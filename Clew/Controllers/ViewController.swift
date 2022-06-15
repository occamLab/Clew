//
//  ViewController.swift
//  ARKitTest
//
//  Created by Chris Seonghwan Yoon & Jeremy Ryan on 7/10/17.
//
// Confirmed issues
// - We are not doing a proper job dealing with resumed routes with respect to logging (we always send recorded stuff in the log file, which we don't always have access to)
//
// Voice Note Recording Feature
// - think about direction of device and how it relates to the route itself (e.g., look to your left)
// - Get buttons to align in the recording view (add transparent third button)
//
// Unconfirmed issues
// - Maybe intercept session was interrupted so that we don't mistakenly try to navigate saved route before relocalization
//
// Major features to implement
//
// Potential enhancements
//  - Possibly create a warning if the phone doesn't appear to be in the correct orientation
//  - revisit turn warning feature.  It doesn't seem to actually help all that much at the moment.

import UIKit
import ARKit
import VectorMath
import Firebase
import FirebaseAuth
import SwiftUI

/// A custom enumeration type that describes the exact state of the app.  The state is not exhaustive (e.g., there are Boolean flags that also track app state).
enum AppState {
    /// This is the screen the comes up immediately after the splash screen
    case mainScreen(announceArrival: Bool)
    /// User is recording the route
    case recordingRoute
    /// User can either navigate back or pause
    case readyToNavigateOrPause(allowPause: Bool)
    /// Finished the tutorial route
    case finishedTutorialRoute(announceArrival: Bool)
    /// User is navigating along a route
    case navigatingRoute
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
    /// the period where the timer is counting down
    case resumeWaitingPeriod
    /// after the countdown has elapsed and visual alignment is actually occuring
    case visuallyAligning
    /// the user is attempting to name the route they're in the process of saving
    case startingNameSavedRouteProcedure(worldMap: ARWorldMap?)
    
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
        case .startingResumeProcedure(let route, let worldMap, let navigateStartToEnd):
            return "startingResumeProcedure(route=\(route.id), mapexists=\(worldMap != nil), navigateStartToEnd=\(navigateStartToEnd))"
        case .readyForFinalResumeAlignment:
            return "readyForFinalResumeAlignment"
        case .resumeWaitingPeriod:
            return "resumeWaitingPeriod"
        case .visuallyAligning:
            return "visuallyAligning"
        case .startingNameSavedRouteProcedure:
            return "startingNameSavedRouteProcedure"
        case .finishedTutorialRoute:
            return "finishedTutorialRoute"
        }
    }
    
    var isInTimerCountdown: Bool {
        if case .pauseWaitingPeriod = self {
            return true
        } else if case .resumeWaitingPeriod = self {
            return true
        }
        return false
    }
    
    var isInReadyForFinalResumeAlignment: Bool {
        if case .readyForFinalResumeAlignment = self {
            return true
        }
        return false
    }
    
    var isAtMainScreen: Bool {
        if case .mainScreen(_) = self {
            return true
        }
        return false
    }
    
    var isTryingToAlign: Bool {
        if case .visuallyAligning = self {
            return true
        }
        return false
    }
}

/// The view controller that handles the main Clew window.  This view controller is always active and handles the various views that are used for different app functionalities.
class ViewController: UIViewController, SRCountdownTimerDelegate {
    // MARK: Properties and subview declarations
    
    /// How long to wait (in seconds) between the alignment request and grabbing the transform
    static var alignmentWaitingPeriod = 5
    
    /// A threshold distance between the user's current position and a voice note.  If the user is closer than this value the voice note will be played
    static let voiceNotePlayDistanceThreshold : Float = 0.75
    
    /// The state of the tracking session as last communicated to us through the delgate protocol.  This is useful if you want to do something different in the delegate method depending on whether there has been an error
    var trackingSessionErrorState : ARTrackingError?
    
    /// The data source for in-app surveys
    let surveyModel = FirebaseFeedbackSurveyModel.shared
    
    /// the last time this particular user was surveyed (nil if we don't know this information or it hasn't been loaded from the database yet)
    var lastSurveyTime: [String: Double] = [:]
    
    /// the last time this particular user submitted each survey (nil if we don't know this information or it hasn't been loaded from the database yet)
    var lastSurveySubmissionTime: [String: Double] = [:]
    
    /// The state of the app.  This should be constantly referenced and updated as the app transitions
    var state = AppState.initializing {
        didSet {
            logger.logStateTransition(newState: state)
            switch state {
            case .recordingRoute:
                handleStateTransitionToRecordingRoute()
            case .readyToNavigateOrPause(_):
                handleStateTransitionToReadyToNavigateOrPause(allowPause: recordingSingleUseRoute, isTutorial: isTutorial)
            case .navigatingRoute:
                handleStateTransitionToNavigatingRoute()
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
            case .visuallyAligning:
                // nothing happens currently
                break
            case .resumeWaitingPeriod:
                // nothing happens currently
                break
            case .startingNameSavedRouteProcedure(let worldMap):
                handleStateTransitionToStartingNameSavedRouteProcedure(worldMap: nil)
            case .initializing:
                break
            case .finishedTutorialRoute(let announceArrival):
                handleStateTransitionToFinishedTutorialRoute(announceArrival: announceArrival)
            }
        }
    }
    
    /// Actions to perform after the tracking session is ready
    var continuationAfterSessionIsReady: (()->())?
    
    /// A boolean that tracks whether or not to suppress tracking warnings.  By default we don't suppress, but when the help popover is presented we do.
    var suppressTrackingWarnings = false
    
    /// A computed attributed that tests if tracking warnings has been suppressed and ensures that the app is in an active state
    var trackingWarningsAllowed: Bool {
        if case .mainScreen(_) = state {
            return false
        }
        if case .finishedTutorialRoute(_) = state {
            return false
        }
        return !suppressTrackingWarnings
    }
    
    var tutorialHostingController: UIViewController?
    
    var burgerMenuController: UIViewController?
    
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
    
    /// this Boolean marks whether or not to use visual alignment with the current route (either pausing or resuming)
    var isVisualAlignment = false

    /// this boolean marks whether or not the phone is vertical (helps with visual alignment)
    var phoneVertical : Bool? = false
    
    /// the action to do after the time is finished
    var timerContinuation: (()->())?
    
    ///this Boolean marks whether or not the app is saving a starting anchor point
    var startAnchorPoint: Bool = false
    
    ///this boolean denotes whether or not the app is loading a route from an automatic alignment
    var isAutomaticAlignment: Bool = false
    
    ///this Boolean markes whether or not the current activities are conducted within the context of the tutorial
    var isTutorial: Bool = false

    /// This is an audio player that queues up the voice note associated with a particular route Anchor Point. The player is created whenever a saved route is loaded. Loading it before the user clicks the "Play Voice Note" button allows us to call the prepareToPlay function which reduces the latency when the user clicks the "Play Voice Note" button.
    var voiceNoteToPlay: AVAudioPlayer?
    
    /// Handler for the mainScreen app state
    ///
    /// - Parameter announceArrival: a Boolean that indicates whether the user's arrival should be announced (true means the user has arrived)
    func handleStateTransitionToMainScreen(announceArrival: Bool) {
        isTutorial = false
        // cancel the timer that announces tracking errors
        trackingErrorsAnnouncementTimer?.invalidate()
        // set this to nil to prevent the app from erroneously detecting that we can auto-align to the route
        ARSessionManager.shared.initialWorldMap = nil
        showRecordPathButton(announceArrival: announceArrival)
    }
    
    /// Handler for the tutorial route state
    ///
    /// - Parameter announceArrival: a Boolean that indicates whether the user's arrival should be announced (true means the user has arrived)
    func handleStateTransitionToFinishedTutorialRoute(announceArrival: Bool) {
        // cancel the timer that announces tracking errors
        trackingErrorsAnnouncementTimer?.invalidate()
        // TODO: see note elsewhere about needing to disable thsi for now. (previous: if the ARSession is running, pause it to conserve battery)
        // set this to nil to prevent the app from erroneously detecting that we can auto-align to the route
        ARSessionManager.shared.initialWorldMap = nil
        showRecordPathButton(announceArrival: announceArrival)
        helpButtonPressed()
        // show the tutorial again
    }
    
    /// Handler for the recordingRoute app state
    func handleStateTransitionToRecordingRoute() {
        // records a new path
        // updates the state Boolean to signifiy that the program is no longer saving the first anchor point
        startAnchorPoint = false
        attemptingRelocalization = false
        
        // TODO: probably don't need to set this to [], but erring on the side of begin conservative
        crumbs = []
        recordingCrumbs = []
        RouteManager.shared.intermediateAnchorPoints = []
        logger.resetPathLog()
        
        showStopRecordingButton()
        droppingCrumbs = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(dropCrumb), userInfo: nil, repeats: true)
        // make sure there are no old values hanging around
        nav.headingOffset = 0.0
        headingRingBuffer.clear()
        locationRingBuffer.clear()
        recordPhaseHeadingOffsets = []
        updateHeadingOffsetTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: (#selector(updateHeadingOffset)), userInfo: nil, repeats: true)
    }
    
    /// Handler for the readyToNavigateOrPause app state
    ///
    /// - Parameter allowPause: a Boolean that determines whether the app should allow the user to pause the route (this is only allowed if it is the initial route recording)
    func handleStateTransitionToReadyToNavigateOrPause(allowPause: Bool, isTutorial: Bool) {
        droppingCrumbs?.invalidate()
        updateHeadingOffsetTimer?.invalidate()
        showStartNavigationButton(allowPause: allowPause, isTutorial: isTutorial)
        suggestAdjustOffsetIfAppropriate()
    }
    
