//
//  ViewController.swift
//  ARKitTest
//
//  Created by Chris Seonghwan Yoon & Jeremy Ryan on 7/10/17.
//
// Confirmed issues
// - We are not doing a proper job dealing with resumed routes with respect to logging (we always send recorded stuff in the log file, which we don't always have access to)
//
// Unconfirmed issues issues
// - Maybe intercept session was interrupted so that we don't mistakenly try to navigate saved route before relocalization
//
// Major features to implement
//
// Potential enhancements
//  - Add a tip to the help file regarding holding phone against your chest (see Per Rosqvist's suggestion)
//  - Warn user via an alert if they have an iPhone 5S or 6
//  - Possibly create a warning if the phone doesn't appear to be in the correct orientation
//  - revisit turn warning feature.  It doesn't seem to actually help all that much at the moment.

// Path alignment
// TODO: implement local suppression so we don't get to many alignment points in one place.
// TODO: implement something to keep the points moving in the proper direction (avoid reversing the route on mistake)
// TODO: automatically add the first keypoint of the route (probably this would also involve an alignment at that point as well)
// TODO: recency of path alignment

import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO
import AVFoundation
import AudioToolbox
import MediaPlayer
import VectorMath
import Firebase
import FirebaseDatabase
import SRCountdownTimer
import VideoToolbox

/// A custom enumeration type that describes the exact state of the app.  The state is not exhaustive (e.g., there are Boolean flags that also track app state).
enum AppState {
    /// This is the screen the comes up immediately after the splash screen
    case mainScreen(announceArrival: Bool)
    /// User is recording the route
    case recordingRoute
    /// User can either navigate back or pause
    case readyToNavigateOrPause(allowPause: Bool)
    /// User is navigating along a route
    case navigatingRoute
    /// User is rating the route
    case ratingRoute(announceArrival: Bool)
    /// The app is starting up
    case initializing
    /// The user has requested a pause, but has not yet put the phone in the save location
    case startingPauseProcedure
    /// The user has hit the volume button.  The app now enters a waiting period for the tracking to stabilize
    case pauseWaitingPeriod
    /// user is attempting to complete the pausing procedure
    case completingPauseProcedure
    /// user has successfully paused the ARSession
    case pauseProcedureCompleted
    /// user has hit the resume button and is waiting for the volume to hit
    case startingResumeProcedure(route: SavedRoute, worldMap: ARWorldMap?, navigateStartToEnd: Bool)
    /// the AR session has entered the relocalizing state, which means that we can now realign the session
    case readyForFinalResumeAlignment
    /// the user is attempting to name the route they're in the process of saving
    case startingNameSavedRouteProcedure(worldMap: ARWorldMap?)
    
    /// user has initiated landmark realignment countdown
    case resumeWaitingPeriod
    
    /// The timer has expired and visual alignment is computing
    case visualAlignmentWaitingPeriod
    
    /// rawValue is useful for serializing state values, which we are currently using for our logging feature
    var rawValue: String {
        switch self {
        case .mainScreen(let announceArrival):
            return "mainScreen(announceArrival=\(announceArrival))"
        case .recordingRoute:
            return "recordingRoute"
        case .readyToNavigateOrPause:
            return "readyToNavigateOrPause"
        case .navigatingRoute:
            return "navigatingRoute"
        case .ratingRoute(let announceArrival):
            return "ratingRoute(announceArrival=\(announceArrival))"
        case .initializing:
            return "initializing"
        case .startingPauseProcedure:
            return "startingPauseProcedure"
        case .pauseWaitingPeriod:
            return "pauseWaitingPeriod"
        case .completingPauseProcedure:
            return "completingPauseProcedure"
        case .pauseProcedureCompleted:
            return "pauseProcedureCompleted"
            
        case .resumeWaitingPeriod:
            return "resumeWaitingPeriod"
        case .visualAlignmentWaitingPeriod:
            return "visualAlignmentWaitingPeriod"
        case .startingResumeProcedure(_, _, let navigateStartToEnd):
            return "startingResumeProcedure(route=notloggedhere, map=notlogged, navigateStartToEnd=\(navigateStartToEnd))"
        case .readyForFinalResumeAlignment:
            return "readyForFinalResumeAlignment"
        case .startingNameSavedRouteProcedure:
            return "startingNameSavedRouteProcedure"
        }
    }
    
    var isTryingToAlign: Bool {
        if case .readyForFinalResumeAlignment = self {
            return true
        }
        if case .resumeWaitingPeriod = self {
            return true
        }
        if case .visualAlignmentWaitingPeriod = self {
            return true
        }
        return false
    }
}

/// The view controller that handles the main Clew window.  This view controller is always active and handles the various views that are used for different app functionalities.
class ViewController: UIViewController, ARSCNViewDelegate, SRCountdownTimerDelegate, AVSpeechSynthesizerDelegate, ARSessionDelegate {
    
    // MARK: - Refactoring UI definition
    
    // MARK: Properties and subview declarations
    
    /// How long to wait (in seconds) between the alignment request and grabbing the transform
    static var alignmentWaitingPeriod = 5
    
    /// maximum number of times to try to visually align
    static let maxVisualAlignmentRetryCount = 25
    
    var visualTransforms: [simd_float4x4] = []
    
    var backupTransform: simd_float4x4?

    
    /// Used for synchrony when saving in background threads.
    let routeSaveGroup = DispatchGroup()
    
    /// The state of the ARKit tracking session as last communicated to us through the delgate protocol.  This is useful if you want to do something different in the delegate method depending on the previous state
    var trackingSessionState : ARCamera.TrackingState?
    
    var loadedRoute : SavedRoute?
    var loadedRouteStartToEnd : Bool?
    
    var phoneVertical : Bool? = false
    
    /// The state of the app.  This should be constantly referenced and updated as the app transitions
    var state = AppState.initializing {
        didSet {
            logger.logStateTransition(newState: state)
            switch state {
            case .recordingRoute:
                handleStateTransitionToRecordingRoute()
            case .readyToNavigateOrPause:
                handleStateTransitionToReadyToNavigateOrPause(allowPause: recordingSingleUseRoute)
            case .navigatingRoute:
                handleStateTransitionToNavigatingRoute()
            case .ratingRoute(let announceArrival):
                handleStateTransitionToRatingRoute(announceArrival: announceArrival)
            case .mainScreen(let announceArrival):
                handleStateTransitionToMainScreen(announceArrival: announceArrival)
            case .startingPauseProcedure:
                handleStateTransitionToStartingPauseProcedure()

            case .pauseWaitingPeriod:
                handleStateTransitionToPauseWaitingPeriod()
            case .completingPauseProcedure:
                handleStateTransitionToCompletingPauseProcedure()
            case .pauseProcedureCompleted:
                // nothing happens currently
                break
            case .startingResumeProcedure(let route, let worldMap, let navigateStartToEnd):
                handleStateTransitionToStartingResumeProcedure(route: route, worldMap: worldMap, navigateStartToEnd: navigateStartToEnd)
            case .readyForFinalResumeAlignment:
                // nothing happens currently
                break
            case .resumeWaitingPeriod:
                break
            case .visualAlignmentWaitingPeriod:
                break
            case .startingNameSavedRouteProcedure(let worldMap):
                handleStateTransitionToStartingNameSavedRouteProcedure(worldMap: worldMap)
            case .initializing:
                break
            }
        }
    }
    
    func recordRouteLandmarkHelper(timer: Timer?, startTimerFunc: () -> ()) {
        guard let poseRotation = sceneView.session.currentFrame?.camera.transform.rotation() else {
            return
        }
        
        let projectedPhoneZ = poseRotation * simd_float3(0, 0, 1)
        let polar = acos(simd_dot(projectedPhoneZ, simd_normalize(simd_float3(projectedPhoneZ.x, 0, projectedPhoneZ.z))))
        let phoneCurrentlyVertical = polar < 0.4
        let nowVerticalVibration = UIImpactFeedbackGenerator(style: .light)
        let nowNotVerticalVibration = UIImpactFeedbackGenerator(style: .heavy)
        
        guard let unwrappedPhoneVertical = phoneVertical else {
            phoneVertical = phoneCurrentlyVertical
            if !phoneCurrentlyVertical {
                rootContainerView.countdownTimer.isHidden = true
                announce(announcement: "Camera not vertical, hold phone vertically to begin countdown")
                rootContainerView.countdownTimer.start(beginingValue: ViewController.alignmentWaitingPeriod, interval: 1)
                rootContainerView.countdownTimer.pause()
                rootContainerView.countdownTimer.setNeedsDisplay()
                nowNotVerticalVibration.impactOccurred()
            }
            else {
                startTimerFunc()
            }
            return
        }
        
        if !phoneCurrentlyVertical && unwrappedPhoneVertical {
            announce(announcement: "Camera no longer vertical, restarting and stopping countdown")
            rootContainerView.countdownTimer.isHidden = true
            timer?.invalidate()
            rootContainerView.countdownTimer.start(beginingValue: ViewController.alignmentWaitingPeriod, interval: 1)
            rootContainerView.countdownTimer.pause()
            rootContainerView.countdownTimer.setNeedsDisplay()
            nowNotVerticalVibration.impactOccurred()
        }
        
        if phoneCurrentlyVertical && !unwrappedPhoneVertical {
            rootContainerView.countdownTimer.isHidden = false
            announce(announcement: "Camera now vertical, starting countdown")
            rootContainerView.countdownTimer.resume()
            nowVerticalVibration.impactOccurred()
            startTimerFunc()
        }
        phoneVertical = phoneCurrentlyVertical
    }
    
    func session(_ session: ARSession, didUpdate: ARFrame) {
        switch state {
        case .pauseWaitingPeriod:
            recordRouteLandmarkHelper(timer: recordRouteLandmarkTimer, startTimerFunc: startRecordRouteLandmarkTimer)

        case .resumeWaitingPeriod:
            recordRouteLandmarkHelper(timer: resumeRouteTimer, startTimerFunc: startResumeRouteTimer)
        case .navigatingRoute:
                if !keypoints.isEmpty, let alignmentTransform = keypoints[0].alignmentImageTransform, let alignmentImage = keypoints[0].alignmentImage, let alignmentIntrinsics = keypoints[0].alignmentIntrinsics {
                    pausedAnchorPoint = RouteAnchorPoint()
                    pausedAnchorPoint?.transform = alignmentTransform
                    pausedAnchorPoint?.image = alignmentImage
                    pausedAnchorPoint?.intrinsics = alignmentIntrinsics
                }
        default:
            phoneVertical = nil
        }

    }
    


    /// When VoiceOver is not active, we use AVSpeechSynthesizer for speech feedback
    let synth = AVSpeechSynthesizer()
    
    /// The announcement that is currently being read.  If this is nil, that implies nothing is being read
    var currentAnnouncement: String?
    
    /// The announcement that should be read immediately after this one finishes
    var nextAnnouncement: String?
    
    /// Actions to perform after the tracking session is ready
    var continuationAfterSessionIsReady: (()->())?
    
    /// A boolean that tracks whether or not to suppress tracking warnings.  By default we don't suppress, but when the help popover is presented we do.
    var suppressTrackingWarnings = false
    
    // TODO: the number of Booleans is a bit out of control.  We need a better way to manage them.  Some of them may be redundant with each other at this point.
    
    /// This Boolean marks whether or not the pause procedure is being used to create a Anchor Point at the start of a route (true) or if it is being used to pause an already recorded route
    var creatingRouteAnchorPoint: Bool = false
    
    /// This Boolean marks whether or not the user is resuming a route
    var isResumedRoute: Bool = false
    
    /// Set to true when the user is attempting to load a saved route that has a map associated with it. Once relocalization succeeds, this flag should be set back to false
    var attemptingRelocalization: Bool = false
    
    /// this Boolean marks whether the curent route is 'paused' or not from the use of the pause button
    var paused: Bool = false
    
    /// this Boolean marks whether or not the app is recording a multi use route
    var recordingSingleUseRoute: Bool = false
    
    /// this Boolean marks whether or not the app is following a single use route
    var followingSingleUseRoute: Bool = false
    
    ///this Boolean marks whether or not the app is saving a starting anchor point
    var startAnchorPoint: Bool = false
    
    ///this boolean denotes whether or not the app is loading a route from an automatic alignment
    var isAutomaticAlignment: Bool = false
    
    /// This is an audio player that queues up the voice note associated with a particular route Anchor Point. The player is created whenever a saved route is loaded. Loading it before the user clicks the "Play Voice Note" button allows us to call the prepareToPlay function which reduces the latency when the user clicks the "Play Voice Note" button.
    var voiceNoteToPlay: AVAudioPlayer?
    
    var visualAlignmentSuccessSound: AVAudioPlayer?
    
    // MARK: - Speech Synthesizer Delegate
    