    /// Handler for the navigatingRoute app state
    func handleStateTransitionToNavigatingRoute() {
        // navigate the recorded path

        // If the route has not yet been saved, we can no longer save this route
        routeName = nil
        beginRouteAnchorPoint = RouteAnchorPoint()
        endRouteAnchorPoint = RouteAnchorPoint()

        logger.resetNavigationLog()

        // generate path from PathFinder class
        // enabled hapticFeedback generates more keypoints
        // TODO: need settings manager
        let routeKeypoints = PathFinder(crumbs: crumbs.reversed(), hapticFeedback: hapticFeedback, voiceFeedback: AnnouncementManager.shared.voiceFeedback).keypoints
        RouteManager.shared.setRouteKeypoints(kps: routeKeypoints)
        
        // save keypoints data for debug log
        logger.logKeypoints(keypoints: routeKeypoints)
        
        // render 3D keypoints
        ARSessionManager.shared.renderKeypoint(RouteManager.shared.nextKeypoint!.location, defaultColor: defaultColor)
        
        // ? getting user location
        prevKeypointPosition = getRealCoordinates(record: true)!.location
        
        // render path
        if showPath, let nextKeypoint = RouteManager.shared.nextKeypoint {
            ARSessionManager.shared.renderPath(prevKeypointPosition, nextKeypoint.location, defaultPathColor: defaultPathColor)
        }
        
        // render intermediate anchor points
        ARSessionManager.shared.render(intermediateAnchorPoints: RouteManager.shared.intermediateAnchorPoints)
        
        feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        waypointFeedbackGenerator = UINotificationFeedbackGenerator()
        
        showStopNavigationButton()
        remindedUserOfOffsetAdjustment = false

        // wait a little bit before starting navigation to allow screen to transition and make room for the first direction announcement to be communicated
        
        if UIAccessibility.isVoiceOverRunning {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { timer in
                self.followingCrumbs = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: (#selector(self.followCrumb)), userInfo: nil, repeats: true)
            }
        } else {
            followingCrumbs = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: (#selector(self.followCrumb)), userInfo: nil, repeats: true)
        }
        
        feedbackTimer = Date()
        errorFeedbackTimer = Date()
        playedErrorSoundForOffRoute = false
        // make sure there are no old values hanging around
        headingRingBuffer.clear()
        locationRingBuffer.clear()
        
        hapticTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: (#selector(getHapticFeedback)), userInfo: nil, repeats: true)
    }
    
    /// Handler for the startingResumeProcedure app state
    ///
    /// - Parameters:
    ///   - route: the route to navigate
    ///   - worldMap: the world map to use
    ///   - navigateStartToEnd: a Boolean that is true if we want to navigate from the start to the end and false if we want to navigate from the end to the start.
    func handleStateTransitionToStartingResumeProcedure(route: SavedRoute, worldMap: ARWorldMap?, navigateStartToEnd: Bool) {
        logger.setCurrentRoute(route: route, worldMap: worldMap)
        phoneVertical = nil
        isVisualAlignment = navigateStartToEnd ? route.beginRouteAnchorPoint.imageFileName != nil : route.endRouteAnchorPoint.imageFileName != nil
        
        // load the world map and restart the session so that things have a chance to quiet down before putting it up to the wall
        var isTrackingPerformanceNormal = false
        if case .normal? = ARSessionManager.shared.currentFrame?.camera.trackingState {
            isTrackingPerformanceNormal = true
        }
        var isRelocalizing = false
        if case .limited(reason: .relocalizing)? = ARSessionManager.shared.currentFrame?.camera.trackingState {
            isRelocalizing = true
        }
        var isSameMap = false
        if let worldMap = worldMap {
            // analyze the map to see if we can relocalize
            if ARSessionManager.shared.adjustRelocalizationStrategy(worldMap: worldMap) == .none {
                // unfortunately, we are out of luck.  Better to not use the ARWorldMap
                ARSessionManager.shared.initialWorldMap = nil
                attemptingRelocalization = false
            } else {
                isSameMap = ARSessionManager.shared.initialWorldMap != nil && ARSessionManager.shared.initialWorldMap == worldMap
                ARSessionManager.shared.initialWorldMap = worldMap
                // TODO: see if we can move this out of this if statement
                attemptingRelocalization = isSameMap && !isTrackingPerformanceNormal || !isSameMap
            }
        } else {
            ARSessionManager.shared.relocalizationStrategy = .none
            ARSessionManager.shared.initialWorldMap = nil
        }

        if navigateStartToEnd {
            crumbs = route.crumbs.reversed()
            pausedAnchorPoint = route.beginRouteAnchorPoint
        } else {
            crumbs = route.crumbs
            pausedAnchorPoint = route.endRouteAnchorPoint
        }
        pausedAnchorPoint?.loadImage()
        RouteManager.shared.intermediateAnchorPoints = route.intermediateAnchorPoints
        trackingSessionErrorState = nil
        ARSessionManager.shared.startSession()

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
    func handleStateTransitionToStartingNameSavedRouteProcedure(worldMap: Any?){
        hideAllViewsHelper()
        if let map = worldMap as? ARWorldMap {
            for anchor in map.anchors {
                if let name = anchor.name, name.starts(with: "recording_crumb_") {
                    let lastUnderscore = name.lastIndex(of: "_")!
                    let startSubstring = name.index(after: lastUnderscore)
                    let idx = Int(name.substring(from: startSubstring))
                    let crumbTransform =  recordingCrumbs[idx!-1].transform
                    let anchorTransform = anchor.transform
                    let relativeTransform = crumbTransform.inverse * anchorTransform
                    let angle = simd_quatf(relativeTransform).angle
                    let translation = simd_length(simd_float3(relativeTransform.columns.3.x, relativeTransform.columns.3.y, relativeTransform.columns.3.z))
                    print("\(idx): ", angle, translation)
                }
            }
        }
        
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
        phoneVertical = nil
        try! showChooseAnchorMethodScreen()
    }
    
    /// Handler for the pauseWaitingPeriod app state
    func handleStateTransitionToPauseWaitingPeriod() {
        hideAllViewsHelper()
        ///sets the length of the timer to be equal to what the person has in their settings
        ViewController.alignmentWaitingPeriod = timerLength
        if !isVisualAlignment {
            rootContainerView.countdownTimer.isHidden = false
            rootContainerView.countdownTimer.start(beginingValue: ViewController.alignmentWaitingPeriod, interval: 1)
        }
        delayTransition()
        timerContinuation = {
            self.rootContainerView.countdownTimer.isHidden = true
            self.pauseTracking()
            if self.paused && self.recordingSingleUseRoute {
                ///announce to the user that they have sucessfully saved an anchor point.
                self.delayTransition(announcement: NSLocalizedString("singleUseRouteAnchorPointToPausedStateAnnouncement", comment: "This is the announcement which is spoken after creating an anchor point in the process of pausing the tracking session of recording a single use route"), initialFocus: nil)
            }
        }
    }
    
    /// Checks to see if the user had the phone pointing consistently off-center when recording the route.  If this is the case, set a flag in UserDefaults so that the app can suggests the "Correct Offset of Phone / Body" feature.
    func setShouldSuggestAdjustOffset() {
        // TODO: could do this without conversion by adding an extension
        let offsetsArray = Array(recordPhaseHeadingOffsets)
        if offsetsArray.count > 6 && abs(offsetsArray.avg()) > 0.4 && offsetsArray.mean_abs_dev() < 0.2 {
            UserDefaults.standard.set(true, forKey: "shouldShowAdjustOffsetSuggestion")
        }
    }
    
    /// If appropriate, suggest that the user activate the "Correct Offset of Phone / Body" feature.
    func suggestAdjustOffsetIfAppropriate() {
        let userDefaults: UserDefaults = UserDefaults.standard
        let shouldShowAdjustOffsetSuggestion: Bool? = userDefaults.object(forKey: "shouldShowAdjustOffsetSuggestion") as? Bool
        let showedAdjustOffsetSuggestion: Bool? = userDefaults.object(forKey: "showedAdjustOffsetSuggestion") as? Bool

        if !adjustOffset && shouldShowAdjustOffsetSuggestion == true && showedAdjustOffsetSuggestion != true {
            showAdjustOffsetSuggestion()
            // clear the flag
            userDefaults.set(false, forKey: "shouldShowAdjustOffsetSuggestion")
            // record that the alert has been shown
            userDefaults.set(true, forKey: "showedAdjustOffsetSuggestion")
        }
    }
    
    func getAlignmentImageHelper()->(NSString, simd_float4)? {
        var imageFileName: NSString?
        var intrinsicsVec: simd_float4?
        if isVisualAlignment, let currentFrame = ARSessionManager.shared.currentFrame {
            let anchorPointImageIdentifier = UUID()
            imageFileName = "\(anchorPointImageIdentifier).jpg" as NSString
            
            guard let image = pixelBufferToUIImage(pixelBuffer: currentFrame.capturedImage) else {
                return nil
            }
            
            let anchorPointJpeg = image.jpegData(compressionQuality: 1)
            try! anchorPointJpeg?.write(to: imageFileName!.documentURL, options: .atomic)
            
            let intrinsics = currentFrame.camera.intrinsics
            intrinsicsVec = simd_float4(intrinsics[0, 0], intrinsics[1, 1], intrinsics[2, 0], intrinsics[2, 1])
        }
        if let imageFileName = imageFileName, let intrinsicsVec = intrinsicsVec {
            return (imageFileName, intrinsicsVec)
        }
        return nil
    }
    
    /// Handler for the completingPauseProcedure app state
    func handleStateTransitionToCompletingPauseProcedure() {
        // TODO: we should not be able to create a route Anchor Point if we are in the relocalizing state... (might want to handle this when the user stops navigation on a route they loaded.... This would obviate the need to handle this in the recordPath code as well
        if creatingRouteAnchorPoint {
            guard let currentTransform = ARSessionManager.shared.currentFrame?.camera.transform else {
                print("can't properly save Anchor Point: TODO communicate this to the user somehow")
                return
            }
            // make sure we log the transform
            let _ = self.getRealCoordinates(record: true)
            beginRouteAnchorPoint.anchor = ARAnchor(transform: currentTransform)
            hideAllViewsHelper()
            if isVisualAlignment {
                if let imageAlignment = getAlignmentImageHelper() {
                    beginRouteAnchorPoint.imageFileName = imageAlignment.0
                    beginRouteAnchorPoint.loadImage()
                    beginRouteAnchorPoint.intrinsics = imageAlignment.1
                }
                SoundEffectManager.shared.playSystemSound(id: 1108)
            } else {
                SoundEffectManager.shared.meh()
            }

            ///PATHPOINT begining anchor point alignment timer -> record route
            ///announce to the user that they have sucessfully saved an anchor point.
            delayTransition(announcement: NSLocalizedString("multipleUseRouteAnchorPointToRecordingRouteAnnouncement", comment: "This is the announcement which is spoken after the first anchor point of a multiple use route is saved. this signifies the completeion of the saving an anchor point procedure and the start of recording a route to be saved."), initialFocus: nil)
            ///sends the user to a route recording of the program is creating a beginning route Anchor Point
            state = .recordingRoute
            return
        } else if let currentTransform = ARSessionManager.shared.currentFrame?.camera.transform {
            // make sure to log transform
            let _ = self.getRealCoordinates(record: true)
            endRouteAnchorPoint.anchor = ARAnchor(transform: currentTransform)
            if isVisualAlignment {
                if let imageAlignment = getAlignmentImageHelper() {
                    endRouteAnchorPoint.imageFileName = imageAlignment.0
                    endRouteAnchorPoint.loadImage()
                    endRouteAnchorPoint.intrinsics = imageAlignment.1
                }
                SoundEffectManager.shared.playSystemSound(id: 1108)
            } else {
                SoundEffectManager.shared.meh()
            }

            // no more crumbs
            droppingCrumbs?.invalidate()

            ARSessionManager.shared.sceneView.session.getCurrentWorldMap { worldMap, error in
                self.completingPauseProcedureHelper(worldMap: worldMap)
            }
        }
    }
    
    func completingPauseProcedureHelper(worldMap: ARWorldMap?) {
        //check whether or not the path was called from the pause menu or not
        if paused {
            ///PATHPOINT pause recording anchor point alignment timer -> resume tracking
            //proceed as normal with the pause structure (single use route)
            justTraveledRoute = SavedRoute(id: "single use", name: "single use", crumbs: self.crumbs, dateCreated: Date() as NSDate, beginRouteAnchorPoint: self.beginRouteAnchorPoint, endRouteAnchorPoint: self.endRouteAnchorPoint, intermediateAnchorPoints: RouteManager.shared.intermediateAnchorPoints)
            justUsedMap = worldMap
            showResumeTrackingButton()
            state = .pauseProcedureCompleted
        } else {
            ///PATHPOINT end anchor point alignment timer -> Save Route View
            delayTransition(announcement: NSLocalizedString("multipleUseRouteAnchorPointToSaveARouteAnnouncement", comment: "This is an announcement which is spoken when the user saves the end anchor point for a multiple use route. This signifies the transition from saving an anchor point to the screen where the user can name and save their route"), initialFocus: nil)
            ///sends the user to the play/pause screen
            state = .startingNameSavedRouteProcedure(worldMap: worldMap)
        }
    }
    
    /// Called when the user presses the routes button.  The function will display the `Routes` view, which is managed by `RoutesViewController`.
    @objc func routesButtonPressed() {
        ///update state boolians
        paused = false
        isAutomaticAlignment = false
        recordingSingleUseRoute = false
        
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "SettingsAndHelp", bundle: nil)
        let popoverContent = storyBoard.instantiateViewController(withIdentifier: "Routes") as! RoutesViewController
        popoverContent.rootViewController = self
        popoverContent.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: popoverContent, action: #selector(popoverContent.doneWithRoutes))
        popoverContent.updateRoutes(routes: dataPersistence.routes)
        let nav = UINavigationController(rootViewController: popoverContent)
        let popover = nav.popoverPresentationController
        popover?.delegate = self
        popover?.sourceView = self.view
        
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc func saveRouteButtonPressed() {
        let id = String(Int64(NSDate().timeIntervalSince1970 * 1000)) as NSString
        // Get the input values from user, if it's nil then use timestamp
        self.routeName = nameSavedRouteController.textField.text as NSString? ?? id
        try! self.archive(routeId: id, beginRouteAnchorPoint: self.beginRouteAnchorPoint, endRouteAnchorPoint: self.endRouteAnchorPoint, intermediateAnchorPoints: RouteManager.shared.intermediateAnchorPoints, worldMap: nameSavedRouteController.worldMap)
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
        chooseAnchorMethodController.remove()
        recordPathController.remove()
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
    func archive(routeId: NSString, beginRouteAnchorPoint: RouteAnchorPoint, endRouteAnchorPoint: RouteAnchorPoint, intermediateAnchorPoints: [RouteAnchorPoint], worldMap: Any?) throws {
        let savedRoute = SavedRoute(id: routeId, name: routeName!, crumbs: crumbs, dateCreated: Date() as NSDate, beginRouteAnchorPoint: beginRouteAnchorPoint, endRouteAnchorPoint: endRouteAnchorPoint, intermediateAnchorPoints: intermediateAnchorPoints)
        try dataPersistence.archive(route: savedRoute, worldMap: worldMap)
        justTraveledRoute = savedRoute
    }

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
    
    /// an aray of heading offsets calculated during the record phase.  We use thsi to suggest that users enable the adjustOffest option
    var recordPhaseHeadingOffsets: LinkedList<Float> = []
    /// the last time we stored the heading offset during the record phase (we want to make sure thesse are spaced out by at least a little bit
    var lastRecordPhaseOffsetTime = Date()
    /// a ring buffer used to keep the last 50 positions of the phone
    var locationRingBuffer = RingBuffer<Vector3>(capacity: 50)
    /// a ring buffer used to keep the last 100 headings of the phone
    var headingRingBuffer = RingBuffer<Float>(capacity: 50)

    /// The conection to the Firebase real-time database
    var databaseHandle = Database.database()
    
    /// Route persistence
    var dataPersistence = DataPersistence()
    
    // MARK: - Parameters that can be controlled remotely via Firebase
    
    /// True if the offset between direction of travel and phone should be updated over time
    var adjustOffset: Bool!
    
    /// True if the user has been reminded that the adjusts offset feature is turned on
    var remindedUserOfOffsetAdjustment = false
    
    /// True if we should use a cone of pi/12 and false if we should use a cone of pi/6 when deciding whether to issue haptic feedback
    var strictHaptic = true

    /// Callback function for when `countdownTimer` updates.  This allows us to announce the new value via voice
    ///
    /// - Parameter newValue: the new value (in seconds) displayed on the countdown timer
    @objc func timerDidUpdateCounterValue(sender: SRCountdownTimer, newValue: Int) {
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String(newValue))
    }
        
    @objc func timerDidEnd(sender: SRCountdownTimer, elapsedTime: TimeInterval) {
        if let timerContinuation = timerContinuation {
            timerContinuation()
        }
        timerContinuation = nil
    }
    
    /// Hook in the view class as a view, so that we can access its variables easily
    var rootContainerView: RootContainerView {
        return view as! RootContainerView
    }
    
    /// child view controllers for various app states
    
    /// the controller that hosts the popover survey
    var hostingController: UIViewController?
    
    /// route navigation method choosing VC
    var chooseAnchorMethodController: ChooseAnchorMethodController!
    
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
                
        // set the main view as active
        view = RootContainerView(frame: UIScreen.main.bounds)
        self.modalPresentationStyle = .fullScreen
        // initialize child view controllers
        chooseAnchorMethodController = ChooseAnchorMethodController()
        pauseTrackingController = PauseTrackingController()
        resumeTrackingController = ResumeTrackingController()
        resumeTrackingConfirmController = ResumeTrackingConfirmController()
        stopRecordingController = StopRecordingController()
        recordPathController = RecordPathController()
        startNavigationController = StartNavigationController()
        stopNavigationController = StopNavigationController()
        nameSavedRouteController = NameSavedRouteController()
        ARSessionManager.shared.delegate = self
        
        // Add the scene to the view, which is a RootContainerView
        ARSessionManager.shared.sceneView.frame = view.frame
        view.addSubview(ARSessionManager.shared.sceneView)
        
        createSettingsBundle()
        
        // TODO: we might want to make this wait on the AR session starting up, but since it happens pretty fast it's likely not a big deal
        state = .mainScreen(announceArrival: false)
        view.sendSubviewToBack(ARSessionManager.shared.sceneView)
        
        // targets for global buttons
        ///// TRACK
        rootContainerView.burgerMenuButton.addTarget(self, action: #selector(burgerMenuButtonPressed), for: .touchUpInside)
        
        rootContainerView.homeButton.addTarget(self, action: #selector(homeButtonPressed), for: .touchUpInside)
        
        rootContainerView.helpButton.addTarget(self, action: #selector(helpButtonPressed), for: .touchUpInside)

        rootContainerView.getDirectionButton.addTarget(self, action: #selector(announceDirectionHelpPressed), for: .touchUpInside)

        // make sure this happens after the view is created!
        rootContainerView.countdownTimer.delegate = self
        
        AnnouncementManager.shared.announcementText = rootContainerView.announcementText
        
        ///sets the length of the timer to be equal to what the person has in their settings
        ViewController.alignmentWaitingPeriod = timerLength
        
        addGestures()
        setupFirebaseObservers()
        
        NotificationCenter.default.addObserver(forName: Notification.Name("StartTutorialPath"), object: nil, queue: nil) { (notification) -> Void in
            #if IS_DEV_TARGET
                self.runTutorialPath(routeName: "TutorialFollowPath1")
            #else
                self.runTutorialPath(routeName: "TutorialFollowPathRelease1")
            #endif
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("StartTutorialPath2"), object: nil, queue: nil) { (notification) -> Void in
            #if IS_DEV_TARGET
                self.runTutorialPath(routeName: "TutorialFollowPath2")
            #else
                self.runTutorialPath(routeName: "TutorialFollowPathRelease2")
            #endif
        }

        // we use a custom notification to communicate from the help controller to the main view controller that a popover that should suppress tracking warnings was dimissed
        NotificationCenter.default.addObserver(forName: Notification.Name("ClewPopoverDismissed"), object: nil, queue: nil) { (notification) -> Void in
            self.suppressTrackingWarnings = false
            if self.stopRecordingController.parent == self {
                /// set  record voice note as active
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.stopRecordingController.recordVoiceNoteButton)
            }
        }

        NotificationCenter.default.addObserver(forName: Notification.Name("StartARSessionForTutorialModule"), object: nil, queue: nil) { (notification) -> Void in
            // in case something was already happening, goHome to clear out state
            self.goHome()
            // TODO if session is already running, don't restart it
            self.trackingSessionErrorState = nil
            ARSessionManager.shared.startSession()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil, queue: nil) { (notification) -> Void in
            self.tutorialHostingController?.dismiss(animated: true)
            NotificationCenter.default.post(name: Notification.Name("ClewPopoverDismissed"), object: nil)
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("BurgerMenuReadyToDismiss"), object: nil, queue: nil) { (notification) -> Void in
            self.burgerMenuController?.dismiss(animated: true)
        }
        
        // we use a custom notification to communicate from the help controller to the main view controller that a popover that should suppress tracking warnings was displayed
        NotificationCenter.default.addObserver(forName: Notification.Name("ClewPopoverDisplayed"), object: nil, queue: nil) { (notification) -> Void in
            self.suppressTrackingWarnings = true
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("SurveyPopoverReadyToDismiss"), object: nil, queue: nil) { (notification) -> Void in
            self.hostingController?.dismiss(animated: true)
            NotificationCenter.default.post(name: Notification.Name("ClewPopoverDismissed"), object: nil)
            if let gaveFeedback = notification.object as? Bool, gaveFeedback {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    AnnouncementManager.shared.announce(announcement: NSLocalizedString("thanksForFeedbackAnnouncement", comment: "This is read right after the user fills out a feedback survey."))
                }
            }
        }
        // make sure to fetch these before we need them
        SiriShortcutsManager.shared.updateVoiceShortcuts(completion: nil)
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
        if let currentUID = Auth.auth().currentUser?.uid {
            databaseHandle.reference(withPath: "\(currentUID)").child("surveys").getData() { (error, snapshot) in
                if let error = error {
                    print("Error getting data \(error)")
                }
                else if snapshot?.exists() == true, let userDict = snapshot?.value as? [String : AnyObject] {
                    for (surveyName, surveyInfo) in userDict {
                        if let surveyInfoDict = surveyInfo as? [String : AnyObject] {
                            if let lastSurveyTime = surveyInfoDict["lastSurveyTime"] as? Double {
                                self.lastSurveyTime[surveyName] = lastSurveyTime
                            }
                            if let lastSurveySubmissionTime = surveyInfoDict["lastSurveySubmissionTime"] as? Double {
                                self.lastSurveySubmissionTime[surveyName] = lastSurveySubmissionTime
                            }
                        }
                    }
                }
                else {
                    print("No data available")
                }
            }
        }
        
    }
    
    /// Respond to any dynamic reconfiguration requests (this is currently not used in the app store version of Clew).
    ///
    /// - Parameter snapshot: the new configuration data
    func handleNewConfig(snapshot: DataSnapshot) {
        if snapshot.key == "adjust_offset", let newValue = snapshot.value as? Bool {
            adjustOffset = newValue
            nav.useHeadingOffset = adjustOffset
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

        // To test the SiriShortcut alert, comment out the line below
        // siriShortcutAlert = false
        if firstTimeLoggingIn == nil {
            userDefaults.set(Date().timeIntervalSince1970, forKey: "firstUsageTimeStamp")
            userDefaults.set(true, forKey: "firstTimeLogin")
            showSafetyAlert() {
//                if(!self.siriShortcutAlert){
//                    self.showSignificantChangesHandsFreeAlert()
//                    self.siriShortcutAlert = true
//                }
                if(!self.visualAlignmentAlert){
                    self.showSignificantChangesVisualAlignment()
                    self.visualAlignmentAlert = true
                }
            }
        } else {
//            if(!siriShortcutAlert){
//                showSignificantChangesHandsFreeAlert()
//                siriShortcutAlert = true
//            }
            if(!visualAlignmentAlert){
                showSignificantChangesVisualAlignment()
                visualAlignmentAlert = true
            }
        }
        
        let firstUsageTimeStamp =  userDefaults.object(forKey: "firstUsageTimeStamp") as? Double ?? 0.0
        if Date().timeIntervalSince1970 - firstUsageTimeStamp > 3600*24 {
            // it's been long enough, try to trigger the survey
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                // make sure to wait for data to load from firebase.  If they have started using the app, don't interrupt them.
                if case .mainScreen(_) = self.state {
                    self.presentSurveyIfIntervalHasPassed(mode: "onAppLaunch", logFileURLs: [])
                }
            }
        }
    }
    
    /// func that prepares the state transition to home by clearing active processes and data
    func clearState() {
        // TODO: check for code reuse
        // Clearing All State Processes and Data
        rootContainerView.homeButton.isHidden = true
        timerContinuation = nil
        recordPathController.isAccessibilityElement = false
        if case .navigatingRoute = self.state {
            ARSessionManager.shared.removeNavigationNodes()
        }
        followingCrumbs?.invalidate()
        recordPhaseHeadingOffsets = []
        routeName = nil
        beginRouteAnchorPoint = RouteAnchorPoint()
        endRouteAnchorPoint = RouteAnchorPoint()
        RouteManager.shared.intermediateAnchorPoints = []
        rootContainerView.announcementText.isHidden = true
        nav.headingOffset = 0.0
        headingRingBuffer.clear()
        locationRingBuffer.clear()
        logger.resetNavigationLog()
        logger.resetPathLog()
        hapticTimer?.invalidate()
        logger.resetStateSequenceLog()
    }
    
    /// This finishes the process of pressing the home button (after user has given confirmation)
    @objc func goHome() {
        // proceed to home page
        if case .startingNameSavedRouteProcedure = self.state {
            self.nameSavedRouteController.textField.text = ""
        }
        PathLogger.shared.logEvent(eventDescription: "home button pressed")
        // TODO: this will be called even if nothing interesting has happened in the app.  we should probably check for something to make sure we don't get too many events.
        sendLogDataHelper(pathStatus: nil, announceArrival: false)
        self.clearState()
        self.hideAllViewsHelper()
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
    
    /// function that creates alerts for the home button
    func showAdjustOffsetSuggestion() {
        // Create alert to warn users of lost information
        let alert = UIAlertController(title: NSLocalizedString("showAdjustOffsetSuggestionTitle", comment: "This is the title of an alert which shows up when the user appears to hold their phone at a consistent offset to their direction of motion."),
                                      message: NSLocalizedString("adjustOffsetAlertContent", comment: "this is the content of an alert which tells the user that they should consider enabling the adjust offset feature."),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("turnOnAdjustOffsetButton", comment: "This text appears on a button that turns on the adjust offset feature"), style: .default, handler: { action -> Void in
            // turn on the adjust offset feature
            UserDefaults.standard.set(true, forKey: "adjustOffset")
        }
        ))
        alert.addAction(UIAlertAction(title: NSLocalizedString("declineTurnOnAdjustOffsetButton", comment: "A button which declines to turn on the adjust offset feature"), style: .default, handler: { action -> Void in
            // nothing to do, just stay on the page
        }
        ))
        self.present(alert, animated: true, completion: nil)
    }

    
    /// Show the dialog that allows the user to enter textual information to help them remember a Anchor Point.
    @objc func showAnchorPointInformationDialog() {
        rootContainerView.homeButton.isHidden = false
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
    
    /// Show safety disclaimer when user opens app for the first time.
    func showSafetyAlert(continuationAfterConfirmation: @escaping ()->()) {
        let safetyAlertVC = UIAlertController(title: NSLocalizedString("forYourSafetyPop-UpHeading", comment: "The heading of a pop-up telling the user to be aware of their surroundings while using clew"),
                                              message: NSLocalizedString("forYourSafetyPop-UpContent", comment: "Disclaimer shown to the user when they open the app for the first time"),
                                              preferredStyle: .alert)
        safetyAlertVC.addAction(UIAlertAction(title: NSLocalizedString("anchorPointTextPop-UpConfirmation", comment: "What the user clicks to acknowledge a message and dismiss pop-up"), style: .default) { _ in
            continuationAfterConfirmation()
        })
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
    
    /// Show significant changes alert so the user is not surprised by new app features.
    func showSignificantChangesHandsFreeAlert() {
        let changesAlertVC = UIAlertController(title: NSLocalizedString("significantVersionChangesPop-UpHeading", comment: "The heading of a pop-up telling the user that significant changes have been made to this app version"),
                                               message: NSLocalizedString("significantVersionChangesPopHandsFree-UpContent", comment: "An alert shown to the user to alert them to the fact that significant changes have been made to the app."),
                                               preferredStyle: .actionSheet)
        changesAlertVC.addAction(UIAlertAction(title: NSLocalizedString("significantVersionChanges-HelpMeWithSiri", comment: "What the user clicks to request help setting up Siri shortcuts"), style: .default, handler: { action -> Void in
            let rootView = NavigationView {
                SiriWalkthrough()
            }
            self.tutorialHostingController = UIHostingController(rootView: rootView)
            self.present(self.tutorialHostingController!, animated: true, completion: nil)
        }
        ))
        changesAlertVC.addAction(UIAlertAction(title: NSLocalizedString("dismissSurvey", comment: "This is used for dismissing popovers"), style: .default, handler: { action -> Void in
        }
        ))
        changesAlertVC.popoverPresentationController?.sourceView = rootContainerView.burgerMenuButton
        changesAlertVC.popoverPresentationController?.sourceRect = CGRect.null
        self.present(changesAlertVC, animated: true, completion: nil)
    }
    
    /// Show significant changes alert so the user is not surprised by new app features.
    func showSignificantChangesVisualAlignment() {
        let changesAlertVC = UIAlertController(title: NSLocalizedString("significantVersionChangesPop-UpHeading", comment: "The heading of a pop-up telling the user that significant changes have been made to this app version"),
                                               message: NSLocalizedString("significantVersionChangesVisualAlignment-UpContent", comment: "An alert shown to the user to alert them to the fact that significant changes have been made to the app by adding visual alignment."),
                                               preferredStyle: .actionSheet)
        changesAlertVC.addAction(UIAlertAction(title: NSLocalizedString("significantVersionChanges-VisualAlignment", comment: "What the user clicks to request help learning visual alignment"), style: .default, handler: { action -> Void in
            let rootView = NavigationView {
                VisualAnchorPointPractice()
            }
            self.tutorialHostingController = UIHostingController(rootView: rootView)
            self.present(self.tutorialHostingController!, animated: true, completion: nil)
        }
        ))
        changesAlertVC.addAction(UIAlertAction(title: NSLocalizedString("dismissSurvey", comment: "This is used for dismissing popovers"), style: .default, handler: { action -> Void in
        }
        ))
        changesAlertVC.popoverPresentationController?.sourceView = rootContainerView.burgerMenuButton
        changesAlertVC.popoverPresentationController?.sourceRect = CGRect.null
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
        let usesMetric = Locale.current.usesMetricSystem
        let appDefaults = ["crumbColor": 0, "showPath": true, "pathColor": 0, "hapticFeedback": true, "sendLogs": true, "voiceFeedback": true, "soundFeedback": true, "adjustOffset": false, "units": usesMetric ? 1 : 0, "timerLength":5, "siriShortcutAlert": false] as [String : Any]
        UserDefaults.standard.register(defaults: appDefaults)
    }

    /// Respond to update events to the `UserDefaults` object (the settings of the app).
    func updateDisplayFromDefaults(){
        let defaults = UserDefaults.standard
        
        defaultUnit = defaults.integer(forKey: "units")
        defaultColor = defaults.integer(forKey: "crumbColor")
        showPath = defaults.bool(forKey: "showPath")
        defaultPathColor = defaults.integer(forKey: "pathColor")
        soundFeedback = defaults.bool(forKey: "soundFeedback")
        AnnouncementManager.shared.voiceFeedback = defaults.bool(forKey: "voiceFeedback")
        hapticFeedback = defaults.bool(forKey: "hapticFeedback")
        sendLogs = true // (making this mandatory) defaults.bool(forKey: "sendLogs")
        timerLength = defaults.integer(forKey: "timerLength")
        adjustOffset = defaults.bool(forKey: "adjustOffset")
        nav.useHeadingOffset = adjustOffset
        
        logger.logSettings(defaultUnit: defaultUnit, defaultColor: defaultColor, soundFeedback: soundFeedback, voiceFeedback: AnnouncementManager.shared.voiceFeedback, hapticFeedback: hapticFeedback, sendLogs: sendLogs, timerLength: timerLength, adjustOffset: adjustOffset)
    }
    
    /// Handles updates to the app settings.
    @objc func defaultsChanged(){
        updateDisplayFromDefaults()
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

    /// Adds double tap gesture to the sceneView to handle the anounce direction button (TODO: I'm not sure exactly what this does at the moment and how it differs from the button itself)
    func addGestures() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(announceDirectionHelp))
        tapGestureRecognizer.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }

    // MARK: - drawUI() temp mark for navigation
    
    /// Initializes, configures, and adds all subviews defined programmatically.
    ///
    /// Subviews:
    /// - `getDirectionButton` (`UIButton`)
    /// - `directionText` (`UILabel`)
    /// - `recordPathView` (`UIView`):
    ///   - configured with `UIView.setupButtonContainer(withButton:)`
    ///   - contains record path button, with information stored in `recordPathButton` instance of `ActionButtonComponents`
    /// - `stopRecordingView` (`UIView`):
    ///   - configured with `UIView.setupButtonContainer(withButton:)`
    ///   - contains record path button, with information stored in `stopRecordingButton` instance of `ActionButtonComponents`
    /// - `startNavigationView` (`UIView`)
    /// - `stopNavigationView` (`UIView`):
    ///   - configured with `UIView.setupButtonContainer(withButton:)`
    ///   - contains record path button, with information stored in `stopNavigationButton` instance of `ActionButtonComponents`
    /// - `pauseTrackingView` (`UIView`)
    /// - `resumeTrackingView` (`UIView`)
    /// - `resumeTrackingConfirmView` (`UIView`)
    /// - `routeRatingView` (`UIView`)
    ///
    /// - TODO:
    ///   - DRY
    ///   - AutoLayout
    ///   - `startNavigationView` pause button configuration
    ///   - subview transitions?
    /// display RECORD PATH button/hide all other views
    @objc func showRecordPathButton(announceArrival: Bool) {
        hideAllViewsHelper()
        add(recordPathController)
        /// handling main screen transitions outside of the first load
        
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
        print("initialFocus \(initialFocus) announcement \(announcement)")
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: initialFocus)
        if let announcement = announcement {
            if UIAccessibility.isVoiceOverRunning {
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { timer in
                    AnnouncementManager.shared.announce(announcement: announcement)
                }
            } else {
                AnnouncementManager.shared.announce(announcement: announcement)
            }
        }
    }
    
    /// Display stop recording view/hide all other views
    @objc func showStopRecordingButton() {
        rootContainerView.homeButton.isHidden = false // home button here
        hideAllViewsHelper()
        recordPathController.view.isAccessibilityElement = false
        add(stopRecordingController)
        delayTransition(announcement: NSLocalizedString("properDevicePositioningAnnouncement", comment: "This is an announcement which plays to tell the user the best practices for aligning the phone"))
    }
    
    /// Display start navigation view/hide all other views
    @objc func showStartNavigationButton(allowPause: Bool, isTutorial: Bool) {
        rootContainerView.homeButton.isHidden = !recordingSingleUseRoute // home button hidden if we are doing a multi use route (we use the large home button instead)
        hideAllViewsHelper()
        // set appropriate Boolean flags for context
        startNavigationController.isTutorial = isTutorial
        startNavigationController.isAutomaticAlignment = isAutomaticAlignment
        startNavigationController.recordingSingleUseRoute = recordingSingleUseRoute
        add(startNavigationController)
        startNavigationController.pauseButton.isHidden = !allowPause
        startNavigationController.largeHomeButton.isHidden = recordingSingleUseRoute
        startNavigationController.stackView.layoutIfNeeded()
    
        if !isResumedRoute {
            AnnouncementManager.shared.announce(announcement: NSLocalizedString("stoppedRecordingAnnouncement", comment: "An announcement which lets the user know that they have stopped recording the route."))
        }
        
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: startNavigationController.startNavigationButton)
    }

    /// Display the pause tracking view/hide all other views
    func showChooseAnchorMethodScreen() throws {
        rootContainerView.homeButton.isHidden = false
        hideAllViewsHelper()
        if paused {
            chooseAnchorMethodController.anchorType = .pauseRouteAnchorPoint
        } else if startAnchorPoint {
            chooseAnchorMethodController.anchorType = .beginRouteAnchorPoint
        } else {
            chooseAnchorMethodController.anchorType = .endRouteAnchorPoint
        }
        add(chooseAnchorMethodController)
        delayTransition()
    }
    
    /// Display the pause tracking view/hide all other views
    func showPauseTrackingButton() throws {
        rootContainerView.homeButton.isHidden = false
        hideAllViewsHelper()

        // set appropriate Boolean flags
        pauseTrackingController.paused = paused
        pauseTrackingController.recordingSingleUseRoute = recordingSingleUseRoute
        pauseTrackingController.startAnchorPoint = startAnchorPoint
        pauseTrackingController.isVisualAlignment = isVisualAlignment
        
        add(pauseTrackingController)
        delayTransition()
    }
    
    /// Display the resume tracking view/hide all other views
    @objc func showResumeTrackingButton() {
        rootContainerView.homeButton.isHidden = false // no home button here
        hideAllViewsHelper()
        add(resumeTrackingController)
        UIApplication.shared.keyWindow!.bringSubviewToFront(rootContainerView)
        delayTransition()
    }
    
    /// Display the resume tracking confirm view/hide all other views.
    func showResumeTrackingConfirmButton(route: SavedRoute, navigateStartToEnd: Bool) {
        rootContainerView.homeButton.isHidden = false
        hideAllViewsHelper()
        resumeTrackingConfirmController.isTutorial = isTutorial
        resumeTrackingConfirmController.isVisualAlignment = isVisualAlignment
        add(resumeTrackingConfirmController)
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
        delayTransition()
    }
    
    /// display stop navigation view/hide all other views
    @objc func showStopNavigationButton() {
        hideAllViewsHelper()
        rootContainerView.homeButton.isHidden = false
        rootContainerView.getDirectionButton.isHidden = false
        add(stopNavigationController)
        
        // this does not auto update, so don't use it as an accessibility element
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
                altText += " " + NSLocalizedString("and walk", comment: "this text is presented when getting directions.  It is placed between a direction of how to turn and a distance to travel") + " \(Int(distanceToDisplay))" + unitText[defaultUnit]!
            } else {
                altText += " " + NSLocalizedString("and walk", comment: "this text is presented when getting directions.  It is placed between a direction of how to turn and a distance to travel") + " \(distanceToDisplay)" + unitText[defaultUnit]!
            }
        }
        if !remindedUserOfOffsetAdjustment && adjustOffset {
            altText += ". " + NSLocalizedString("adjustOffsetReminderAnnouncement", comment: "This is the announcement which is spoken after starting navigation if the user has enabled the Correct Offset of Phone / Body option.")
            remindedUserOfOffsetAdjustment = true
        }
        if case .navigatingRoute = state {
            logger.logSpeech(utterance: altText)
        }
        AnnouncementManager.shared.announce(announcement: altText)
    }
        
    /// MARK: - Clew internal datastructures
    
    /// list of crumbs dropped when recording path
    var recordingCrumbs: LinkedList<LocationInfo>!
    
    /// list of crumbs to use for route creation
    var crumbs: [LocationInfo]!
    
    /// previous keypoint location - originally set to current location
    var prevKeypointPosition: LocationInfo!

    /// Interface for logging data about the session and the path
    var logger = PathLogger.shared
    
    // MARK: - Timers for background functions
    
    /// times the recording of path crumbs
    var droppingCrumbs: Timer?
    
    /// times the checking of the path navigation process (e.g., have we reached a waypoint)
    var followingCrumbs: Timer?
    
    /// times the generation of haptic feedback
    var hapticTimer: Timer?
    
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
    
    static let maxVisualAlignmentRetryCount = 20
    static let requiredSuccessfulVisualAlignmentFrames = 5
    static let timeBetweenVisualAlignmentFailureAnnouncements = 5.0

    var errorFeedbackTimer = Date()
    var playedErrorSoundForOffRoute = false
    /// Delay (and interval) before playing the error sound when the user is not facing the next keypoint of the route
    static let delayBeforeErrorSound = 3.0
    /// Delay (and interval) before announcing to the user that they should press the get directions button
    static let delayBeforeErrorAnnouncement = 8.0

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
    
    /// true if path should be shown between waypoints, false otherwise
    var showPath: Bool!
  
    var siriShortcutAlert: Bool {
        get {
            UserDefaults.standard.bool(forKey: "siriShortcutAlert")
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "siriShortcutAlert")
        }
    }
    
    var visualAlignmentAlert: Bool {
        get {
            UserDefaults.standard.bool(forKey: "visualAlignmentAlert")
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "visualAlignmentAlert")
        }
    }
    /// the color of the path.  0 is red, 1 is green, 2 is blue, and 3 is random
    var defaultPathColor: Int!
    
    /// true if sound feedback should be generated when the user is facing the next waypoint, false otherwise
    var soundFeedback: Bool!
    
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
        switch trackingSessionErrorState {
        case .insufficientFeatures:
            if trackingWarningsAllowed {
                AnnouncementManager.shared.announce(announcement: NSLocalizedString("insuficientFeaturesDegradedTrackingAnnouncemnt", comment: "An announcement which lets the user know  that their current surroundings do not have enough visual markers and thus the app's ability to track a route has been lowered."))
                if self.soundFeedback {
                    SoundEffectManager.shared.playSystemSound(id: 1050)
                }
            }
        case .excessiveMotion:
            if trackingWarningsAllowed {
                AnnouncementManager.shared.announce(announcement: NSLocalizedString("excessiveMotionDegradedTrackingAnnouncemnt", comment: "An announcement which lets the user know that there is too much movement of their device and thus the app's ability to track a route has been lowered."))
                if self.soundFeedback {
                    SoundEffectManager.shared.playSystemSound(id: 1050)
                }
            }
        case .none:
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
        ARSessionManager.shared.initialWorldMap = nil
        trackingSessionErrorState = nil
        ARSessionManager.shared.startSession()
    }
    
    /// handles the user pressing the stop recording button.
    ///
    /// - Parameter sender: the button that generated the event
    @objc func stopRecording(_ sender: UIButton?) {
        // copy the recordingCrumbs over for use in path creation
        hideAllViewsHelper()
        crumbs = Array(recordingCrumbs)
        isResumedRoute = false

        rootContainerView.homeButton.isHidden = false // home button here
        setShouldSuggestAdjustOffset()
        // heading offsets should not be updated from this point until route navigation starts
        updateHeadingOffsetTimer?.invalidate()
        recordPhaseHeadingOffsets = []
        
        ///checks if the route is a single use route or a multiple use route
        if !recordingSingleUseRoute {
            AnnouncementManager.shared.announce(announcement: NSLocalizedString("returnAnchorReminder", comment: "Once the user finished stops recording the saved route, they are reminded via an announcement to record an ending anchor point"))
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
    @objc func startNavigation(_ sender: UIButton?) {
        ///announce to the user that return navigation has started.
        self.delayTransition(announcement: NSLocalizedString("startingReturnNavigationAnnouncement", comment: "This is an anouncement which is played when the user performs return navigation from the play pause menu. It signifies the start of a navigation session."), initialFocus: nil)
        // this will handle the appropriate state transition if we pass the warning
        state = .navigatingRoute
    }
    
    /// handles the user pressing the stop navigation button.
    ///
    /// - Parameter sender: the button that generated the event
    @objc func stopNavigation(_ sender: UIButton) {
        // stop navigation
        followingCrumbs?.invalidate()
        hapticTimer?.invalidate()
        
        feedbackGenerator = nil
        waypointFeedbackGenerator = nil
        ARSessionManager.shared.removeNavigationNodes()
        PathLogger.shared.logEvent(eventDescription: "pressed stop")
        sendLogDataHelper(pathStatus: nil)
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
        } else {
            ///PATHPOINT single use route pause -> record end Anchor Point
            state = .startingPauseProcedure
        }
    }
    
    @objc func setVisualAlignment() {
        isVisualAlignment = true
        try? showPauseTrackingButton()
    }
    
    @objc func setPhysicalAlignment() {
        isVisualAlignment = false
        try? showPauseTrackingButton()
    }
    
    /// handles the user pressing the Anchor Point button
    @objc func startCreateAnchorPointProcedure() {
        rootContainerView.homeButton.isHidden = false
        creatingRouteAnchorPoint = true
        
        ///the route has not been resumed automaticly from a saved route
        isAutomaticAlignment = false
        ///tell the program that a single use route is being recorded
        recordingSingleUseRoute = true
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
        ARSessionManager.shared.initialWorldMap = nil
        trackingSessionErrorState = nil
        ARSessionManager.shared.startSession()
    }
    /// this is called after the alignment countdown timer finishes in order to complete the pause tracking procedure
    @objc func pauseTracking() {
        // pause AR pose tracking
        state = .completingPauseProcedure
    }
    
    /// this is called when the user has confirmed the alignment and is the alignment countdown should begin.  Once the alignment countdown has finished, the alignment will be performed and the app will move to the ready to navigate view.
    func resumeTracking() {
        // resume pose tracking with existing ARSessionConfiguration
        hideAllViewsHelper()
        if !isVisualAlignment {
            state = .resumeWaitingPeriod
            rootContainerView.countdownTimer.isHidden = false
            rootContainerView.countdownTimer.start(beginingValue: ViewController.alignmentWaitingPeriod, interval: 1)
            timerContinuation = {
                self.rootContainerView.countdownTimer.isHidden = true
                // The first check is necessary in case the phone relocalizes before this code executes
                if case .resumeWaitingPeriod = self.state, let alignTransform = self.pausedAnchorPoint?.anchor?.transform, let camera = ARSessionManager.shared.currentFrame?.camera {
                    // yaw can be determined by projecting the camera's z-axis into the ground plane and using arc tangent (note: the camera coordinate conventions of ARKit https://developer.apple.com/documentation/arkit/arsessionconfiguration/worldalignment/camera
                    // add this call so we make sure that we log the alignment transform
                    let _ = self.getRealCoordinates(record: true)
                    let alignYaw = ViewController.getYawHelper(alignTransform)
                    let cameraYaw = ViewController.getYawHelper(camera.transform)

                    var leveledCameraPose = simd_float4x4.makeRotate(radians: cameraYaw, 0, 1, 0)
                    leveledCameraPose.columns.3 = camera.transform.columns.3
                    
                    var leveledAlignPose =  simd_float4x4.makeRotate(radians: alignYaw, 0, 1, 0)
                    leveledAlignPose.columns.3 = alignTransform.columns.3
                    
                    ARSessionManager.shared.manualAlignment = leveledCameraPose * leveledAlignPose.inverse
                    
                    PathLogger.shared.logAlignmentEvent(alignmentEvent: .physicalAlignment(transform: camera.transform, isTutorial: self.isTutorial))
                    
                    self.isResumedRoute = true
                    self.paused = false

                    ///PATHPOINT paused anchor point alignment timer -> return navigation
                    ///announce to the user that they have aligned to the anchor point sucessfully and are starting  navigation.
                    self.delayTransition(announcement: NSLocalizedString("resumeAnchorPointToReturnNavigationAnnouncement", comment: "This is an Announcement which indicates that the pause session is complete, that the program was able to align with the anchor point, and that return navigation has started."), initialFocus: nil)
                    self.state = .navigatingRoute
                }
            }
        } else if let pausedAnchorPoint = pausedAnchorPoint {
            state = .visuallyAligning
            VisualAlignmentManager.shared.doVisualAlignment(delegate: self, alignAnchorPoint: pausedAnchorPoint, maxTries: ViewController.maxVisualAlignmentRetryCount, makeAnnouncement: false)
        }
        delayTransition()
    }
    
    /// handles the user pressing the resume tracking confirmation button.
    @objc func confirmResumeTracking() {
        if let route = justTraveledRoute {
            state = .startingResumeProcedure(route: route, worldMap: justUsedMap, navigateStartToEnd: false)
        }
    }
    
    // MARK: - Logging
    
    /// Presents a survey to the user as a popover.  The method will check to see if it has been sufficiently long since the user was last asked to fill out this survey before displaying the survey.
    /// - Parameters:
    ///   - mode: type of survey, accepts "onAppLaunch" and "afterRoute" which correspond to the value of the "currentAppLaunchSurvey" and "currentAfterRouteSurvey" keys respectively located in the Firebase Realtime Database at surveys/
    ///   - logFileURLs: this list of URLs will be added to the survey response JSON file if the user winds up submitting the survey.  This makes it easier to link together feedback in the survey with data logs.
    func presentSurveyIfIntervalHasPassed(mode: String, logFileURLs: [String]) {
        var surveyToTrigger: String = ""
        
        switch mode {
            case "onAppLaunch":
                surveyToTrigger = FirebaseFeedbackSurveyModel.shared.currentAppLaunchSurvey
            case "afterRoute":
                surveyToTrigger = FirebaseFeedbackSurveyModel.shared.currentAfterRouteSurvey
            default:
                surveyToTrigger = "defaultSurvey"
        }
        
        print(surveyToTrigger)
        
        if FirebaseFeedbackSurveyModel.shared.questions[surveyToTrigger] == nil {
            return
        }
        if self.lastSurveySubmissionTime[surveyToTrigger] != nil {
            return
        }
        if self.lastSurveyTime[surveyToTrigger] == nil || -Date(timeIntervalSince1970: self.lastSurveyTime[surveyToTrigger]!).timeIntervalSinceNow >= FirebaseFeedbackSurveyModel.shared.intervals[surveyToTrigger] ?? 0.0 {
            self.lastSurveyTime[surveyToTrigger] = Date().timeIntervalSince1970
            
            if let currentUID = Auth.auth().currentUser?.uid {
                let surveyInfo = ["lastSurveyTime": self.lastSurveyTime[surveyToTrigger]!]
                self.databaseHandle.reference(withPath: "\(currentUID)/surveys/\(surveyToTrigger)").updateChildValues(surveyInfo)
            }
            
            let swiftUIView = FirebaseFeedbackSurvey(feedbackSurveyName: surveyToTrigger, logFileURLs: logFileURLs)
            self.hostingController = UISurveyHostingController(rootView: swiftUIView)
            NotificationCenter.default.post(name: Notification.Name("ClewPopoverDisplayed"), object: nil)
            self.present(self.hostingController!, animated: true, completion: nil)
        }
    }
    
    /// Presents a survey to the user as a popover.  The method will check to see if it has been sufficiently long since the user was last asked to fill out this survey before displaying the survey.
    /// - Parameters:
    ///   - surveyToTrigger: this is the name of the survey, which should be described in the realtime database under "/surveys/{surveyToTrigger}"
    ///   - logFileURLs: this list of URLs will be added to the survey response JSON file if the user winds up submitting the survey.  This makes it easier to link together feedback in the survey with data logs.
    func presentSurveyIfIntervalHasPassedWithSurveyKey(surveyToTrigger: String, logFileURLs: [String]) {
        if FirebaseFeedbackSurveyModel.shared.questions[surveyToTrigger] == nil {
            return
        }
        if self.lastSurveyTime[surveyToTrigger] == nil || -Date(timeIntervalSince1970: self.lastSurveyTime[surveyToTrigger]!).timeIntervalSinceNow >= FirebaseFeedbackSurveyModel.shared.intervals[surveyToTrigger] ?? 0.0 {
            self.lastSurveyTime[surveyToTrigger] = Date().timeIntervalSince1970
            
            if let currentUID = Auth.auth().currentUser?.uid {
                let surveyInfo = ["lastSurveyTime": self.lastSurveyTime[surveyToTrigger]!]
                self.databaseHandle.reference(withPath: "\(currentUID)/surveys/\(surveyToTrigger)").updateChildValues(surveyInfo)
            }
            
            let swiftUIView = FirebaseFeedbackSurvey(feedbackSurveyName: surveyToTrigger, logFileURLs: logFileURLs)
            self.hostingController = UISurveyHostingController(rootView: swiftUIView)
            NotificationCenter.default.post(name: Notification.Name("ClewPopoverDisplayed"), object: nil)
            self.present(self.hostingController!, animated: true, completion: nil)
        }
    }
    
    func sendLogDataHelper(pathStatus: Bool?, announceArrival: Bool = false) {
        // send success log data to Firebase
        let logFileURLs = logger.compileLogData(pathStatus)
        logger.resetStateSequenceLog()
        if case .navigatingRoute = state, isTutorial {
            // TODO: might be able to remove this finishedTutorialRoute state and use the Boolean instead
            state = .finishedTutorialRoute(announceArrival: announceArrival)
        } else {
            state = .mainScreen(announceArrival: announceArrival)
        }
        if sendLogs {
            // do this in a little while to give it time to announce arrival
            DispatchQueue.main.asyncAfter(deadline: .now() + (announceArrival ? 3 : 1)) {
                self.presentSurveyIfIntervalHasPassed(mode: "afterRoute", logFileURLs: logFileURLs)
            }
        }
    }
        
    /// drop a crumb during path recording
    @objc func dropCrumb() {
        guard let curLocation = getRealCoordinates(record: true)?.location, case .recordingRoute = state else {
            return
        }
        recordingCrumbs.append(curLocation)
        ARSessionManager.shared.add(anchor: curLocation)
    }
    
    /// checks to see if user is on the right path during navigation.
    @objc func followCrumb() {
        guard let curLocation = getRealCoordinates(record: true), let nextKeypoint = RouteManager.shared.nextKeypoint else {
            // TODO: might want to indicate that something is wrong to the user
            return
        }
        guard let directionToNextKeypoint = getDirectionToNextKeypoint(currentLocation: curLocation) else {
            return
        }
        
        if (directionToNextKeypoint.targetState == PositionState.atTarget) {
            if !RouteManager.shared.onLastKeypoint {
                // arrived at keypoint
                // send haptic/sonic feedback
                waypointFeedbackGenerator?.notificationOccurred(.success)
                if (soundFeedback) { SoundEffectManager.shared.meh() }
                
                // remove current visited keypont from keypoint list
                prevKeypointPosition = nextKeypoint.location
                RouteManager.shared.checkOffKeypoint()
                
                // erase current keypoint and render next keypoint node
                ARSessionManager.shared.renderKeypoint(RouteManager.shared.nextKeypoint!.location, defaultColor: defaultColor)
                
                if showPath {
                    ARSessionManager.shared.renderPath(prevKeypointPosition, RouteManager.shared.nextKeypoint!.location, defaultPathColor: defaultPathColor)
                }
                
                // update directions to next keypoint
                if let newDirectionToNextKeypoint = getDirectionToNextKeypoint(currentLocation: curLocation) {
                    setDirectionText(currentLocation: curLocation.location, direction: newDirectionToNextKeypoint, displayDistance: false)
                }
            } else {
                // arrived at final keypoint
                // send haptic/sonic feedback
                waypointFeedbackGenerator?.notificationOccurred(.success)
                if (soundFeedback) { SoundEffectManager.shared.success() }

                RouteManager.shared.checkOffKeypoint()
                ARSessionManager.shared.removeNavigationNodes()
                
                followingCrumbs?.invalidate()
                hapticTimer?.invalidate()
                PathLogger.shared.logEvent(eventDescription: "arrived")
                sendLogDataHelper(pathStatus: nil, announceArrival: true)
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
        guard let curLocation = getRealCoordinates(record: false) else {
            return
        }
        // NOTE: currPhoneHeading is not the same as curLocation.location.yaw
        let currPhoneHeading = nav.getPhoneHeadingYaw(currentLocation: curLocation)
        headingRingBuffer.insert(currPhoneHeading)
        locationRingBuffer.insert(Vector3(curLocation.location.x, curLocation.location.y, curLocation.location.z))
        
        if let newOffset = getHeadingOffset(), cos(newOffset) > 0 {
            if case .recordingRoute = state {
                // see if it has been at least 1 second since we last recorded the offset
                if -lastRecordPhaseOffsetTime.timeIntervalSinceNow > 1.0 {
                    recordPhaseHeadingOffsets.append(newOffset)
                    lastRecordPhaseOffsetTime = Date()
                }
            }
            nav.headingOffset = newOffset
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
        let projectedHeading = ViewController.getProjectedHeading(transform)
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
        guard let directionToNextKeypoint = getDirectionToNextKeypoint(currentLocation: curLocation) else {
            return
        }
        let coneWidth: Float!
        let lateralDisplacementToleranceRatio: Float
        if strictHaptic {
            coneWidth = Float.pi/12
            lateralDisplacementToleranceRatio = 0.5          // this is the ratio between lateral distance when passing keypoint and the maximum acceptable lateral displacement
        } else {
            coneWidth = Float.pi/6
            lateralDisplacementToleranceRatio = 1.0
        }
        
        // use a stricter criteria than 12 o'clock for providing haptic feedback
        if directionToNextKeypoint.lateralDistanceRatioWhenCrossingTarget < lateralDisplacementToleranceRatio || abs(directionToNextKeypoint.angleDiff) < coneWidth {
            // mark this since we now want to wait a while before giving error feedback
            errorFeedbackTimer = Date()
            playedErrorSoundForOffRoute = false
            let timeInterval = feedbackTimer.timeIntervalSinceNow
            if(-timeInterval > ViewController.FEEDBACKDELAY) {
                // wait until desired time interval before sending another feedback
                if (hapticFeedback) {
                    feedbackGenerator?.impactOccurred()
                }
                if (soundFeedback) { SoundEffectManager.shared.playSystemSound(id: 1103)
                }
                feedbackTimer = Date()
            }
        } else {
            let timeInterval = errorFeedbackTimer.timeIntervalSinceNow
            if -timeInterval > ViewController.delayBeforeErrorAnnouncement {
                // wait until desired time interval before sending another feedback
                if AnnouncementManager.shared.voiceFeedback {
                    AnnouncementManager.shared.announce(announcement: NSLocalizedString("offThePathAnnouncement", comment: "this announcemet is delivered if the user is off the path for 10 seconds or more."))
                }
                errorFeedbackTimer = Date()
                playedErrorSoundForOffRoute = false
            } else if -timeInterval > ViewController.delayBeforeErrorSound {
                // wait until desired time interval before sending another feedback
                if soundFeedback, !playedErrorSoundForOffRoute { SoundEffectManager.shared.error()
                    playedErrorSoundForOffRoute = true
                }
            }
        }
        for anchorPoint in RouteManager.shared.intermediateAnchorPoints {
            guard let arAnchor = anchorPoint.anchor, let anchorPointTransform = ARSessionManager.shared.getCurrentLocation(of: arAnchor)?.transform else {
                continue
            }
            // TODO think about breaking ties by playing the least recently played voice note
            // TODO consider different floors by considering the y value
            if (voiceNoteToPlay == nil || !voiceNoteToPlay!.isPlaying) && sqrt(pow(anchorPointTransform.columns.3.x - curLocation.location.x,2) + pow(anchorPointTransform.columns.3.z - curLocation.location.z,2)) < ViewController.voiceNotePlayDistanceThreshold {
                // play voice note
                let voiceNoteToPlayURL = anchorPoint.voiceNote!.documentURL
                do {
                    let data = try Data(contentsOf: voiceNoteToPlayURL)
                    voiceNoteToPlay = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.caf.rawValue)
                    voiceNoteToPlay?.prepareToPlay()
                } catch {}
                readVoiceNote()
            }
        }
    }
    
    /// Get direction to next keypoint based on the current location
    ///
    /// - Parameter currentLocation: the current location of the device
    /// - Returns: the direction to the next keypoint with the distance rounded to the nearest tenth of a meter
    func getDirectionToNextKeypoint(currentLocation: CurrentCoordinateInfo) -> DirectionInfo? {
        // returns direction to next keypoint from current location
        guard let nextKeypoint = RouteManager.shared.nextKeypoint, var dir = nav.getDirections(currentLocation: currentLocation, nextKeypoint: nextKeypoint, isLastKeypoint: RouteManager.shared.onLastKeypoint) else {
            return nil
        }
        dir.distance = roundToTenths(dir.distance)
        return dir
    }
    
    /// Called when the "get directions" button is pressed.  The announcement is made with a 0.5 second delay to allow the button name to be announced.
    @objc func announceDirectionHelpPressed() {
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: (#selector(announceDirectionHelp)), userInfo: nil, repeats: false)
    }
    
    @objc func helpButtonPressed() {
        helpButtonPressed(withOverride: nil)
    }
    
    // Called when help button is pressed
    @objc func helpButtonPressed(withOverride pageToDisplayOverride: String? = nil) {
        // TODO: confineToSection is not respected for all tutorial views yet
        var pageToDisplay = pageToDisplayOverride == nil ? "" : pageToDisplayOverride!
        var confineToSection: Bool = true
        let tutorialView = TutorialTestView()
        tutorialHostingController = UIHostingController(rootView: tutorialView)
        
        if pageToDisplayOverride == nil { // determine based on the state
            // TODO: we are turning off contextual help for this release
            confineToSection = false
            switch state {
            case .recordingRoute:
                break //pageToDisplay = "FindPath"
            case .mainScreen(_):
                confineToSection = false
                break
            case .readyToNavigateOrPause(allowPause: let allowPause):
                break // pageToDisplay = "FindPath"
                
            case .navigatingRoute:
                break // pageToDisplay = "FindPath"
                
            case .initializing:
                break // pageToDisplay = "FindPath"
                
            case .startingPauseProcedure:
                break // pageToDisplay = "SavedRoutes"
                
            case .pauseWaitingPeriod:
                break // pageToDisplay = "AnchorPoints"
                
            case .completingPauseProcedure:
                break // pageToDisplay = "AnchorPoints"
                
            case .pauseProcedureCompleted:
                break // pageToDisplay = "AnchorPoints"
                
            case .startingResumeProcedure(route: let route, worldMap: let worldMap, navigateStartToEnd: let navigateStartToEnd):
                break // pageToDisplay = "FindPath"
                
            case .readyForFinalResumeAlignment:
                break // pageToDisplay = "FindPath"
            
            case .resumeWaitingPeriod:
                break
                
            case .visuallyAligning:
                break
                
            case .startingNameSavedRouteProcedure(worldMap: let worldMap):
                break // pageToDisplay = "FindingSavedRoutes"
                
            case .finishedTutorialRoute(_):
                let tutorialView = PracticeSuccess()
                tutorialHostingController = UIHostingController(rootView: tutorialView)
                self.state = .mainScreen(announceArrival: false)
            }
        }
        ShowTutorialPage.shared.confineToSection = confineToSection
        NotificationCenter.default.post(name: Notification.Name("ClewPopoverDisplayed"), object: nil)
        self.present(tutorialHostingController!, animated: false, completion: nil)
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
        else if case .resumeWaitingPeriod = self.state {
            homePageNavigationProcesses()
        }
        else if case .visuallyAligning = self.state {
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
    
    @objc func burgerMenuButtonPressed() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "BurgerMenu", bundle: nil)
        let popoverContent = storyBoard.instantiateViewController(withIdentifier: "burgerMenuTapped") as! BurgerMenuViewController
        popoverContent.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: popoverContent, action: #selector(popoverContent.doneWithBurgerMenu))
        burgerMenuController = popoverContent
        let nav = UINavigationController(rootViewController: popoverContent)
        let popover = nav.popoverPresentationController
        popover?.delegate = self
        popover?.sourceView = self.view

        self.present(nav, animated: true, completion: nil)
    }
    
    /// Announce directions at any given point to the next keypoint
    @objc func announceDirectionHelp() {
        if case .navigatingRoute = state, let curLocation = getRealCoordinates(record: false) {
            if let directionToNextKeypoint = getDirectionToNextKeypoint(currentLocation: curLocation) {
                setDirectionText(currentLocation: curLocation.location, direction: directionToNextKeypoint, displayDistance: true)
            }
        }
    }
    
    /// Set the direction text based on the current location and direction info.
    ///
    /// - Parameters:
    ///   - currentLocation: the current location of the device
    ///   - direction: the direction info struct (e.g., as computed by the `Navigation` class)
    ///   - displayDistance: a Boolean that indicates whether the distance to the net keypoint should be displayed (true if it should be displayed, false otherwise)
    func setDirectionText(currentLocation: LocationInfo, direction: DirectionInfo, displayDistance: Bool) {
        guard let nextKeypoint = RouteManager.shared.nextKeypoint else {
            return
        }
        // Set direction text for text label and VoiceOver
        let xzNorm = sqrtf(powf(currentLocation.x - nextKeypoint.location.x, 2) + powf(currentLocation.z - nextKeypoint.location.z, 2))
        let slope = (nextKeypoint.location.y - prevKeypointPosition.y) / xzNorm
        let yDistance = abs(nextKeypoint.location.y - prevKeypointPosition.y)
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
    
    /// Compute the location of the device based on the ARSession.  If the record flag is set to true, record this position in the logs.
    ///
    /// - Parameter record: a Boolean indicating whether to record the computed position (true if it should be computed, false otherwise)
    /// - Returns: the current location as a `CurrentCoordinateInfo` object
    func getRealCoordinates(record: Bool) -> CurrentCoordinateInfo? {
        guard let currTransform = ARSessionManager.shared.currentFrame?.camera.transform else {
            return nil
        }
        // returns current location & orientation based on starting origin
        let scn = SCNMatrix4(currTransform)
        let transMatrix = Matrix3([scn.m11, scn.m12, scn.m13,
                                   scn.m21, scn.m22, scn.m23,
                                   scn.m31, scn.m32, scn.m33])
        
        // record location data in debug logs
        if(record) {
            logger.logTransformMatrix(state: state, scn: scn, headingOffset: nav.headingOffset, useHeadingOffset: nav.useHeadingOffset)
        }
        return CurrentCoordinateInfo(LocationInfo(transform: currTransform), transMatrix: transMatrix)
    }
    
    func runTutorialPath(routeName: String) {
        goHome()
        isTutorial = true
        let path = Bundle.main.path(forResource: routeName, ofType:"crd")!
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else {
            return
        }
        do {
            if let document = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? RouteDocumentData {
                let thisRoute = document.route
                trackingSessionErrorState = nil
                ARSessionManager.shared.startSession()
                self.continuationAfterSessionIsReady = {
                    self.state = .startingResumeProcedure(route: thisRoute, worldMap: nil, navigateStartToEnd: true)
                }
            }
        } catch {
            print("error \(error)")
        }
    }
    
    /// Checks to see if we need to reset the timer
    /// - Returns: true if timer was reset
    func recordRouteLandmarkHelper() {
        guard isVisualAlignment, state.isTryingToAlign || state.isInTimerCountdown else {
            return
        }
        guard let phoneCurrentlyVertical = ARSessionManager.shared.currentFrame?.camera.transform.isVerticalPhonePose() else {
            return
        }
        
        guard let unwrappedPhoneVertical = phoneVertical else {
            if !phoneCurrentlyVertical {
                if state.isTryingToAlign {
                    AnnouncementManager.shared.announce(announcement: NSLocalizedString("holdVerticallyToBeginAlignment", comment: "Tell the user that the phone must be vertical to start alignment"))
                } else {
                    rootContainerView.countdownTimer.isHidden = true
                    AnnouncementManager.shared.announce(announcement: NSLocalizedString("holdVerticallyToBeginAnchoring", comment: "tell the user that to create an anchor point the phone must be vertical"))
                    rootContainerView.countdownTimer.setNeedsDisplay()
                }
                let nowNotVerticalVibration = UIImpactFeedbackGenerator(style: .heavy)
                nowNotVerticalVibration.impactOccurred()
            } else {
                if state.isTryingToAlign {
                    AnnouncementManager.shared.announce(announcement: NSLocalizedString("cameraNowVerticalStartingAlignment", comment: "tell the user that alignment countdown is starting now that phone is vertical"))
                } else {
                    rootContainerView.countdownTimer.isHidden = false
                    AnnouncementManager.shared.announce(announcement: NSLocalizedString("cameraNowVerticalStartingAnchoring", comment: "tell the user that anchoring countdown is starting now that phone is vertical"))
                    rootContainerView.countdownTimer.start(beginingValue: ViewController.alignmentWaitingPeriod, interval: 1)
                }
                let nowVerticalVibration = UIImpactFeedbackGenerator(style: .light)
                nowVerticalVibration.impactOccurred()
            }
            phoneVertical = phoneCurrentlyVertical
            return
        }
        
        if !phoneCurrentlyVertical && unwrappedPhoneVertical {
            if state.isTryingToAlign {
                AnnouncementManager.shared.announce(announcement: NSLocalizedString("cameraNotVerticalPausingAlignment", comment: "Announce to the user that alignment is paused until the phone becomes vertical again"))
            } else {
                AnnouncementManager.shared.announce(announcement: NSLocalizedString("cameraNotVerticalRestartingAnchoringCountdown", comment: "announce to the user that the anchoring process cannot continue until the phone is vertical"))
                rootContainerView.countdownTimer.isHidden = true
                rootContainerView.countdownTimer.pause()
                rootContainerView.countdownTimer.setNeedsDisplay()
            }
            let nowNotVerticalVibration = UIImpactFeedbackGenerator(style: .heavy)
            nowNotVerticalVibration.impactOccurred()
        } else if phoneCurrentlyVertical && !unwrappedPhoneVertical {
            if state.isTryingToAlign {
                AnnouncementManager.shared.announce(announcement: NSLocalizedString("alignmentCanContinue", comment: "Tell the user the phone is vertical and thus alignment can continue"))
            } else {
                rootContainerView.countdownTimer.isHidden = false
                AnnouncementManager.shared.announce(announcement: NSLocalizedString("cameraNowVerticalStartingAnchoring", comment: "tell the user that anchoring countdown is starting now that phone is vertical"))
                rootContainerView.countdownTimer.start(beginingValue: ViewController.alignmentWaitingPeriod, interval: 1)
            }
            let nowVerticalVibration = UIImpactFeedbackGenerator(style: .light)
            nowVerticalVibration.impactOccurred()
        }
        phoneVertical = phoneCurrentlyVertical
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
        if case .recordingRoute = state {
            guard let currentTransform = ARSessionManager.shared.currentFrame?.camera.transform else {
                print("can't properly save Anchor Point since AR session is not running")
                return
            }
            let noteAnchorPoint = RouteAnchorPoint()
            noteAnchorPoint.voiceNote = audioFileURL.lastPathComponent as NSString
            noteAnchorPoint.anchor = ARAnchor(transform: currentTransform)
            ARSessionManager.shared.sceneView.session.add(anchor: noteAnchorPoint.anchor!)
            RouteManager.shared.intermediateAnchorPoints.append(noteAnchorPoint)
        } else {
            print(audioFileURL)
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

class UISurveyHostingController: UIHostingController<FirebaseFeedbackSurvey> {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.view)
        }
    }
}

extension ViewController: ARSessionManagerDelegate {
    func getPathColor() -> Int {
        return defaultPathColor
    }
    
    func getKeypointColor() -> Int {
        return defaultColor
    }
    
    func getShowPath() ->Bool {
        return showPath
    }
    
    func trackingErrorOccurred(_ trackingError : ARTrackingError) {
        trackingSessionErrorState = trackingError
        announceCurrentTrackingErrors()
    }
    
    func sessionInitialized() {
        if let continuation = continuationAfterSessionIsReady {
            continuationAfterSessionIsReady = nil
            continuation()
        }
    }
    
    func sessionRelocalizing() {
        trackingSessionErrorState = nil
    }
    
    func trackingIsNormal() {
        let oldTrackingSessionErrorState = trackingSessionErrorState
        trackingSessionErrorState = nil
        // if we are waiting on the session, proceed now
        if let continuation = continuationAfterSessionIsReady {
            continuationAfterSessionIsReady = nil
            continuation()
        }
        if ARSessionManager.shared.initialWorldMap != nil, attemptingRelocalization {
            if trackingWarningsAllowed {
                AnnouncementManager.shared.announce(announcement: NSLocalizedString("realignToSavedRouteAnnouncement", comment: "An announcement which lets the user know that their surroundings have been matched to a saved route"))
            }
            attemptingRelocalization = false
        } else if oldTrackingSessionErrorState != nil {
            if trackingWarningsAllowed {
                AnnouncementManager.shared.announce(announcement: NSLocalizedString("fixedTrackingAnnouncement", comment: "Let user know that the ARKit tracking session has returned to its normal quality (this is played after the tracking has been restored from thir being insuficent visual features or excessive motion which degrade the tracking)"))
                if soundFeedback {
                    SoundEffectManager.shared.playSystemSound(id: 1025)
                }
            }
        }
        if state.isInReadyForFinalResumeAlignment || state.isInTimerCountdown || state.isTryingToAlign {
            // this will cancel any realignment if it hasn't happened yet and go straight to route navigation mode
            rootContainerView.countdownTimer.isHidden = true
            isResumedRoute = true
            
            isAutomaticAlignment = true
            
            ///PATHPOINT: Auto Alignment -> resume route
            if !isTutorial, ARSessionManager.shared.initialWorldMap != nil {
                state = .readyToNavigateOrPause(allowPause: false)
            }
        }
    }
    
    func isRecording() -> Bool {
        if case .recordingRoute = state {
            return true
        } else {
            return false
        }
    }
    
    func newFrameAvailable() {
        recordRouteLandmarkHelper()
    }
}

extension ViewController: VisualAlignmentManagerDelegate {
    func shouldContinueAlignment() -> Bool {
        if state.isAtMainScreen {
            // once we are at the main screen, we need to stop
            return false
        }
        if case .readyToNavigateOrPause(_) = state {
            return false
        }
        if !state.isTryingToAlign || !attemptingRelocalization {
            return false
        }
        return true
    }
    
    func isPhoneVertical()->Bool? {
        return phoneVertical
    }
    
    func alignmentSuccessful(manualAlignment: simd_float4x4) {
        if self.attemptingRelocalization || ARSessionManager.shared.initialWorldMap == nil {
            
            ARSessionManager.shared.manualAlignment = manualAlignment
        }
        paused = false

        ///PATHPOINT paused anchor point alignment timer -> return navigation
        ///announce to the user that they have aligned to the anchor point sucessfully and are starting  navigation.
        delayTransition(announcement: NSLocalizedString("resumeAnchorPointToReturnNavigationAnnouncement", comment: "This is an Announcement which indicates that the pause session is complete, that the program was able to align with the anchor point, and that return navigation has started."), initialFocus: nil)
        state = .navigatingRoute
    }
    
    func alignmentFailed(fallbackTransform: simd_float4x4) {
        AnnouncementManager.shared.announce(announcement: NSLocalizedString("noVisualMatchesNavigationNavigationIsUnlikelyToWorkWell", comment: "Warn user that navigation is unlikely to work well"))
        
        ARSessionManager.shared.manualAlignment = fallbackTransform
        SoundEffectManager.shared.meh()
        isResumedRoute = true
        state = .readyToNavigateOrPause(allowPause: false)
    }
}