    /// Called when an utterance is finished.  We implement this function so that we can keep track of
    /// whether or not an announcement is currently being read to the user.
    ///
    /// - Parameters:
    ///   - synthesizer: the synthesizer that finished the utterance
    ///   - utterance: the utterance itself
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        currentAnnouncement = nil
        if let nextAnnouncement = self.nextAnnouncement {
            self.nextAnnouncement = nil
            announce(announcement: nextAnnouncement)
        }
    }
    
    /// Called when an utterance is canceled.  We implement this function so that we can keep track of
    /// whether or not an announcement is currently being read to the user.
    ///
    /// - Parameters:
    ///   - synthesizer: the synthesizer that finished the utterance
    ///   - utterance: the utterance itself
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didCancel utterance: AVSpeechUtterance) {
        currentAnnouncement = nil
        if let nextAnnouncement = self.nextAnnouncement {
            self.nextAnnouncement = nil
            announce(announcement: nextAnnouncement)
        }
    }
    
    /// Handler for the mainScreen app state
    ///
    /// - Parameter announceArrival: a Boolean that indicates whether the user's arrival should be announced (true means the user has arrived)
    func handleStateTransitionToMainScreen(announceArrival: Bool) {
        // cancel the timer that announces tracking errors
        trackingErrorsAnnouncementTimer?.invalidate()
        // if the ARSession is running, pause it to conserve battery
        sceneView.session.pause()
        // set this to nil to prevent the app from erroneously detecting that we can auto-align to the route
        configuration.initialWorldMap = nil
        showRecordPathButton(announceArrival: announceArrival)
    }
    
    /// Handler for the recordingRoute app state
    func handleStateTransitionToRecordingRoute() {
        // records a new path
        // updates the state Boolean to signifiy that the program is no longer saving the first anchor point
        startAnchorPoint = false
        attemptingRelocalization = false
        
        crumbs = []
        intermediateRouteAnchorPoints = []
        logger.resetPathLog()
        
        showStopRecordingButton()
        droppingCrumbs = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(dropCrumb), userInfo: nil, repeats: true)
        // make sure there are no old values hanging around
        nav.headingOffset = 0.0
        headingRingBuffer.clear()
        locationRingBuffer.clear()
        updateHeadingOffsetTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: (#selector(updateHeadingOffset)), userInfo: nil, repeats: true)
    }
    
    /// Handler for the readyToNavigateOrPause app state
    ///
    /// - Parameter allowPause: a Boolean that determines whether the app should allow the user to pause the route (this is only allowed if it is the initial route recording)
    func handleStateTransitionToReadyToNavigateOrPause(allowPause: Bool) {
        droppingCrumbs?.invalidate()
        updateHeadingOffsetTimer?.invalidate()
        showStartNavigationButton(allowPause: allowPause)
    }
    
    /// Removes all of the follow crumbs that have been built-up in the system
    func clearAllFollowCrumbs() {
        guard let anchors = sceneView.session.currentFrame?.anchors else {
            return
        }
        for anchor in anchors {
            if let name = anchor.name, name == "followCrumb" {
                sceneView.session.remove(anchor: anchor)
            }
        }
    }
    
    /// Handler for the navigatingRoute app state
    func handleStateTransitionToNavigatingRoute() {
        // navigate the recorded path

        // If the route has not yet been saved, we can no longer save this route
        routeName = nil
        beginRouteAnchorPoint = RouteAnchorPoint()
        endRouteAnchorPoint = RouteAnchorPoint()
        clearAllFollowCrumbs()

        logger.resetNavigationLog()

        // generate path from PathFinder class
        // enabled hapticFeedback generates more keypoints
        let path = PathFinder(crumbs: crumbs.reversed(), intermediateRouteAnchorPoints: intermediateRouteAnchorPoints.reversed(), hapticFeedback: hapticFeedback, voiceFeedback: voiceFeedback)
        keypoints = path.keypoints
        print("kp", keypoints!.map({[$0.location.x, $0.location.y, $0.location.z]}))
        checkedOffKeypoints = []
        
        // save keypoints data for debug log
        logger.logKeypoints(keypoints: keypoints)
        
        // render 3D keypoints
        renderKeypoint(keypoints[0].location)
        
        // TODO: gracefully handle error
        prevKeypointPosition = getRealCoordinates(record: true)!.location
        
        feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        waypointFeedbackGenerator = UINotificationFeedbackGenerator()
        showStopNavigationButton()

        // wait a little bit before starting navigation to allow screen to transition and make room for the first direction announcement to be communicated
        
        if UIAccessibility.isVoiceOverRunning {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { timer in
                self.followingCrumbs = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: (#selector(self.followCrumb)), userInfo: nil, repeats: true)
            }
        } else {
            followingCrumbs = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: (#selector(self.followCrumb)), userInfo: nil, repeats: true)
        }
        
        feedbackTimer = Date()
        // make sure there are no old values hanging around
        headingRingBuffer.clear()
        locationRingBuffer.clear()
        hapticTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: (#selector(getHapticFeedback)), userInfo: nil, repeats: true)
        print("turning off auto snap to route")
        //snapToRouteTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: (#selector(snapToRoute)), userInfo: nil, repeats: true)
    }
    
    /// Handler for the route rating app state
    ///
    /// - Parameter announceArrival: a Boolean that is true if we should announce that the user has arrived at the destination and false otherwise
    func handleStateTransitionToRatingRoute(announceArrival: Bool) {
        showRouteRating(announceArrival: announceArrival)
    }
    
    /// Handler for the startingResumeProcedure app state
    ///
    /// - Parameters:
    ///   - route: the route to navigate
    ///   - worldMap: the world map to use
    ///   - navigateStartToEnd: a Boolean that is true if we want to navigate from the start to the end and false if we want to navigate from the end to the start.
    func handleStateTransitionToStartingResumeProcedure(route: SavedRoute, worldMap: ARWorldMap?, navigateStartToEnd: Bool) {
        // load the world map and restart the session so that things have a chance to quiet down before putting it up to the wall
        loadedRoute = route
        loadedRouteStartToEnd = navigateStartToEnd
        var isTrackingPerformanceNormal = false
        if case .normal? = sceneView.session.currentFrame?.camera.trackingState {
            isTrackingPerformanceNormal = true
        }
        var isRelocalizing = false
        if case .limited(reason: .relocalizing)? = sceneView.session.currentFrame?.camera.trackingState {
            isRelocalizing = true
        }
        let isSameMap = configuration.initialWorldMap != nil && configuration.initialWorldMap == worldMap
        print("disabling world map")
        configuration.initialWorldMap = nil //worldMap
    
        attemptingRelocalization =  isSameMap && !isTrackingPerformanceNormal || worldMap != nil && !isSameMap

        if navigateStartToEnd {
            crumbs = route.crumbs.reversed()
            intermediateRouteAnchorPoints = route.intermediateRouteAnchorPoints.reversed()
            pausedAnchorPoint = route.beginRouteAnchorPoint
        } else {
            crumbs = route.crumbs
            pausedAnchorPoint = route.endRouteAnchorPoint
            intermediateRouteAnchorPoints = route.intermediateRouteAnchorPoints
        }
        print("Intermediate route anchors", intermediateRouteAnchorPoints.count)
        // don't reset tracking, but do clear anchors and switch to the new map
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])

        if isTrackingPerformanceNormal, isSameMap {
            // we can skip the whole process of relocalization since we are already using the correct map and tracking is normal.  It helps to strip out old anchors to reduce jitter though
            ///PATHPOINT load route from automatic alignment -> start navigation
            
            isResumedRoute = true
            isAutomaticAlignment = true
            state = .readyToNavigateOrPause(allowPause: false)
        } else if isRelocalizing && isSameMap || isTrackingPerformanceNormal && worldMap == nil  {
            // we don't have to wait for the session to start up.  It will be created automatically.
            self.state = .readyForFinalResumeAlignment
            self.showResumeTrackingConfirmButton(route: route, navigateStartToEnd: navigateStartToEnd)
        } else {
            // this makes sure that the user doesn't resume the session until the session is initialized
            continuationAfterSessionIsReady = {
                self.state = .readyForFinalResumeAlignment
                self.showResumeTrackingConfirmButton(route: route, navigateStartToEnd: navigateStartToEnd)
            }
        }
    }
    
    /// Handler for the startingNameSavedRouteProcedure app state
    func handleStateTransitionToStartingNameSavedRouteProcedure(worldMap: ARWorldMap?){
        hideAllViewsHelper()
        nameSavedRouteController.worldMap = worldMap
        add(nameSavedRouteController)
    }
    
    /// Handler for the startingPauseProcedure app state
    func handleStateTransitionToStartingPauseProcedure() {
        // clear out these variables in case they had already been created
        if creatingRouteAnchorPoint {
            beginRouteAnchorPoint = RouteAnchorPoint()
        } else {
            endRouteAnchorPoint = RouteAnchorPoint()
        }
        try! showPauseTrackingButton()
    }
    weak var recordRouteLandmarkTimer: Timer?
    
    /// Handler for beginning alignment computations after the alignment period
    @objc
    func playAlignmentConfirmation(_ timer: Timer) {
        self.rootContainerView.countdownTimer.isHidden = true
        self.pauseTracking()
    }
    
    /// Start the route landmark recording timer
    func startRecordRouteLandmarkTimer() {
        recordRouteLandmarkTimer = Timer.scheduledTimer(
            timeInterval: Double(ViewController.alignmentWaitingPeriod),
            target: self,
            selector: #selector(playAlignmentConfirmation(_:)),
            userInfo: nil,
            repeats: false)
    }
    
    /// Handler for the pauseWaitingPeriod app state
    func handleStateTransitionToPauseWaitingPeriod() {
        hideAllViewsHelper()
        ///sets the length of the timer to be equal to what the person has in their settings
        ViewController.alignmentWaitingPeriod = timerLength
        rootContainerView.countdownTimer.isHidden = false
        rootContainerView.countdownTimer.start(beginingValue: ViewController.alignmentWaitingPeriod, interval: 1)

        delayTransition()
    }
    
    /// Handler for the completingPauseProcedure app state
    func handleStateTransitionToCompletingPauseProcedure() {
        // TODO: we should not be able to create a route Anchor Point if we are in the relocalizing state... (might want to handle this when the user stops navigation on a route they loaded.... This would obviate the need to handle this in the recordPath code as well
        print("completing pause procedure")
        if creatingRouteAnchorPoint {
            guard let currentTransform = sceneView.session.currentFrame?.camera.transform else {
                print("could not properly save landmark: TODO communicate this to the user somehow")
                return
            }
            beginRouteAnchorPoint.transform = currentTransform
            print("setting transform", beginRouteAnchorPoint.transform)

            if let currentFrame = sceneView.session.currentFrame {

                let beginRouteAnchorPointImageIdentifier = UUID()
                beginRouteAnchorPoint.imageFileName = "\(beginRouteAnchorPointImageIdentifier).jpg" as NSString
                
                guard let beginRouteAnchorPointImage = pixelBufferToUIImage(pixelBuffer: currentFrame.capturedImage) else {
                    return
                }
                
                let beginRouteAnchorPointJpeg = beginRouteAnchorPointImage.jpegData(compressionQuality: 1)
                try! beginRouteAnchorPointJpeg?.write(to: beginRouteAnchorPoint.imageFileName!.documentURL, options: .atomic)
                beginRouteAnchorPoint.loadImage()
                
                let intrinsics = currentFrame.camera.intrinsics
                beginRouteAnchorPoint.intrinsics = simd_float4(intrinsics[0, 0], intrinsics[1, 1], intrinsics[2, 0], intrinsics[2, 1])
            }
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(playSound)), userInfo: nil, repeats: false)

            pauseTrackingController.remove()
            
            ///PATHPOINT begining anchor point alignment timer -> record route
            ///announce to the user that they have sucessfully saved an anchor point.
            delayTransition(announcement: NSLocalizedString("multipleUseRouteAnchorPointToRecordingRouteAnnouncement", comment: "This is the announcement which is spoken after the first anchor point of a multiple use route is saved. this signifies the completeion of the saving an anchor point procedure and the start of recording a route to be saved."), initialFocus: nil)
            ///sends the user to a route recording of the program is creating a beginning route Anchor Point
            state = .recordingRoute
            return
        } else if let currentFrame = sceneView.session.currentFrame {
            let endRouteAnchorPointImageIdentifier = UUID()
            endRouteAnchorPoint.imageFileName = "\(endRouteAnchorPointImageIdentifier).jpg" as NSString
            
            guard let endRouteAnchorPointImage = pixelBufferToUIImage(pixelBuffer: currentFrame.capturedImage) else {
                return
            }
            
            let endRouteAnchorPointJpeg = endRouteAnchorPointImage.jpegData(compressionQuality: 1)
            try! endRouteAnchorPointJpeg?.write(to: endRouteAnchorPoint.imageFileName!.documentURL, options: .atomic)
            endRouteAnchorPoint.loadImage()
            
            endRouteAnchorPoint.transform = currentFrame.camera.transform

            let intrinsics = currentFrame.camera.intrinsics
            endRouteAnchorPoint.intrinsics = simd_float4(intrinsics[0, 0], intrinsics[1, 1], intrinsics[2, 0], intrinsics[2, 1])

            sceneView.session.getCurrentWorldMap { worldMap, error in
                //check whether or not the path was called from the pause menu or not
                if self.paused {
                    ///PATHPOINT pause recording anchor point alignment timer -> resume tracking
                    //proceed as normal with the pause structure (single use route)
                    self.justTraveledRoute = SavedRoute(id: "single use", name: "single use", crumbs: self.crumbs, dateCreated: Date() as NSDate, beginRouteAnchorPoint: self.beginRouteAnchorPoint, endRouteAnchorPoint: self.endRouteAnchorPoint, intermediateRouteAnchorPoints: self.intermediateRouteAnchorPoints)
                    self.justUsedMap = worldMap
                    self.showResumeTrackingButton()
                    self.state = .pauseProcedureCompleted
                } else {
                    ///PATHPOINT end anchor point alignment timer -> Save Route View
                    self.delayTransition(announcement: NSLocalizedString("multipleUseRouteAnchorPointToSaveARouteAnnouncement", comment: "This is an announcement which is spoken when the user saves the end anchor point for a multiple use route. This signifies the transition from saving an anchor point to the screen where the user can name and save their route"), initialFocus: nil)
                    ///sends the user to the play/pause screen
                    self.state = .startingNameSavedRouteProcedure(worldMap: worldMap)
                }
            }
        }
    }
    
    /// Prompt the user for the name of a route and persist the route data if the user supplies one.  If the user cancels, no action is taken.
    ///
    /// - Parameter mapAsAny: the world map (the `Any?` type is used since it is optional and we want to maintain backward compatibility with iOS 11.3
    func getRouteNameAndSaveRouteHelper(mapAsAny: Any?) {
        if routeName == nil {
            // get a route name
            showRouteNamingDialog(mapAsAny: mapAsAny)
        } else {
            routeSaveGroup.enter()
            DispatchQueue.global(qos: .background).async {
                do {
                    // TODO: factor this out since it shows up in a few places
                    let id = String(Int64(NSDate().timeIntervalSince1970 * 1000)) as NSString
                    try self.archive(routeId: id, beginRouteAnchorPoint: self.beginRouteAnchorPoint, endRouteAnchorPoint: self.endRouteAnchorPoint, worldMap: mapAsAny as! ARWorldMap?)
                    self.routeSaveGroup.leave()
                } catch {
                    fatalError("Can't archive route: \(error.localizedDescription)")
                }
                
                DispatchQueue.main.async {
                    self.announce(announcement: "End landmark saved")
                }
            }
        }
    }
    
    /// Called when the user presses the routes button.  The function will display the `Routes` view, which is managed by `RoutesViewController`.
    @objc func routesButtonPressed() {
        ///update state boolians
        paused = false
        isAutomaticAlignment = false
        recordingSingleUseRoute = false
        followingSingleUseRoute = false
        stopNavigationController.followingSingleUseRoute = followingSingleUseRoute
        
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "SettingsAndHelp", bundle: nil)
        let popoverContent = storyBoard.instantiateViewController(withIdentifier: "Routes") as! RoutesViewController
        popoverContent.preferredContentSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        popoverContent.rootViewController = self
        popoverContent.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: popoverContent, action: #selector(popoverContent.doneWithRoutes))
        popoverContent.updateRoutes(routes: dataPersistence.routes)
        let nav = UINavigationController(rootViewController: popoverContent)
        nav.modalPresentationStyle = .popover
        let popover = nav.popoverPresentationController
        popover?.delegate = self
        popover?.sourceView = self.view
        popover?.sourceRect = CGRect(x: 0,
                                     y: UIConstants.settingsAndHelpFrameHeight/2,
                                     width: 0,height: 0)
        
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc func saveRouteButtonPressed() {
        let id = String(Int64(NSDate().timeIntervalSince1970 * 1000)) as NSString
        // Get the input values from user, if it's nil then use timestamp
        self.routeName = nameSavedRouteController.textField.text as NSString? ?? id
        try! self.archive(routeId: id, beginRouteAnchorPoint: self.beginRouteAnchorPoint, endRouteAnchorPoint: self.endRouteAnchorPoint, worldMap: nameSavedRouteController.worldMap)
        hideAllViewsHelper()
        /// PATHPOINT Save Route View -> play/pause
        ///Announce to the user that they have finished the alignment process and are now at the play pause screen
        self.delayTransition(announcement: NSLocalizedString("saveRouteToPlayPauseAnnouncement", comment: "This is an announcement which is spoken when the user finishes saving their route. This announcement signifies the transition from the view where the user can name or save their route to the screen where the user can either pause the AR session tracking or they can perform return navigation."), initialFocus: nil)
        ///Clearing the save route text field
        nameSavedRouteController.textField.text = ""
        ///perform the state transition
        self.state = .readyToNavigateOrPause(allowPause: true)
    }
    
    /// Hide all the subviews.  TODO: This should probably eventually refactored so it happens more automatically.
    func hideAllViewsHelper() {
        recordPathController.remove()
        routeRatingController.remove()
        stopRecordingController.remove()
        startNavigationController.remove()
        stopNavigationController.remove()
        pauseTrackingController.remove()
        resumeTrackingConfirmController.remove()
        resumeTrackingController.remove()
        nameSavedRouteController.remove()
        rootContainerView.countdownTimer.isHidden = true
    }
    
    /// This handles when a route cell is clicked (triggering the route to be loaded).
    ///
    /// - Parameters:
    ///   - route: the route that was clicked
    ///   - navigateStartToEnd: a Boolean indicating the navigation direction (true is start to end)
    func onRouteTableViewCellClicked(route: SavedRoute, navigateStartToEnd: Bool) {
        let worldMap = dataPersistence.unarchiveMap(id: route.id as String)
        hideAllViewsHelper()
        state = .startingResumeProcedure(route: route, worldMap: worldMap, navigateStartToEnd: navigateStartToEnd)
    }
    
    /// Saves the specified route.  The bulk of the work is done by the `DataPersistence` class, but this is a convenient wrapper.
    ///
    /// - Parameters:
    ///   - routeId: the ID of the route
    ///   - beginRouteAnchorPoint: the route Anchor Point for the beginning (if there is no route Anchor Point at the beginning, the elements of this struct can be nil)
    ///   - endRouteAnchorPoint: the route Anchor Point for the end (if there is no route Anchor Point at the end, the elements of this struct can be nil)
    ///   - worldMap: the world map
    /// - Throws: an error if something goes wrong
    func archive(routeId: NSString, beginRouteAnchorPoint: RouteAnchorPoint, endRouteAnchorPoint: RouteAnchorPoint, worldMap: ARWorldMap?) throws {
        let savedRoute = SavedRoute(id: routeId, name: routeName!, crumbs: crumbs, dateCreated: Date() as NSDate, beginRouteAnchorPoint: beginRouteAnchorPoint, endRouteAnchorPoint: endRouteAnchorPoint, intermediateRouteAnchorPoints: intermediateRouteAnchorPoints)
        try dataPersistence.archive(route: savedRoute, worldMap: worldMap)
        justTraveledRoute = savedRoute
    }

    /// A threshold to determine when a segment is long enough to use for soft alignment
    var softAlignmentSegmentLengthThreshold = 1.0

    /// Timer to periodically announce tracking errors
    var trackingErrorsAnnouncementTimer: Timer?
    
    /// While recording, every 0.01s, check to see if we should reset the heading offset
    var angleOffsetTimer: Timer?
    
    /// A threshold to determine when the phone rotated too much to update the angle offset
    let angleDeviationThreshold : Float = 0.2
    /// The minimum distance traveled in the floor plane in order to update the angle offset
    let requiredDistance : Float = 0.3
    /// A threshold to determine when a path is too curvy to update the angle offset
    let linearDeviationThreshold: Float = 0.05
    
    /// a ring buffer used to keep the last 50 positions of the phone
    var locationRingBuffer = RingBuffer<Vector3>(capacity: 50)
    /// a ring buffer used to keep the last 100 headings of the phone
    var headingRingBuffer = RingBuffer<Float>(capacity: 50)

    /// The conection to the Firebase real-time database
    var databaseHandle = Database.database()
    
    /// Keypoint object
    var keypointObject : MDLObject!
    
    /// Arrow object
    var arrowObject : MDLObject!
    
    /// Route persistence
    var dataPersistence = DataPersistence()
    
    // MARK: - Parameters that can be controlled remotely via Firebase
    
    /// True if the offset between direction of travel and phone should be updated over time
    var adjustOffset = false
    
    /// True if we should use a cone of pi/12 and false if we should use a cone of pi/6 when deciding whether to issue haptic feedback
    var strictHaptic = true
    
    /// This is embeds an AR scene.  The ARSession is a part of the scene view, which allows us to capture where the phone is in space and the state of the world tracking.  The scene also allows us to insert virtual objects
    var sceneView = ARSCNView()
    
    /// Hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }

    /// audio players for playing system sounds through an `AVAudioSession` (this allows them to be audible even when the rocker switch is muted.
    var audioPlayers: [Int: AVAudioPlayer] = [:]
    
    /// Callback function for when `countdownTimer` updates.  This allows us to announce the new value via voice
    ///
    /// - Parameter newValue: the new value (in seconds) displayed on the countdown timer
    @objc func timerDidUpdateCounterValue(newValue: Int) {
        if UIAccessibility.isVoiceOverRunning {
            if currentAnnouncement == nil {
                UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String(newValue))
            }
//            announce(announcement: String(newValue))
        }
    }
    
    /// Hook in the view class as a view, so that we can access its variables easily
    var rootContainerView: RootContainerView {
        return view as! RootContainerView
    }
    
    /// child view controllers for various app states
    
    /// route rating VC
    var routeRatingController: RouteRatingController!
    
    /// route navigation pausing VC
    var pauseTrackingController: PauseTrackingController!
    
    /// route navigation resuming VC
    var resumeTrackingController: ResumeTrackingController!
    
    /// route navigation resuming alignment and confirmation VC
    var resumeTrackingConfirmController: ResumeTrackingConfirmController!
    
    /// route recording dismissal VC
    var stopRecordingController: StopRecordingController!
    
    /// route recording VC (called on app start)
    var recordPathController: RecordPathController!
    
    /// saving route name VC
    var nameSavedRouteController: NameSavedRouteController!
    
    /// start route navigation VC
    var startNavigationController: StartNavigationController!
    
    /// stop route navigation VC
    var stopNavigationController: StopNavigationController!

    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.session.delegate = self

        sceneView.accessibilityIgnoresInvertColors = true
        
        // set the main view as active
        view = RootContainerView(frame: UIScreen.main.bounds)
        
        // initialize child view controllers
        routeRatingController = RouteRatingController()
        pauseTrackingController = PauseTrackingController()
        resumeTrackingController = ResumeTrackingController()
        resumeTrackingConfirmController = ResumeTrackingConfirmController()
        stopRecordingController = StopRecordingController()
        recordPathController = RecordPathController()
        startNavigationController = StartNavigationController()
        stopNavigationController = StopNavigationController()
        nameSavedRouteController = NameSavedRouteController()
        
        // Add the scene to the view, which is a RootContainerView
        sceneView.frame = view.frame
        view.addSubview(sceneView)

        setupAudioPlayers()
        loadAssets()
        createSettingsBundle()
        createARSessionConfiguration()
        
        // TODO: we might want to make this wait on the AR session starting up, but since it happens pretty fast it's likely not a big deal
        state = .mainScreen(announceArrival: false)
        view.sendSubviewToBack(sceneView)
        
        // targets for global buttons
        ///// TRACK
        rootContainerView.burgerMenuButton.addTarget(self, action: #selector(burgerMenuButtonPressed), for: .touchUpInside)
        
        rootContainerView.homeButton.addTarget(self, action: #selector(homeButtonPressed), for: .touchUpInside)

        rootContainerView.getDirectionButton.addTarget(self, action: #selector(announceDirectionHelpPressed), for: .touchUpInside)

        // make sure this happens after the view is created!
        rootContainerView.countdownTimer.delegate = self
        ///sets the length of the timer to be equal to what the person has in their settings
        ViewController.alignmentWaitingPeriod = timerLength
        
        addGestures()
        setupFirebaseObservers()
        
        // create listeners to ensure that the isReadingAnnouncement flag is reset properly
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { (notification) -> Void in
            self.currentAnnouncement = nil
        }
        
        NotificationCenter.default.addObserver(forName: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil, queue: nil) { (notification) -> Void in
            self.currentAnnouncement = nil
        }
        
        // we use a custom notification to communicate from the help controller to the main view controller that a popover that should suppress tracking warnings was dimissed
        NotificationCenter.default.addObserver(forName: Notification.Name("ClewPopoverDismissed"), object: nil, queue: nil) { (notification) -> Void in
            self.suppressTrackingWarnings = false
        }
        // we use a custom notification to communicate from the help controller to the main view controller that a popover that should suppress tracking warnings was displayed
        NotificationCenter.default.addObserver(forName: Notification.Name("ClewPopoverDisplayed"), object: nil, queue: nil) { (notification) -> Void in
            self.suppressTrackingWarnings = true
        }
    }
    
    /// Create the audio player objects for the various app sounds.  Creating them ahead of time helps reduce latency when playing them later.
    func setupAudioPlayers() {
        do {
            audioPlayers[1103] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/Tink.caf"))
            audioPlayers[1016] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/tweet_sent.caf"))
            audioPlayers[1050] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/ussd.caf"))
            audioPlayers[1025] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/New/Fanfare.caf"))
            visualAlignmentSuccessSound = try AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "ClewSuccessSound", withExtension: "wav")!)
            visualAlignmentSuccessSound?.prepareToPlay()

            for p in audioPlayers.values {
                p.prepareToPlay()
            }
        } catch let error {
            print("count not setup audio players", error)
        }
    }
    
    /// Load the crumb 3D model
    func loadAssets() {
        let url = NSURL(fileURLWithPath: Bundle.main.path(forResource: "Crumb", ofType: "obj")!)
        let asset = MDLAsset(url: url as URL)
        keypointObject = asset.object(at: 0)
        
        let arrowUrl = NSURL(fileURLWithPath: Bundle.main.path(forResource: "arrow", ofType: "obj")!)
        let arrowAsset = MDLAsset(url: arrowUrl as URL)
        arrowObject = arrowAsset.object(at: 0)
    }
    
    /// Observe the relevant Firebase paths to handle any dynamic reconfiguration requests (this is currently not used in the app store version of Clew)
    func setupFirebaseObservers() {
        let responsePathRef = databaseHandle.reference(withPath: "config/" + UIDevice.current.identifierForVendor!.uuidString)
        responsePathRef.observe(.childChanged) { (snapshot) -> Void in
            self.handleNewConfig(snapshot: snapshot)
        }
        responsePathRef.observe(.childAdded) { (snapshot) -> Void in
            self.handleNewConfig(snapshot: snapshot)
        }
    }
    
    /// Respond to any dynamic reconfiguration requests (this is currently not used in the app store version of Clew).
    ///
    /// - Parameter snapshot: the new configuration data
    func handleNewConfig(snapshot: DataSnapshot) {
        if snapshot.key == "adjust_offset", let newValue = snapshot.value as? Bool {
            adjustOffset = newValue
            if !adjustOffset {
                // clear the offset in case one was set from before
                nav.headingOffset = 0.0
            }
            print("set new adjust offset value", newValue)
        } else if snapshot.key == "strict_haptic", let newValue = snapshot.value as? Bool {
            strictHaptic = newValue
            print("set new strict haptic value", newValue)
        }
    }
    
    /// Called when the view appears on screen.
    ///
    /// - Parameter animated: True if the appearance is animated
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let userDefaults: UserDefaults = UserDefaults.standard
        let firstTimeLoggingIn: Bool? = userDefaults.object(forKey: "firstTimeLogin") as? Bool
        let showedSignificantChangesAlert: Bool? = userDefaults.object(forKey: "showedSignificantChangesAlertv1_3") as? Bool
        
        if firstTimeLoggingIn == nil {
            userDefaults.set(true, forKey: "firstTimeLogin")
            // make sure not to show the significant changes alert in the future
            userDefaults.set(true, forKey: "showedSignificantChangesAlertv1_3")
            showLogAlert()
        } else if showedSignificantChangesAlert == nil {
            // we only show the significant changes alert if this is an old installation
            userDefaults.set(true, forKey: "showedSignificantChangesAlertv1_3")
            showSignificantChangesAlert()
        }
        
        synth.delegate = self
        NotificationCenter.default.addObserver(forName: UIAccessibility.announcementDidFinishNotification, object: nil, queue: nil) { (notification) -> Void in
            self.currentAnnouncement = nil
            if let nextAnnouncement = self.nextAnnouncement {
                self.nextAnnouncement = nil
                self.announce(announcement: nextAnnouncement)
            }
        }
    }
    
    /// func that prepares the state transition to home by clearing active processes and data
    func clearState() {
        // TODO: check for code reuse
        // Clearing All State Processes and Data
        rootContainerView.homeButton.isHidden = true
        recordPathController.isAccessibilityElement = false
        if case .navigatingRoute = self.state {
            keypointNode.removeFromParentNode()
        }
        followingCrumbs?.invalidate()
        routeName = nil
        beginRouteAnchorPoint = RouteAnchorPoint()
        endRouteAnchorPoint = RouteAnchorPoint()
        recordRouteLandmarkTimer?.invalidate()
        rootContainerView.announcementText.isHidden = true
        nav.headingOffset = 0.0
        headingRingBuffer.clear()
        locationRingBuffer.clear()
        logger.resetNavigationLog()
        logger.resetPathLog()
        hapticTimer?.invalidate()
        snapToRouteTimer?.invalidate()
        logger.resetStateSequenceLog()
    }
    
    /// This finishes the process of pressing the home button (after user has given confirmation)
    @objc func goHome() {
        // proceed to home page
        self.clearState()
        self.hideAllViewsHelper()
        if case .startingNameSavedRouteProcedure = self.state {
            self.nameSavedRouteController.textField.text = ""
        }
        self.state = .mainScreen(announceArrival: false)
    }
    
    /// function that creates alerts for the home button
    func homePageNavigationProcesses() {
        // Create alert to warn users of lost information
        let alert = UIAlertController(title: NSLocalizedString("homeAlertTitle", comment: "This is the title of an alert which shows up when the user tries to go home from inside an active process."),
                                      message: NSLocalizedString("homeAlertContent", comment: "this is the content of an alert which tells the user that if they continue with going to the home page the current process will be stopped."),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("homeAlertConfirmNavigationButton", comment: "This text appears on a button in an alert notifying the user that if they navigate to the home page they will stop their curent process. This text appears on the button which signifies that the user wants to continue to the home screen"), style: .default, handler: { action -> Void in
            // proceed to home page
            self.goHome()
        }
        ))
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancelPop-UpButtonLabel", comment: "A button which closes the current pop up"), style: .default, handler: { action -> Void in
            // nothing to do, just stay on the page
        }
        ))
        self.present(alert, animated: true, completion: nil)
    }

    
    /// Display a warning that tells the user they must create a landmark to be able to use this route again in the forward direction
    /// Display the dialog that prompts the user to enter a route name.  If the user enters a route name, the route along with the optional world map will be persisted.
    ///
    /// - Parameter mapAsAny: the world map to save (the `Any?` type is used to indicate that the map is optional and to preserve backwards compatibility with iOS 11.3)
    @objc func showRouteNamingDialog(mapAsAny: Any?) {
        // Set title and message for the alert dialog
        if #available(iOS 12.0, *) {
            justUsedMap = mapAsAny as! ARWorldMap?
        }
        let alertController = UIAlertController(title: NSLocalizedString("Save route", comment: "The title of a popup window where user enters a name for the route they want to save."), message: NSLocalizedString("Enter the name of the route", comment: "Ask user to provide a descriptive name for the route they want to save."), preferredStyle: .alert)
        // The confirm action taking the inputs
        let saveAction = UIAlertAction(title: NSLocalizedString("Save", comment: "An option for the user to select"), style: .default) { (_) in
            let id = String(Int64(NSDate().timeIntervalSince1970 * 1000)) as NSString
            self.routeName = alertController.textFields?[0].text as NSString? ?? id
            // Get the input values from user, if it's nil then use timestamp
            
            self.routeSaveGroup.enter()
            DispatchQueue.global(qos: .background).async {
                try! self.archive(routeId: id, beginRouteAnchorPoint: self.beginRouteAnchorPoint, endRouteAnchorPoint: self.endRouteAnchorPoint, worldMap: self.justUsedMap)
                self.routeSaveGroup.leave()
                DispatchQueue.main.async {
                    self.announce(announcement: "Route saved")
                }
            }
        }
        
        // The cancel action saves the just traversed route so you can navigate back along it later
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "An option for the user to select"), style: .cancel) { (_) in
            self.justTraveledRoute = SavedRoute(id: "dummyid", name: "Last route", crumbs: self.crumbs, dateCreated: Date() as NSDate, beginRouteAnchorPoint: self.beginRouteAnchorPoint, endRouteAnchorPoint: self.endRouteAnchorPoint, intermediateRouteAnchorPoints: self.intermediateRouteAnchorPoints)
        }
        
        // Add textfield to our dialog box
        alertController.addTextField { (textField) in
            textField.becomeFirstResponder()
            textField.placeholder = NSLocalizedString("Enter route title", comment: "A placeholder before user enters text in textbox")
        }
            
        // Add the action to dialogbox
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
            
        // Finally, present the dialog box
        present(alertController, animated: true, completion: nil)
    }

    /// Show the dialog that allows the user to enter textual information to help them remember a Anchor Point.
    @objc func showAnchorPointInformationDialog() {
        rootContainerView.homeButton.isHidden = false
//        backButton.isHidden = true
        // Set title and message for the alert dialog
        let alertController = UIAlertController(title: NSLocalizedString("anchorPointTextHeading", comment: "The header of a pop-up menu which prompts the user to write descriptive text about their route anchor point"), message: NSLocalizedString("anchorPointTextPrompt", comment: "Prompts user to enter descriptive text about their anchor point"), preferredStyle: .alert)
        // The confirm action taking the inputs
        let saveAction = UIAlertAction(title: NSLocalizedString("anchorPointTextPop-UpConfirmation", comment: "A button for user to click to confirm the text note they added to their anchor point and close a pop-up"), style: .default) { (_) in
            if self.creatingRouteAnchorPoint {
                self.beginRouteAnchorPoint.information = alertController.textFields?[0].text as NSString?
            } else {
                self.endRouteAnchorPoint.information = alertController.textFields?[0].text as NSString?
            }
        }
        
        // The cancel action saves the just traversed route so you can navigate back along it later
        let cancelAction = UIAlertAction(title: NSLocalizedString("anchorPointPop-UpCancel", comment: "A button for user to click which will close the pop up without saving any information the user put in"), style: .cancel) { (_) in
        }
        
        // Add textfield to our dialog box
        alertController.addTextField { (textField) in
            textField.becomeFirstResponder()
            textField.placeholder = NSLocalizedString("anchorPointTextPlaceholder", comment: "A placeholder that appears in text box which the user uses to enter a text label for an anchor point.")
        }
        
        // Add the action to dialogbox
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        // Finally, present the dialog box
        present(alertController, animated: true, completion: nil)
    }
    
    /// Plays back the loaded voice note.  This method assumes that the `voiceNoteToPlay` attribute has already been loaded with an appropriate audio player.
    @objc func readVoiceNote() {
        if let voiceNoteToPlay = self.voiceNoteToPlay {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                try AVAudioSession.sharedInstance().setActive(true)
                voiceNoteToPlay.volume = 1.0
                voiceNoteToPlay.play()
            } catch let error {
                print("Couldn't play back the voice note", error.localizedDescription)
            }
        }
    }
    
    /// Record a voice note by displaying the RecorderView
    @objc func recordVoiceNote() {
        let popoverContent = RecorderViewController()
        //says that the recorder should dismiss tiself when it is done
        popoverContent.shouldAutoDismiss = true
        popoverContent.delegate = self
        popoverContent.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: popoverContent, action: #selector(popoverContent.doneWithRecording))
        let nav = UINavigationController(rootViewController: popoverContent)
        nav.modalPresentationStyle = .popover
        let popover = nav.popoverPresentationController
        popover?.delegate = self
        popover?.sourceView = self.view
        popover?.sourceRect = CGRect(x: 0, y: UIConstants.settingsAndHelpFrameHeight/2, width: 0,height: 0)
        suppressTrackingWarnings = true
        self.present(nav, animated: true, completion: nil)
    }
    
    /// Show logging disclaimer when user opens app for the first time.
    func showLogAlert() {
        let logAlertVC = UIAlertController(title: NSLocalizedString("sharingYourExperiencePop-UpHeading", comment: "The heading of a pop-up telling the user that their data is being saved with error logs"),
                                           message: NSLocalizedString("sharingYourExperiencePop-UpContent", comment: "Disclaimer shown to the user when they open the app for the first time"),
                                           preferredStyle: .alert)
        logAlertVC.addAction(UIAlertAction(title: NSLocalizedString("anchorPointTextPop-UpConfirmation", comment: "What the user clicks to acknowledge a message and dismiss pop-up"), style: .default, handler: { action -> Void in
            self.showSafetyAlert()
        }
        ))
        self.present(logAlertVC, animated: true, completion: nil)
    }
    
    /// Show safety disclaimer when user opens app for the first time.
    func showSafetyAlert() {
        let safetyAlertVC = UIAlertController(title: NSLocalizedString("forYourSafetyPop-UpHeading", comment: "The heading of a pop-up telling the user to be aware of their surroundings while using clew"),
                                              message: NSLocalizedString("forYourSafetyPop-UpContent", comment: "Disclaimer shown to the user when they open the app for the first time"),
                                              preferredStyle: .alert)
        safetyAlertVC.addAction(UIAlertAction(title: NSLocalizedString("anchorPointTextPop-UpConfirmation", comment: "What the user clicks to acknowledge a message and dismiss pop-up"), style: .default, handler: nil))
        self.present(safetyAlertVC, animated: true, completion: nil)
    }
    
    /// Show significant changes alert so the user is not surprised by new app features.
    func showSignificantChangesAlert() {
        let changesAlertVC = UIAlertController(title: NSLocalizedString("significantVersionChangesPop-UpHeading", comment: "The heading of a pop-up telling the user that significant changes have been made to this app version"),
                                               message: NSLocalizedString("significantVersionChangesPop-UpContent", comment: "An alert shown to the user to alert them to the fact that significant changes have been made to the app."),
                                               preferredStyle: .alert)
        changesAlertVC.addAction(UIAlertAction(title: NSLocalizedString("significantVersionChanges-Confirmation", comment: "What the user clicks to acknowledge the significant changes message and dismiss pop-up"), style: .default, handler: { action -> Void in
        }
        ))
        self.present(changesAlertVC, animated: true, completion: nil)
    }
    
    /// Configure Settings Bundle
    func createSettingsBundle() {
        registerSettingsBundle()
        updateDisplayFromDefaults()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(defaultsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }
    
    /// Register settings bundle
    func registerSettingsBundle(){
        let appDefaults = ["crumbColor": 0, "hapticFeedback": true, "sendLogs": true, "voiceFeedback": true, "soundFeedback": true, "units": 0, "timerLength":5] as [String : Any]
        UserDefaults.standard.register(defaults: appDefaults)
    }

    /// Respond to update events to the `UserDefaults` object (the settings of the app).
    func updateDisplayFromDefaults(){
        let defaults = UserDefaults.standard
        
        defaultUnit = defaults.integer(forKey: "units")
        defaultColor = defaults.integer(forKey: "crumbColor")
        soundFeedback = defaults.bool(forKey: "soundFeedback")
        voiceFeedback = defaults.bool(forKey: "voiceFeedback")
        hapticFeedback = defaults.bool(forKey: "hapticFeedback")
        sendLogs = defaults.bool(forKey: "sendLogs")
        timerLength = defaults.integer(forKey: "timerLength")
    }
    
    /// Handles updates to the app settings.
    @objc func defaultsChanged(){
        updateDisplayFromDefaults()
    }
    
    /// Create a new ARSession.
    func createARSessionConfiguration() {
        //configuration = ARPositionalTrackingConfiguration()
        configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        //configuration.isAutoFocusEnabled = false
        sceneView.delegate = self
    }
    
    /// Handle the user clicking the confirm alignment to a saved Anchor Point.  Depending on the app state, the behavior of this function will differ (e.g., if the route is being resumed versus reloaded)
    @objc func confirmAlignment() {
        if case .startingPauseProcedure = state {
            state = .pauseWaitingPeriod
        } else if case .startingResumeProcedure = state {
            resumeTracking()
        } else if case .readyForFinalResumeAlignment = state {
            resumeTracking()
        }
    }
    
    /// Play audio feedback and system sound.  This is used currently when the user is facing the appropriate direction along the route.
    @objc func playSound() {
        feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator?.impactOccurred()
        feedbackGenerator = nil
        playSystemSound(id: 1103)
    }

    /// Play the specified system sound.  If the system sound has been preloaded as an audio player, then play using the AVAudioSession.  If there is no corresponding player, use the `AudioServicesPlaySystemSound` function.
    ///
    /// - Parameter id: the id of the system sound to play
    func playSystemSound(id: Int) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            guard let player = audioPlayers[id] else {
                // fallback on system sounds
                AudioServicesPlaySystemSound(SystemSoundID(id))
                return
            }
            
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    /// Adds double tap gesture to the sceneView to handle the anounce direction button (TODO: I'm not sure exactly what this does at the moment and how it differs from the button itself)
    func addGestures() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(announceDirectionHelp))
        tapGestureRecognizer.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }

    /// display RECORD PATH button/hide all other views
    @objc func showRecordPathButton(announceArrival: Bool) {
        add(recordPathController)
        /// handling main screen transitions outside of the first load
        /// add the view of the child to the view of the parent
        routeRatingController.remove()
        stopNavigationController.remove()
        
        rootContainerView.getDirectionButton.isHidden = true
        // the options button is hidden if the route rating shows up
        ///// TRACK
        rootContainerView.homeButton.isHidden = true

        if announceArrival {
            delayTransition(announcement: NSLocalizedString("completedNavigationAnnouncement", comment: "An announcement which is played to notify the user that they have arrived at the end of their route."))
        } else {
            delayTransition()
        }
    }
    
    /// Called when the UI of the view changes dramatically (e.g., if a different subview is displayed).  The optional `announcement` input is will be spoken 2 seconds after the transition occurs.  The delay is necessary to prevent the accessibility notification for screen changed to cut off the announcement.
    ///
    /// - Parameter announcement: the announcement to read after a 2 second delay
    func delayTransition(announcement: String? = nil, initialFocus: UIView? = nil) {
        // this notification currently cuts off the announcement of the button that was just pressed
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: initialFocus)
        if let announcement = announcement {
            if UIAccessibility.isVoiceOverRunning {
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { timer in
                    self.announce(announcement: announcement)
                }
            } else {
                announce(announcement: announcement)
            }
        }
    }
    
    /// Display stop recording view/hide all other views
    @objc func showStopRecordingButton() {
        rootContainerView.homeButton.isHidden = false // home button here
        recordPathController.remove()
        recordPathController.view.isAccessibilityElement = false
        add(stopRecordingController)
        delayTransition(announcement: NSLocalizedString("properDevicePositioningAnnouncement", comment: "This is an announcement which plays to tell the user the best practices for aligning the phone"))
    }
    
    /// Display start navigation view/hide all other views
    @objc func showStartNavigationButton(allowPause: Bool) {
        rootContainerView.homeButton.isHidden = !recordingSingleUseRoute // home button hidden if we are doing a multi use route (we use the large home button instead)
        resumeTrackingController.remove()
        resumeTrackingConfirmController.remove()
        stopRecordingController.remove()
        
        // set appropriate Boolean flags for context
        startNavigationController.isAutomaticAlignment = isAutomaticAlignment
        startNavigationController.recordingSingleUseRoute = recordingSingleUseRoute

        add(startNavigationController)
        startNavigationController.pauseButton.isHidden = !allowPause
        startNavigationController.largeHomeButton.isHidden = recordingSingleUseRoute
        startNavigationController.stackView.layoutIfNeeded()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: startNavigationController.startNavigationButton)
    }

    /// Display the pause tracking view/hide all other views
    func showPauseTrackingButton() throws {
        rootContainerView.homeButton.isHidden = false
        recordPathController.remove()
        startNavigationController.remove()

        // set appropriate Boolean flags
        pauseTrackingController.paused = paused
        pauseTrackingController.recordingSingleUseRoute = recordingSingleUseRoute
        pauseTrackingController.startAnchorPoint = startAnchorPoint
        
        add(pauseTrackingController)
        pauseTrackingController.setMainText(direction: creatingRouteAnchorPoint)
        delayTransition()
    }
    
    /// Display the resume tracking view/hide all other views
    @objc func showResumeTrackingButton() {
        routeSaveGroup.notify(queue: .main) {
            self.rootContainerView.homeButton.isHidden = false // no home button here
            self.pauseTrackingController.remove()
            self.add(self.resumeTrackingController)
            UIApplication.shared.keyWindow!.bringSubviewToFront(self.rootContainerView)
            self.delayTransition()
        }
    }
    
    /// Display the resume tracking confirm view/hide all other views.
    func showResumeTrackingConfirmButton(route: SavedRoute, navigateStartToEnd: Bool) {
        rootContainerView.homeButton.isHidden = false
        resumeTrackingController.remove()
        add(resumeTrackingConfirmController)
        resumeTrackingConfirmController.view.mainText?.text = ""
        voiceNoteToPlay = nil
        if navigateStartToEnd {
            if let AnchorPointInformation = route.beginRouteAnchorPoint.information as String? {
                let infoString = "\n\n" + NSLocalizedString("anchorPointIntroductionToSavedText", comment: "This is the text which delineates the text that a user saved witht their saved anchor point. This text is shown when a suer loads an anchor point and the text that the user saved with their anchor point appears right after this string.") + AnchorPointInformation + "\n\n"
                resumeTrackingConfirmController.anchorPointLabel.text = infoString
            } else {
                // make sure to clear out any old labels that were stored here
                resumeTrackingConfirmController.anchorPointLabel.text = nil
            }
            if let beginRouteAnchorPointVoiceNote = route.beginRouteAnchorPoint.voiceNote {
                let voiceNoteToPlayURL = beginRouteAnchorPointVoiceNote.documentURL
                do {
                    let data = try Data(contentsOf: voiceNoteToPlayURL)
                    voiceNoteToPlay = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.caf.rawValue)
                    voiceNoteToPlay?.prepareToPlay()
                } catch {}
            }
        } else {
            if let AnchorPointInformation = route.endRouteAnchorPoint.information as String? {
                let infoString = "\n\n" + NSLocalizedString("anchorPointIntroductionToSavedText", comment: "This is the text which delineates the text that a user saved witht their saved anchor point. This text is shown when a suer loads an anchor point and the text that the user saved with their anchor point appears right after this string.") + AnchorPointInformation + "\n\n"
                resumeTrackingConfirmController.anchorPointLabel.text = infoString
            } else {
                // make sure to clear out any old labels that were stored here
                resumeTrackingConfirmController.anchorPointLabel.text = nil
            }
            if let endRouteAnchorPointVoiceNote = route.endRouteAnchorPoint.voiceNote {
                let voiceNoteToPlayURL = endRouteAnchorPointVoiceNote.documentURL
                do {
                    let data = try Data(contentsOf: voiceNoteToPlayURL)
                    voiceNoteToPlay = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.caf.rawValue)
                    voiceNoteToPlay?.prepareToPlay()
                } catch {}
            }
        }
        resumeTrackingConfirmController.readVoiceNoteButton?.isHidden = voiceNoteToPlay == nil
        let waitingPeriod = ViewController.alignmentWaitingPeriod
        resumeTrackingConfirmController.view.mainText?.text?.append(String.localizedStringWithFormat(NSLocalizedString("anchorPointAlignmentText", comment: "Text describing the process of aligning to an anchorpoint. This text shows up on the alignment screen."), waitingPeriod))
        delayTransition()
    }
    
    /// display stop navigation view/hide all other views
    @objc func showStopNavigationButton() {
        rootContainerView.homeButton.isHidden = false
        rootContainerView.getDirectionButton.isHidden = false
        startNavigationController.remove()
        add(stopNavigationController)
        
        // this does not auto update, so don't use it as an accessibility element
        delayTransition()
    }
    
    /// display route rating view/hide all other views
    @objc func showRouteRating(announceArrival: Bool) {
        rootContainerView.getDirectionButton.isHidden = true
        rootContainerView.homeButton.isHidden = true
        stopNavigationController.remove()
        
        if sendLogs, let loadedRoute = loadedRoute, let currentImage = currentImage, let currentIntrinsics = currentIntrinsics, let currentPose = currentPose {
            let sendToDevAlert = UIAlertController(title: NSLocalizedString("TestFlightHelpDevsTitle", comment: "Title to ask users to send data"), message: NSLocalizedString("TestFlightHelpDevsContent", comment: "Ask users to send data"), preferredStyle: .alert)
            sendToDevAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                let subdir = TestFlightLogger.uploadData(savedRoute: loadedRoute, image: currentImage, intrinsics: currentIntrinsics, pose: currentPose)
                self.logger.logAlignmentInfo(path: subdir)
            }))
            sendToDevAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            present(sendToDevAlert, animated: true)
        }

        add(routeRatingController)
        if announceArrival {
            routeRatingController.view.mainText?.text = NSLocalizedString("ratingYourServiceViewText", comment: "The text that is displayed when the user has completed navigation of their route. This prompts the user to rate their navigation experience.")
        } else {
            routeRatingController.view.mainText?.text = NSLocalizedString("ratingYourServiceViewText", comment: "The text that is displayed when the user has completed navigation of their route. This prompts the user to rate their navigation experience.")
        }
        
        feedbackGenerator = nil
        waypointFeedbackGenerator = nil
        delayTransition()
    }
    
    /// Announce the direction (both in text and using speech if appropriate).  The function will automatically use the appropriate units based on settings to convert `distance` from meters to the appropriate unit.
    ///
    /// - Parameters:
    ///   - description: the direction text to display (e.g., may include the direction to turn)
    ///   - distance: the distance (expressed in meters)
    ///   - displayDistance: a Boolean that indicates whether to display the distance (true means display distance)
    func updateDirectionText(_ description: String, distance: Float, displayDistance: Bool) {
        let distanceToDisplay = roundToTenths(distance * unitConversionFactor[defaultUnit]!)
        var altText = description
        if (displayDistance) {
            if defaultUnit == 0 || distanceToDisplay >= 10 {
                // don't use fractional feet or for higher numbers of meters (round instead)
                // Related to higher number of meters, there is a somewhat strange behavior in VoiceOver where numbers greater than 10 will be read as, for instance, 11 dot 4 meters (instead of 11 point 4 meters).
                altText += " for \(Int(distanceToDisplay))" + unitText[defaultUnit]!
            } else {
                altText += " for \(distanceToDisplay)" + unitText[defaultUnit]!
            }
        }
        if case .navigatingRoute = state {
            logger.logSpeech(utterance: altText)
        }
        announce(announcement: altText)
    }
    
    // MARK: - BreadCrumbs
    
    /// AR Session Configuration
    //var configuration: ARPositionalTrackingConfiguration!
    var configuration: ARWorldTrackingConfiguration!
    
    /// MARK: - Clew internal datastructures
    
    /// list of crumbs dropped when recording pth
    var crumbs: [LocationInfo]!
    
    /// list of images from the route while recording the path
    var intermediateRouteAnchorPoints: [RouteAnchorPoint] = []
    
    /// list of crumbs dropped when following path
    var followCrumbs: [LocationInfo] {
        guard let anchors = sceneView.session.currentFrame?.anchors else {
            return []
        }
        return anchors.compactMap({$0.name != nil && $0.name! == "followCrumb" ? LocationInfo(transform: $0.transform) : nil })
    }
    
    /// list of keypoints calculated after path completion
    var keypoints: [KeypointInfo]!
    
    /// stores the keypoints that have been checked off along the route thus far
    var checkedOffKeypoints: [KeypointInfo]!
    
    /// SCNNode of the next keypoint
    var keypointNode: SCNNode!
    
    /// SCNNode of the arrow that shows the alignment
    var arrowNode: SCNNode?
    
    /// previous keypoint location - originally set to current location
    var prevKeypointPosition: LocationInfo!

    /// Interface for logging data about the session and the path
    var logger = PathLogger()
    
    /// Interface for matching points to a saved route
    var pathMatcher = PathMatcher()
    
    // MARK: - Timers for background functions
    
    /// times the recording of path crumbs
    var droppingCrumbs: Timer?
    
    /// times the checking of the path navigation process (e.g., have we reached a waypoint)
    var followingCrumbs: Timer?
    
    /// times the generation of haptic feedback
    var hapticTimer: Timer?
    
    /// times the generation of snap to route
    var snapToRouteTimer: Timer?
    
    /// times when an announcement should be removed.  These announcements are displayed on the `announcementText` label.
    var announcementRemovalTimer: Timer?
    
    /// times when the heading offset should be recalculated.  The ability to use the heading offset is currently not exposed to the user.
    var updateHeadingOffsetTimer: Timer?
    
    /// Navigation class and state
    var nav = Navigation()
    
    // MARK: - Haptic generators
    
    /// The haptic feedback generator to use when facing towards the keypoint
    var feedbackGenerator : UIImpactFeedbackGenerator?
    /// The haptic feedback generator to use when a keypoint is reached
    var waypointFeedbackGenerator: UINotificationFeedbackGenerator?
    /// The time of last haptic feedback
    var feedbackTimer: Date!
    /// The delay between haptic feedback pulses in seconds
    static let FEEDBACKDELAY = 0.4
    
    // MARK: - Settings bundle configuration
    
    /// the bundle configuration has 0 as feet and 1 as meters
    let unit = [0: "ft", 1: "m"]
    
    /// the text to display for each possible unit
    let unitText = [0: NSLocalizedString("imperialUnitText", comment: "this is the text which is displayed in the settings to show the user the option of imperial measurements"), 1: NSLocalizedString("metricUnitText", comment: "this is the text which is displayed in the settings to show the user the option of metric measurements")] as [Int : String]
    
    /// the converstion factor to apply to distances as reported by ARKit so that they are expressed in the user's chosen distance units.  ARKit's unit of distance is meters.
    let unitConversionFactor = [0: Float(100.0/2.54/12.0), 1: Float(1.0)]

    /// the selected default unit index (this index cross-references `unit`, `unitText`, and `unitConversionFactor`
    var defaultUnit: Int!
    
    /// the color of the waypoints.  0 is red, 1 is green, 2 is blue, and 3 is random
    var defaultColor: Int!
    
    /// true if sound feedback should be generated when the user is facing the next waypoint, false otherwise
    var soundFeedback: Bool!
    
    /// true if the app should announce directions via text to speech, false otherwise
    var voiceFeedback: Bool!
    
    /// true if haptic feedback should be generated when the user is facing the next waypoint, false otherwise
    var hapticFeedback: Bool!

    /// true if we should prompt the user to rate route navigation and then send log data to the cloud
    var sendLogs: Bool!
    
    /// The length of time that the timer will run for
    var timerLength: Int!

    /// This keeps track of the paused transform while the current session is being realigned to the saved route
    var pausedAnchorPoint : RouteAnchorPoint?
    
    /// the Anchor Point to use to mark the beginning of the route currently being recorded
    var beginRouteAnchorPoint = RouteAnchorPoint()
    
    /// the Anchor Point to use to mark the end of the route currently being recorded
    var endRouteAnchorPoint = RouteAnchorPoint()

    /// the name of the route being recorded
    var routeName: NSString?

    /// the route just recorded.  This is useful for when the user resumes a route that wasn't saved.
    var justTraveledRoute: SavedRoute?
    
    
    /// the most recently used map.  This helps us determine whether a route the user is attempting to load requires alignment.  If we have already aligned within a particular map, we can skip the alignment procedure.
    var justUsedMap : ARWorldMap?
    
    /// DirectionText based on hapic/voice settings
    var Directions: Dictionary<Int, String> {
        if (hapticFeedback) {
            return HapticDirections
        } else {
            return ClockDirections
        }
    }
    
    /// Announces the any excessive motion or insufficient visual features errors as specified in the last observed tracking state
    func announceCurrentTrackingErrors() {
        switch self.trackingSessionState {
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                print("Excessive motion")
                if !self.suppressTrackingWarnings {
                    self.announce(announcement: NSLocalizedString("excessiveMotionDegradedTrackingAnnouncemnt", comment: "An announcement which lets the user know that there is too much movement of their device and thus the app's ability to track a route has been lowered."))
                    if self.soundFeedback {
                        self.playSystemSound(id: 1050)
                    }
                }
            case .insufficientFeatures:
                print("InsufficientFeatures")
                if !self.suppressTrackingWarnings {
                    self.announce(announcement: NSLocalizedString("insuficientFeaturesDegradedTrackingAnnouncemnt", comment: "An announcement which lets the user know  that their current surroundings do not have enough visual markers and thus the app's ability to track a route has been lowered."))
                    if self.soundFeedback {
                        self.playSystemSound(id: 1050)
                    }
                }
            default:
                break
            }
        default:
            break
        }
    }
    
    /// handles the user pressing the record path button.
    @objc func recordPath() {
        ///PATHPOINT record two way path button -> create Anchor Point
        ///route has not been auto aligned
        isAutomaticAlignment = false
        ///tells the program that it is recording a two way route
        recordingSingleUseRoute = false
        //update the state Boolean to say that this is not paused
        paused = false
        ///update the state Boolean to say that this is recording the first anchor point
        startAnchorPoint = true

        ///sends the user to create a Anchor Point
        rootContainerView.homeButton.isHidden = false
        creatingRouteAnchorPoint = true

        hideAllViewsHelper()

        // announce session state
        trackingErrorsAnnouncementTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            self.announceCurrentTrackingErrors()
        }
        // this makes sure that the user doesn't start recording the single use route until the session is initialized
        continuationAfterSessionIsReady = {
            self.trackingErrorsAnnouncementTimer?.invalidate()
            //sends the user to the screen where they can start recording a route
            self.state = .startingPauseProcedure
        }
        configuration.initialWorldMap = nil
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    /// handles the user pressing the stop recording button.
    ///
    /// - Parameter sender: the button that generated the event
    @objc func stopRecording(_ sender: UIButton) {
        isResumedRoute = false

        rootContainerView.homeButton.isHidden = false // home button here
        resumeTrackingController.remove()
        resumeTrackingConfirmController.remove()
        stopRecordingController.remove()
        
        ///checks if the route is a single use route or a multiple use route
        if !recordingSingleUseRoute {
            ///PATHPOINT two way route recording finished -> create end Anchor Point
            ///sets the variable tracking whether the route is paused to be false
            paused = false
            creatingRouteAnchorPoint = false
            ///sends the user to the process where they create an end anchorpoint
            state = .startingPauseProcedure
        } else {
            ///PATHPOINT one way route recording finished -> play/pause
            state = .readyToNavigateOrPause(allowPause: true)
        }
        
    }
    
    /// handles the user pressing the start navigation button.
    ///
    /// - Parameter sender: the button that generated the event
    @objc func startNavigation(_ sender: UIButton) {
        ///announce to the user that return navigation has started.
        self.delayTransition(announcement: NSLocalizedString("startingReturnNavigationAnnouncement", comment: "This is an anouncement which is played when the user performs return navigation from the play pause menu. It signifies the start of a navigation session."), initialFocus: nil)
        // this will handle the appropriate state transition if we pass the warning
        state = .navigatingRoute
        tryVisualAlignment(triesLeft: 10000, makeAnnounement: false)
    }
    
    /// handles the user pressing the stop navigation button.
    ///
    /// - Parameter sender: the button that generated the event
    @objc func stopNavigation(_ sender: UIButton) {
        // stop navigation
        followingCrumbs?.invalidate()
        hapticTimer?.invalidate()
        snapToRouteTimer?.invalidate()
        
        feedbackGenerator = nil
        waypointFeedbackGenerator = nil
        
        // erase nearest keypoint
        keypointNode.removeFromParentNode()
        
        if(sendLogs) {
            state = .ratingRoute(announceArrival: false)
        } else {
            state = .mainScreen(announceArrival: false)
            logger.resetStateSequenceLog()
        }
    }
    
    /// The handler for the snap to route button.
    ///
    /// - Parameter send: the sender of the button pressed event
    @objc func snapToRoute(_ send: UIButton) {
        logger.logSnapToRoute()
        var keypointsToUse: [KeypointInfo] = checkedOffKeypoints
        // always append the next point to check off
        if let firstKeypoint = keypoints.first {
            keypointsToUse.append(firstKeypoint)
        }

        let optimalTransform = pathMatcher.match(points: followCrumbs, toPath: keypointsToUse)
        sceneView.session.setWorldOrigin(relativeTransform: optimalTransform.inverse)
    }
    
    /// handles the user pressing the pause button
    @objc func startPauseProcedure() {
        creatingRouteAnchorPoint = false
        paused = true
        
        //checks if the pause button has been called from inside a recording a multi use route
        if !recordingSingleUseRoute {
            hideAllViewsHelper()
            ///PATHPOINT multi use route pause -> resume route
            self.pauseTracking()
        }else {
            ///PATHPOINT single use route pause -> record end Anchor Point
            state = .startingPauseProcedure
        }
    }
    
    /// handles the user pressing the Anchor Point button
    @objc func startCreateAnchorPointProcedure() {
        rootContainerView.homeButton.isHidden = false
        creatingRouteAnchorPoint = true
        
        ///the route has not been resumed automaticly from a saved route
        isAutomaticAlignment = false
        ///tell the program that a single use route is being recorded
        recordingSingleUseRoute = true
        followingSingleUseRoute = true
        stopNavigationController.followingSingleUseRoute = followingSingleUseRoute
        paused = false
        ///PATHPOINT single use route button -> recording a route
        ///hide all other views
        hideAllViewsHelper()
        
        // announce session state
        trackingErrorsAnnouncementTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            self.announceCurrentTrackingErrors()
        }
        // this makes sure that the user doesn't start recording the single use route until the session is initialized
        continuationAfterSessionIsReady = {
            self.trackingErrorsAnnouncementTimer?.invalidate()
            ///platy an announcemnt which tells the user that a route is being recorded
            self.delayTransition(announcement: NSLocalizedString("singleUseRouteToRecordingRouteAnnouncement", comment: "This is an announcement which is spoken when the user starts recording a single use route. it informs the user that they are recording a single use route."), initialFocus: nil)
            
            //sends the user to the screen where they can start recording a route
            self.state = .recordingRoute
        }
        configuration.initialWorldMap = nil
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    /// this is called after the alignment countdown timer finishes in order to complete the pause tracking procedure
    @objc func pauseTracking() {
        // pause AR pose tracking
        state = .completingPauseProcedure
    }
    
    
    /// Timer for resuming route landmark action
    weak var resumeRouteTimer: Timer?
    
    /// Start the route landmark recording timer
    func startResumeRouteTimer() {
        resumeRouteTimer = Timer.scheduledTimer(
            timeInterval: Double(ViewController.alignmentWaitingPeriod),
            target: self,
            selector: #selector(afterResumeTimerAction(_:)),
            userInfo: nil,
            repeats: false)
    }
    
    
    /// Alignment content to be sent to firebase
    var currentIntrinsics: simd_float3x3?
    var currentImage: UIImage?
    var currentPose: simd_float4x4?
    
    /// Action to take place after route resume countdown
    @objc
    func afterResumeTimerAction(_ timer: Timer) {
        if !state.isTryingToAlign {
            // we must have already aligned using the ARWorldMap, we can stop trying now
            return
        }
        state = .visualAlignmentWaitingPeriod
        self.rootContainerView.countdownTimer.isHidden = true
        self.pausedAnchorPoint?.loadImage()
        // The first check is necessary in case the phone relocalizes before this code executes
        visualTransforms = []
        backupTransform = nil
        tryVisualAlignment(triesLeft: ViewController.maxVisualAlignmentRetryCount, makeAnnounement: true)
    }
        
    func getRelativeTransform(frame: ARFrame, alignTransform: simd_float4x4, visualYawReturn: VisualAlignmentReturn)->simd_float4x4 {
        let alignRotation = simd_float3x3(simd_float3(alignTransform[0, 0], alignTransform[0, 1], alignTransform[0, 2]),
                                          simd_float3(alignTransform[1, 0], alignTransform[1, 1], alignTransform[1, 2]),
                                          simd_float3(alignTransform[2, 0], alignTransform[2, 1], alignTransform[2, 2]))
        
        let leveledAlignRotation = visualYawReturn.square_rotation1.inverse * alignRotation;
        
        var leveledAlignPose = leveledAlignRotation.toPose()
        leveledAlignPose[3] = alignTransform[3]
        
        let cameraTransform = frame.camera.transform
        let cameraRotation = cameraTransform.rotation()
        let leveledCameraRotation = visualYawReturn.square_rotation2.inverse * cameraRotation;
        var leveledCameraPose = leveledCameraRotation.toPose()
        leveledCameraPose[3] = cameraTransform[3]
        
        let yawRotation = simd_float4x4.makeRotate(radians: visualYawReturn.yaw, -1, 0, 0)
        
        return leveledCameraPose * yawRotation.inverse * leveledAlignPose.inverse
    }
    
    func tryVisualAlignment(triesLeft: Int, makeAnnounement: Bool = false) {
        /*if !state.isTryingToAlign {
            return
        }*/
        if let alignAnchorPoint = self.pausedAnchorPoint, let alignAnchorPointImage = alignAnchorPoint.image, let alignTransform = alignAnchorPoint.transform, let frame = self.sceneView.session.currentFrame {
            if makeAnnounement {
                announce(announcement: NSLocalizedString("visualAlignmentConfirmation", comment: "Announce that visual alignment process has began"))
            }

            DispatchQueue.global(qos: .userInitiated).async {
                let intrinsics = frame.camera.intrinsics
                let capturedUIImage = self.pixelBufferToUIImage(pixelBuffer: frame.capturedImage)!
                self.currentIntrinsics = intrinsics
                self.currentImage = capturedUIImage
                self.currentPose = frame.camera.transform
                let visualYawReturn = VisualAlignment.visualYaw(alignAnchorPointImage, alignAnchorPoint.intrinsics!, alignTransform,
                                                                capturedUIImage,
                                                                simd_float4(intrinsics[0, 0], intrinsics[1, 1], intrinsics[2, 0], intrinsics[2, 1]),
                                                                frame.camera.transform)
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                
               let propInliers = visualYawReturn.numMatches > 0 ? Float(visualYawReturn.numInliers) / Float(visualYawReturn.numMatches) : 0.0
                print("alignment inliers \(visualYawReturn.numInliers) \(visualYawReturn.numMatches) \(propInliers) \(visualYawReturn.residualAngle)")

                if visualYawReturn.is_valid, abs(visualYawReturn.residualAngle) < 0.01 {
                    
                    var arrowTransform = matrix_identity_float4x4
                    arrowTransform.columns.3 = frame.camera.transform.columns.3 - simd_float4(0, 0.5, 0, 0)
                    
                    let yaw = ViewController.getYawHelper(frame.camera.transform) + atan2(-visualYawReturn.tx, visualYawReturn.tz)

                    arrowTransform.columns.0 = simd_float4(-sin(yaw), 0, -cos(yaw), 0)
                    arrowTransform.columns.1 = simd_float4(cos(yaw), 0, -sin(yaw), 0)
                    arrowTransform.columns.2 = simd_float4(0, -1, 0, 0)
                    
                    arrowTransform.columns.3 = arrowTransform.columns.3 + arrowTransform.columns.0
                    print("tx \(visualYawReturn.tx) tz \(visualYawReturn.tz)")
                    DispatchQueue.main.async {
                        self.renderArrow(transform: arrowTransform)
                    }
                    
                    
                    let relativeTransform = self.getRelativeTransform(frame: frame, alignTransform: alignTransform, visualYawReturn: visualYawReturn)
                    self.visualTransforms.append(relativeTransform)
                    self.visualAlignmentSuccessSound?.play()
                } else if self.backupTransform == nil {
                    var visualYawReturnCopy = visualYawReturn
                    visualYawReturnCopy.yaw = 0
                    visualYawReturnCopy.is_valid = true
                    self.backupTransform = self.getRelativeTransform(frame: frame, alignTransform: alignTransform, visualYawReturn: visualYawReturnCopy)
                }
                if triesLeft > 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        self.tryVisualAlignment(triesLeft: triesLeft-1)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    if !self.state.isTryingToAlign {
                        // we must have localized to the map or are doign this during the route... let's bail
                        return
                    }
                    if !self.visualTransforms.isEmpty {
                        // Average the SE3 transforms (rotation and translation in 3D).  The averaging is only valid since we constrain the transforms to involve rotation about a common axis.
                        var averageTransform = self.visualTransforms.reduce(simd_float4x4(0.0), { (x,y) in x + y}) * (1.0 / Float(self.visualTransforms.count))
                        averageTransform.columns.0 = simd_normalize(averageTransform.columns.0)
                        averageTransform.columns.1 = simd_normalize(averageTransform.columns.1)
                        averageTransform.columns.2 = simd_normalize(averageTransform.columns.2)
                        
                        let relativeTransform = averageTransform
                        if self.attemptingRelocalization || self.configuration.initialWorldMap == nil {
                            self.sceneView.session.setWorldOrigin(relativeTransform: relativeTransform)
                        }
                    }
                    
                    else {
                        self.announce(announcement: NSLocalizedString("noVisualMatchesUseSnapToRoute", comment: "Instruct to use snap-to-route when no visual matches are found"))
                        
                        if let backupTransform = self.backupTransform {
                            self.sceneView.session.setWorldOrigin(relativeTransform: backupTransform)
                        }
                    }

                    
                    Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(self.playSound)), userInfo: nil, repeats: false)
                    self.isResumedRoute = true
                    self.state = .readyToNavigateOrPause(allowPause: false)
                }
            }
        }
    }
    
    
    
    /// this is called when the user has confirmed the alignment and is the alignment countdown should begin.  Once the alignment countdown has finished, the alignment will be performed and the app will move to the ready to navigate view.
    func resumeTracking() {
        // resume pose tracking with existing ARSessionConfiguration
        hideAllViewsHelper()
        
        pauseTrackingController.remove()
        state = .resumeWaitingPeriod
        rootContainerView.countdownTimer.isHidden = false
        rootContainerView.countdownTimer.start(beginingValue: ViewController.alignmentWaitingPeriod, interval: 1)
        delayTransition()
    }
    
    /// handles the user pressing the resume tracking confirmation button.
    @objc func confirmResumeTracking() {
        if let route = justTraveledRoute {
            state = .startingResumeProcedure(route: route, worldMap: justUsedMap, navigateStartToEnd: false)
        }
    }
    
    // MARK: - Logging
    
    /// send log data for an successful route navigation (thumbs up)
    @objc func sendLogData() {
        // send success log data to Firebase
        logger.compileLogData(false)
        logger.resetStateSequenceLog()
        state = .mainScreen(announceArrival: false)
    }
    
    /// send log data for an unsuccessful route navigation (thumbs down)
    @objc func sendDebugLogData() {
        // send debug log data to Firebase
        logger.compileLogData(true)
        logger.resetStateSequenceLog()
        state = .mainScreen(announceArrival: false)
    }
    
    /// drop a crumb during path recording
    @objc func dropCrumb() {
        guard let frame = sceneView.session.currentFrame, let curLocation = getRealCoordinates(record: true)?.location else {
            return
        }
        
        crumbs.append(curLocation)
        let routeAnchor = RouteAnchorPoint()
        routeAnchor.transform = frame.camera.transform
        let anchorPointImageIdentifier = UUID()
        routeAnchor.intrinsics = simd_float4(frame.camera.intrinsics[0, 0], frame.camera.intrinsics[1, 1], frame.camera.intrinsics[2, 0], frame.camera.intrinsics[2, 1])
        routeAnchor.imageFileName = "\(anchorPointImageIdentifier).jpg" as NSString
        
        guard let anchorPointImage = pixelBufferToUIImage(pixelBuffer: frame.capturedImage) else {
            return
        }
        
        let routeAnchorPointJpeg = anchorPointImage.jpegData(compressionQuality: 1)
        try! routeAnchorPointJpeg?.write(to: routeAnchor.imageFileName!.documentURL, options: .atomic)
        routeAnchor.loadImage()
        intermediateRouteAnchorPoints.append(routeAnchor)
    }
    
    /// checks to see if user is on the right path during navigation.
    @objc func followCrumb() {
        guard let curLocation = getRealCoordinates(record: true) else {
            // TODO: might want to indicate that something is wrong to the user
            return
        }
        print("adding follow crumb", curLocation.location.x, curLocation.location.y, curLocation.location.z)
        let minDistance = followCrumbs.map({sqrt(pow($0.x - curLocation.location.x, 2) + pow($0.y - curLocation.location.y, 2) + pow($0.z - curLocation.location.z, 2)) }).min()
        // always allow this for now if minDistance == nil || minDistance! > 0.2 {
        sceneView.session.add(anchor: ARAnchor(name: "followCrumb", transform: curLocation.location.transform))
       // }
        var directionToNextKeypoint = getDirectionToNextKeypoint(currentLocation: curLocation)
        
        if (directionToNextKeypoint.targetState == PositionState.atTarget) {
            if (keypoints.count > 1) {
                // arrived at keypoint
                // send haptic/sonic feedback
                waypointFeedbackGenerator?.notificationOccurred(.success)
                if (soundFeedback) { playSystemSound(id: 1016) }
                
                // remove current visited keypont from keypoint list
                prevKeypointPosition = keypoints[0].location
                checkedOffKeypoints.append(keypoints[0])
                keypoints.remove(at: 0)
                
                // erase current keypoint and render next keypoint node
                keypointNode.removeFromParentNode()
                renderKeypoint(keypoints[0].location)
                
                // update directions to next keypoint
                directionToNextKeypoint = getDirectionToNextKeypoint(currentLocation: curLocation)
                setDirectionText(currentLocation: curLocation.location, direction: directionToNextKeypoint, displayDistance: false)
            } else {
                // arrived at final keypoint
                // send haptic/sonic feedback
                waypointFeedbackGenerator?.notificationOccurred(.success)
                if (soundFeedback) { playSystemSound(id: 1016) }
                
                // erase current keypoint node
                keypointNode.removeFromParentNode()
                
                followingCrumbs?.invalidate()
                hapticTimer?.invalidate()
                snapToRouteTimer?.invalidate()
                
                // update text and stop navigation
                if(sendLogs) {
                    state = .ratingRoute(announceArrival: true)
                } else {
                    state = .mainScreen(announceArrival: true)
                    logger.resetStateSequenceLog()
                }
            }
        }
    }
    
    /// Calculate the offset between the phone's heading (either its z-axis or y-axis projected into the floor plane) and the user's direction of travel.  This offset allows us to give directions based on the user's movement rather than the direction of the phone.
    ///
    /// - Returns: the offset
    func getHeadingOffset() -> Float? {
        guard let startHeading = headingRingBuffer.get(0), let endHeading = headingRingBuffer.get(-1), let startPosition = locationRingBuffer.get(0), let endPosition = locationRingBuffer.get(-1) else {
            return nil
        }
        // make sure the path was far enough in the ground plane
        if sqrt(pow(startPosition.x - endPosition.x, 2) + pow(startPosition.z - endPosition.z, 2)) < requiredDistance {
            return nil
        }
        
        // make sure that the headings are all close to the start and end headings
        for i in 0..<headingRingBuffer.capacity {
            guard let currAngle = headingRingBuffer.get(i) else {
                return nil
            }
            if abs(nav.getAngleDiff(angle1: currAngle, angle2: startHeading)) > angleDeviationThreshold || abs(nav.getAngleDiff(angle1: currAngle, angle2: endHeading)) > angleDeviationThreshold {
                // the phone turned too much during the last second
                return nil
            }
        }
        // make sure the path is straight
        let u = (endPosition - startPosition).normalized()
        
        for i in 0..<locationRingBuffer.capacity {
            let d = locationRingBuffer.get(i)! - startPosition
            let orthogonalVector = d - u*Scalar(d.dot(u))
            if orthogonalVector.length > linearDeviationThreshold {
                // the phone didn't move in a straight path during the last second
                return nil
            }
        }
        let movementAngle = atan2f((startPosition.x - endPosition.x), (startPosition.z - endPosition.z))
        
        let potentialOffset = nav.getAngleDiff(angle1: movementAngle, angle2: nav.averageAngle(a: startHeading, b: endHeading))
        // check if the user is potentially moving backwards.  We only try to correct for this if the potentialOffset is in the range [0.75 pi, 1.25 pi]
        if cos(potentialOffset) < -sqrt(2)/2 {
            return potentialOffset - Float.pi
        }
        return potentialOffset
    }
  
    /// update the offset between direction of travel and the orientation of the phone.  This supports a feature which allows the user to navigate with the phone pointed in a direction other than the direction of travel.  The feature cannot be accessed by users in the app store version.
    @objc func updateHeadingOffset() {
        // send haptic feedback depending on correct device
        guard let curLocation = getRealCoordinates(record: false) else {
            return
        }
        // NOTE: currPhoneHeading is not the same as curLocation.location.yaw
        let currPhoneHeading = nav.getPhoneHeadingYaw(currentLocation: curLocation)
        headingRingBuffer.insert(currPhoneHeading)
        locationRingBuffer.insert(Vector3(curLocation.location.x, curLocation.location.y, curLocation.location.z))
        
        if let newOffset = getHeadingOffset() {
            if adjustOffset {
                nav.headingOffset = newOffset
            }
        }
    }
    
    /// Compute the heading vector of the phone.  When the phone is mostly upright, this is just the project of the negative z-axis of the device into the x-z plane.  When the phone is mostly flat, this is the y-axis of the phone projected into the x-z plane after the pitch and roll of the phone are undone.  The case where the phone is mostly flat is used primarily for alignment to and creation of Anchor Points.
    ///
    /// - Parameter transform: the position and orientation of the phone
    /// - Returns: the heading vector as a 4 dimensional vector (y-component and w-component will necessarily be 0)
    static func getProjectedHeading(_ transform: simd_float4x4) -> simd_float4 {
        if abs(transform.columns.2.y) < abs(transform.columns.0.y) {
            return -simd_make_float4(transform.columns.2.x, 0, transform.columns.2.z, 0)
        } else {
            // this is a slightly different notion of yaw when the phone is rolled.  This works better for alignment to saved transforms.  I'm not sure whether it is better when navigating a route.
            // This calculates the angle necessary to align the phone's x-axis (long axis) so that it has a 0 component in the y-direction
            let pitchAngle = atan2f(-transform.columns.0.y, transform.columns.2.y)
            let depitchedTransform = transform.rotate(radians: -pitchAngle, 0, 1, 0)
            return -simd_make_float4(depitchedTransform.columns.0.x, 0, depitchedTransform.columns.0.z, 0)
        }
        
    }
    
    /// this gets the yaw of the phone using the heading vector returned by `getProjectedHeading`.
    static func getYawHelper(_ transform: simd_float4x4) -> Float {
        let projectedHeading = getProjectedHeading(transform)
        return atan2f(-projectedHeading.x, -projectedHeading.z)
    }
    
    // MARK: - Render directions
    
    /// send haptic feedback if the device is pointing towards the next keypoint.
    @objc func getHapticFeedback() {
        updateHeadingOffset()
        guard let curLocation = getRealCoordinates(record: false) else {
            // TODO: might want to indicate that something is wrong to the user
            return
        }
        let directionToNextKeypoint = getDirectionToNextKeypoint(currentLocation: curLocation)
        let coneWidth: Float!
        if strictHaptic {
            coneWidth = Float.pi/12
        } else {
            coneWidth = Float.pi/6
        }
        
        // use a stricter criteria than 12 o'clock for providing haptic feedback
        if abs(directionToNextKeypoint.angleDiff) < coneWidth {
            let timeInterval = feedbackTimer.timeIntervalSinceNow
            if(-timeInterval > ViewController.FEEDBACKDELAY) {
                // wait until desired time interval before sending another feedback
                if (hapticFeedback) { feedbackGenerator?.impactOccurred() }
                if (soundFeedback) { playSystemSound(id: 1103) }
                feedbackTimer = Date()
            }
        }
    }
    
    /// Communicates a message to the user via speech.  If VoiceOver is active, then VoiceOver is used to communicate the announcement, otherwise we use the AVSpeechEngine
    ///
    /// - Parameter announcement: the text to read to the user
    func announce(announcement: String) {
        if let currentAnnouncement = currentAnnouncement {
            // don't interrupt current announcement, but if there is something new to say put it on the queue to say next.  Note that adding it to the queue in this fashion could result in the next queued announcement being preempted
            if currentAnnouncement != announcement {
                nextAnnouncement = announcement
            }
            return
        }
        
        rootContainerView.announcementText.isHidden = false
        rootContainerView.announcementText.text = announcement
        announcementRemovalTimer?.invalidate()
        announcementRemovalTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { timer in
            self.rootContainerView.announcementText.isHidden = true
        }
        if UIAccessibility.isVoiceOverRunning {
            // use the VoiceOver API instead of text to speech
            currentAnnouncement = announcement
        
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: announcement)
        } else if voiceFeedback {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSession.Category.playback)
                try audioSession.setActive(true)
                let utterance = AVSpeechUtterance(string: announcement)
                utterance.rate = 0.6
                currentAnnouncement = announcement
                synth.speak(utterance)
            } catch {
                print("Unexpeced error announcing something using AVSpeechEngine!")
            }
        }
    }
    
    /// Get direction to next keypoint based on the current location
    ///
    /// - Parameter currentLocation: the current location of the device
    /// - Returns: the direction to the next keypoint with the distance rounded to the nearest tenth of a meter
    func getDirectionToNextKeypoint(currentLocation: CurrentCoordinateInfo) -> DirectionInfo {
        // returns direction to next keypoint from current location
        var dir = nav.getDirections(currentLocation: currentLocation, nextKeypoint: keypoints[0], isLastKeypoint: keypoints.count == 1)
        dir.distance = roundToTenths(dir.distance)
        return dir
    }
    
    /// Called when the "get directions" button is pressed.  The announcement is made with a 0.5 second delay to allow the button name to be announced.
    @objc func announceDirectionHelpPressed() {
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: (#selector(announceDirectionHelp)), userInfo: nil, repeats: false)
    }
    
    // Called when home button is pressed
    // Chooses the states in which the home page alerts pop up
    @objc func homeButtonPressed() {
    // if the state case needs to have a home button alert, send it to the function that creates the relevant alert
        if case .navigatingRoute = self.state {
            homePageNavigationProcesses()
        }
        else if case .recordingRoute = self.state {
            homePageNavigationProcesses()
        }
        else if case .readyToNavigateOrPause = self.state {
            homePageNavigationProcesses()
        }
        else if case .pauseWaitingPeriod = self.state {
            homePageNavigationProcesses()
        }
        else if case .startingPauseProcedure = self.state {
            homePageNavigationProcesses()
        }
        else if case .completingPauseProcedure = self.state {
            homePageNavigationProcesses()
        }
        else if case .pauseProcedureCompleted = self.state {
            homePageNavigationProcesses()
        }
        else if case .readyForFinalResumeAlignment = self.state {
            homePageNavigationProcesses()
        }
        else if case .startingResumeProcedure = self.state {
            homePageNavigationProcesses()
        }
        else if case .startingNameSavedRouteProcedure = self.state {
            homePageNavigationProcesses()
        }
        else {
            // proceed to home page
            clearState()
            hideAllViewsHelper()
            self.state = .mainScreen(announceArrival: false)
        }
    }
    
    func pixelBufferToUIImage(pixelBuffer: CVPixelBuffer) -> UIImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        return cgImage.map{UIImage(cgImage: $0)}
    }

    @objc func burgerMenuButtonPressed() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "BurgerMenu", bundle: nil)
        let popoverContent = storyBoard.instantiateViewController(withIdentifier: "burgerMenuTapped") as! BurgerMenuViewController
        popoverContent.preferredContentSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        popoverContent.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: popoverContent, action: #selector(popoverContent.doneWithBurgerMenu))
        let nav = UINavigationController(rootViewController: popoverContent)
        nav.modalPresentationStyle = .popover
        let popover = nav.popoverPresentationController
        popover?.delegate = self
        popover?.sourceView = self.view
        popover?.sourceRect = CGRect(x: 0, y: UIConstants.settingsAndHelpFrameHeight/2, width: 0,height: 0)

        self.present(nav, animated: true, completion: nil)
    }
    
    /// Announce directions at any given point to the next keypoint
    @objc func announceDirectionHelp() {
        if case .navigatingRoute = state, let curLocation = getRealCoordinates(record: false) {
            let directionToNextKeypoint = getDirectionToNextKeypoint(currentLocation: curLocation)
            setDirectionText(currentLocation: curLocation.location, direction: directionToNextKeypoint, displayDistance: true)
        }
    }
    
    /// Set the direction text based on the current location and direction info.
    ///
    /// - Parameters:
    ///   - currentLocation: the current location of the device
    ///   - direction: the direction info struct (e.g., as computed by the `Navigation` class)
    ///   - displayDistance: a Boolean that indicates whether the distance to the net keypoint should be displayed (true if it should be displayed, false otherwise)
    func setDirectionText(currentLocation: LocationInfo, direction: DirectionInfo, displayDistance: Bool) {
        // Set direction text for text label and VoiceOver
        let xzNorm = sqrtf(powf(currentLocation.x - keypoints[0].location.x, 2) + powf(currentLocation.z - keypoints[0].location.z, 2))
        let slope = (keypoints[0].location.y - prevKeypointPosition.y) / xzNorm
        let yDistance = abs(keypoints[0].location.y - prevKeypointPosition.y)
        var dir = ""
        
        if yDistance > 1 && slope > 0.3 { // Go upstairs
            if(hapticFeedback) {
                dir += "\(Directions[direction.hapticDirection]!)" + NSLocalizedString("climbStairsDirection", comment: "Additional directions given to user discussing climbing stairs")
            } else {
                dir += "\(Directions[direction.clockDirection]!)" + NSLocalizedString(" and proceed upstairs", comment: "Additional directions given to user telling them to climb stairs")
            }
            updateDirectionText(dir, distance: 0, displayDistance: false)
        } else if yDistance > 1 && slope < -0.3 { // Go downstairs
            if(hapticFeedback) {
                dir += "\(Directions[direction.hapticDirection]!)\(NSLocalizedString("descendStairsDirection" , comment: "This is a direction which instructs the user to descend stairs"))"
            } else {
                dir += "\(Directions[direction.clockDirection]!)\(NSLocalizedString("descendStairsDirection" , comment: "This is a direction which instructs the user to descend stairs"))"
            }
            updateDirectionText(dir, distance: direction.distance, displayDistance: false)
        } else { // normal directions
            if(hapticFeedback) {
                dir += "\(Directions[direction.hapticDirection]!)"
            } else {
                dir += "\(Directions[direction.clockDirection]!)"
            }
            updateDirectionText(dir, distance: direction.distance, displayDistance:  displayDistance)
        }
    }
    
    func renderArrow(transform: simd_float4x4) {
        arrowNode?.removeFromParentNode()
        arrowNode = SCNNode(mdlObject: arrowObject)
        arrowNode?.simdTransform = transform
        arrowNode?.scale = SCNVector3(1, 0.25, 0.25)
        for material in arrowNode!.geometry!.materials {
            material.diffuse.contents = UIColor.red
        }

        sceneView.scene.rootNode.addChildNode(arrowNode!)
    }
    
    /// Create the keypoint SCNNode that corresponds to the rotating flashing element that looks like a navigation pin.
    ///
    /// - Parameter location: the location of the keypoint
    func renderKeypoint(_ location: LocationInfo) {
        // render SCNNode of given keypoint
        keypointNode = SCNNode(mdlObject: keypointObject)

        // configure node attributes
        keypointNode.scale = SCNVector3(0.0004, 0.0004, 0.0004)
        keypointNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        keypointNode.position = SCNVector3(location.x, location.y - 0.2, location.z)
        keypointNode.rotation = SCNVector4(0, 1, 0, (location.yaw - Float.pi/2))
        
        let bound = SCNVector3(
            x: keypointNode.boundingBox.max.x - keypointNode.boundingBox.min.x,
            y: keypointNode.boundingBox.max.y - keypointNode.boundingBox.min.y,
            z: keypointNode.boundingBox.max.z - keypointNode.boundingBox.min.z)
        keypointNode.pivot = SCNMatrix4MakeTranslation(bound.x / 2, bound.y / 2, bound.z / 2)
        
        let spin = CABasicAnimation(keyPath: "rotation")
        spin.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: 0))
        spin.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float(CGFloat(2 * Float.pi))))
        spin.duration = 3
        spin.repeatCount = .infinity
        keypointNode.addAnimation(spin, forKey: "spin around")
        
        // animation - SCNNode flashes red
        let flashRed = SCNAction.customAction(duration: 2) { (node, elapsedTime) -> () in
            let percentage = Float(elapsedTime / 2)
            var color = UIColor.clear
            let power: Float = 2.0
            
            
            if (percentage < 0.5) {
                color = UIColor(red: 1,
                                green: CGFloat(powf(2.0*percentage, power)),
                                blue: CGFloat(powf(2.0*percentage, power)),
                                alpha: 1)
            } else {
                color = UIColor(red: 1,
                                green: CGFloat(powf(2-2.0*percentage, power)),
                                blue: CGFloat(powf(2-2.0*percentage, power)),
                                alpha: 1)
            }
            node.geometry!.firstMaterial!.diffuse.contents = color
        }
        
        // animation - SCNNode flashes green
        let flashGreen = SCNAction.customAction(duration: 2) { (node, elapsedTime) -> () in
            let percentage = Float(elapsedTime / 2)
            var color = UIColor.clear
            let power: Float = 2.0
            
            
            if (percentage < 0.5) {
                color = UIColor(red: CGFloat(powf(2.0*percentage, power)),
                                green: 1,
                                blue: CGFloat(powf(2.0*percentage, power)),
                                alpha: 1)
            } else {
                color = UIColor(red: CGFloat(powf(2-2.0*percentage, power)),
                                green: 1,
                                blue: CGFloat(powf(2-2.0*percentage, power)),
                                alpha: 1)
            }
            node.geometry!.firstMaterial!.diffuse.contents = color
        }
        
        // animation - SCNNode flashes blue
        let flashBlue = SCNAction.customAction(duration: 2) { (node, elapsedTime) -> () in
            let percentage = Float(elapsedTime / 2)
            var color = UIColor.clear
            let power: Float = 2.0
            
            
            if (percentage < 0.5) {
                color = UIColor(red: CGFloat(powf(2.0*percentage, power)),
                                green: CGFloat(powf(2.0*percentage, power)),
                                blue: 1,
                                alpha: 1)
            } else {
                color = UIColor(red: CGFloat(powf(2-2.0*percentage, power)),
                                green: CGFloat(powf(2-2.0*percentage, power)),
                                blue: 1,
                                alpha: 1)
            }
            node.geometry!.firstMaterial!.diffuse.contents = color
        }
        let flashColors = [flashRed, flashGreen, flashBlue]
        
        // set flashing color based on settings bundle configuration
        var changeColor: SCNAction!
        if (defaultColor == 3) {
            changeColor = SCNAction.repeatForever(flashColors[Int(arc4random_uniform(3))])
        } else {
            changeColor = SCNAction.repeatForever(flashColors[defaultColor])
        }
        
        // add keypoint node to view
        keypointNode.runAction(changeColor)
        sceneView.scene.rootNode.addChildNode(keypointNode)
    }
    
    /// Compute the location of the device based on the ARSession.  If the record flag is set to true, record this position in the logs.
    ///
    /// - Parameter record: a Boolean indicating whether to record the computed position (true if it should be computed, false otherwise)
    /// - Returns: the current location as a `CurrentCoordinateInfo` object
    func getRealCoordinates(record: Bool) -> CurrentCoordinateInfo? {
        guard var currTransform = sceneView.session.currentFrame?.camera.transform else {
            return nil
        }

        // returns current location & orientation based on starting origin
        let scn = SCNMatrix4(currTransform)
        let transMatrix = Matrix3([scn.m11, scn.m12, scn.m13,
                                   scn.m21, scn.m22, scn.m23,
                                   scn.m31, scn.m32, scn.m33])
        
        // record location data in debug logs
        if(record) {
            logger.logTransformMatrix(state: state, scn: scn)
        }
        return CurrentCoordinateInfo(LocationInfo(transform: currTransform), transMatrix: transMatrix)
    }
    
    ///Called when there is a change in tracking state.  This is important for both announcing tracking errors to the user and also to triggering some app state transitions.
    ///
    /// - Parameters:
    ///   - session: the AR session associated with the change in tracking state
    ///   - camera: the AR camera associated with the change in tracking state
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var logString: String? = nil

        switch camera.trackingState {
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                logString = "ExcessiveMotion"
                print("Excessive motion")
                if !suppressTrackingWarnings {
                    announce(announcement: NSLocalizedString("excessiveMotionDegradedTrackingAnnouncemnt", comment: "An announcement which lets the user know that there is too much movement of their device and thus the app's ability to track a route has been lowered."))
                    if soundFeedback {
                        playSystemSound(id: 1050)
                    }
                }
            case .insufficientFeatures:
                logString = "InsufficientFeatures"
                print("InsufficientFeatures")
                if !suppressTrackingWarnings {
                    announce(announcement: NSLocalizedString("insuficientFeaturesDegradedTrackingAnnouncemnt", comment: "An announcement which lets the user know  that their current surroundings do not have enough visual markers and thus the app's ability to track a route has been lowered."))
                    if soundFeedback {
                        playSystemSound(id: 1050)
                    }
                }
            case .initializing:
                // don't log anything
                print("initializing")
            case .relocalizing:
                // if we are waiting on the session, proceed now
                if let continuation = continuationAfterSessionIsReady {
                    continuationAfterSessionIsReady = nil
                    continuation()
                }
                logString = "Relocalizing"
                print("Relocalizing")
            @unknown default:
                print("An error condition arose that we didn't know about when the app was last compiled")
            }
        case .normal:
            logString = "Normal"
            
            // if we are waiting on the session, proceed now
            if let continuation = continuationAfterSessionIsReady {
                continuationAfterSessionIsReady = nil
                continuation()
            }
            
            if configuration.initialWorldMap != nil, attemptingRelocalization {
                // This call is necessary to cancel any pending setWorldOrigin call from the alignment procedure.  Depending on timing, it's possible for the relocalization *and* the realignment to both be applied.  This results in the origin essentially being shifted twice and things are then way off
                session.setWorldOrigin(relativeTransform: matrix_identity_float4x4)
                if !suppressTrackingWarnings {
                    announce(announcement: NSLocalizedString("realignToSavedRouteAnnouncement", comment: "An announcement which lets the user know that their surroundings have been matched to a saved route"))
                }
                // We clear out `followCrumbs` as we have no way to update their position relative to the updated world origin.  We could potentially circumvent this if we inserted them as proper SCNNodes
                attemptingRelocalization = false
            } else if case let .limited(reason)? = trackingSessionState {
                if !suppressTrackingWarnings {
                    if reason != .initializing {
                        announce(announcement: NSLocalizedString("fixedTrackingAnnouncement", comment: "Let user know that the ARKit tracking session has returned to its normal quality (this is played after the tracking has been restored from thir being insuficent visual features or excessive motion which degrade the tracking)"))
                        if soundFeedback {
                            playSystemSound(id: 1025)
                        }
                    }
                }
            }

            if state.isTryingToAlign && configuration.initialWorldMap != nil {
                // this will cancel any realignment if it hasn't happened yet and go straight to route navigation mode
                attemptingRelocalization = false
                rootContainerView.countdownTimer.isHidden = true
                isResumedRoute = true
                
                isAutomaticAlignment = true
                
                ///PATHPOINT: Auto Alignment -> resume route
                state = .readyToNavigateOrPause(allowPause: false)
            }

            print("normal")
        case .notAvailable:
            logString = "NotAvailable"
            print("notAvailable")
        }
        if let logString = logString {
            if case .recordingRoute = state {
                logger.logTrackingError(isRecordingPhase: true, trackingError: logString)
            } else if case .navigatingRoute = state {
                logger.logTrackingError(isRecordingPhase: false, trackingError: logString)
            }
        }
        // update the tracking state so we can use it in the next call to this function
        trackingSessionState = camera.trackingState
    }
    
    /// this tells the ARSession that when the app is becoming active again, we should try to relocalize to the previous world map (rather than proceding with the tracking session in the normal state even though the coordinate systems are no longer aligned).
    /// TODO: not sure if this is actually what we should be doing.  Perhaps we should cancel any recording or navigation if this happens rather than trying to relocalize
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
}

// MARK: - methods for implementing RecorderViewControllerDelegate
extension ViewController: RecorderViewControllerDelegate {
    /// Called when a recording starts (currently nothing is done in this function)
    func didStartRecording() {
    }
    
    /// Called when the user finishes recording a voice note.  This function adds the voice note to the `RouteAnchorPoint` object.
    ///
    /// - Parameter audioFileURL: the URL to the audio recording
    func didFinishRecording(audioFileURL: URL) {
        if creatingRouteAnchorPoint {
            // delete the file since we are re-recording it
            if let beginRouteAnchorPointVoiceNote = self.beginRouteAnchorPoint.voiceNote {
                do {
                    try FileManager.default.removeItem(at: beginRouteAnchorPointVoiceNote.documentURL)
                } catch { }
            }
            beginRouteAnchorPoint.voiceNote = audioFileURL.lastPathComponent as NSString
        } else {
            // delete the file since we are re-recording it
            if let endRouteAnchorPointVoiceNote = self.endRouteAnchorPoint.voiceNote {
                do {
                    try FileManager.default.removeItem(at: endRouteAnchorPointVoiceNote.documentURL)
                } catch { }
            }
            endRouteAnchorPoint.voiceNote = audioFileURL.lastPathComponent as NSString
        }
    }
}

// MARK: - UIPopoverPresentationControllerDelegate
extension ViewController: UIPopoverPresentationControllerDelegate {
    /// Makes sure that popovers are not modal
    ///
    /// - Parameter controller: the presentation controller
    /// - Returns: whether or not to use modal style
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    /// Called when a popover is dismissed
    ///
    /// - Parameter popoverPresentationController: the popover presentation controller used to display the popover.  Currently all this does is re-enable tracking warnings if they were previously disabled (e.g., when displaying the help menu).
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        // this will only fire when the popover is dismissed by some UI action, not when the dismiss function is called from one's own code (this is why we use a custom notification to deal with the case when we dismiss the popover ourselves
        suppressTrackingWarnings = false
    }
    
    /// Ensures that all popover segues are popovers (note: I don't quite understand when this would *not* be the case)
    ///
    /// - Parameters:
    ///   - segue: the segue
    ///   - sender: the sender who generated this prepare call
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // All popover segues should be popovers even on iPhone.
        if let popoverController = segue.destination.popoverPresentationController, let button = sender as? UIButton {
            popoverController.delegate = self
            popoverController.sourceRect = button.bounds
        }
    }
}
