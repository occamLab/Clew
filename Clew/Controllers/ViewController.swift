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
// Unconfirmed issues issues
// - Maybe intercept session was interrupted so that we don't mistakenly try to navigate saved route before relocalization
//
// Major features to implement
//
// Potential enhancements
//  - Warn user via an alert if they have an iPhone 5S or 6
//  - Possibly create a warning if the phone doesn't appear to be in the correct orientation
//  - revisit turn warning feature.  It doesn't seem to actually help all that much at the moment.

import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO
import StoreKit
import AVFoundation
import AudioToolbox
import MediaPlayer
import CoreHaptics
import VectorMath
import Firebase
//import SRCountdownTimer
import SwiftUI
import Firebase
#if !APPCLIP
import ARDataLogger
#endif
import CoreNFC

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
    /// the user is attempting to name the app clip code ID for the route they're in the process of saving
    case startingNameCodeIDProcedure
    /// the user is navigating a recorded route from an ARImageAnchor
    case startingAutoAlignment
    /// the user is creating a route anchored from an ARImageAnchor
    case startingAutoAnchoring
    /// the user has stopped or completed an external route
    case endScreen(completedRoute: Bool)
    
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
        case .startingNameSavedRouteProcedure:
            return "startingNameSavedRouteProcedure"
        case .startingNameCodeIDProcedure:
            return "startingNameCodeIDProcedure"
        case .startingAutoAlignment:
            return "startingAutoAlignment"
        case .startingAutoAnchoring:
            return "startingAutoAnchoring"
        case .endScreen:
            return "endScreen"
        }
    }
}

/// Add clewGreen as a color
extension Color {
    static let clewGreen = Color(red: 105 / 255, green: 189 / 255, blue: 72 / 255)
}

/// The view controller that handles the main Clew window.  This view controller is always active and handles the various views that are used for different app functionalities.
class ViewController: UIViewController, SRCountdownTimerDelegate, AVSpeechSynthesizerDelegate, NFCNDEFReaderSessionDelegate {
    
    // MARK: - Refactoring UI definition
    
    // MARK: Properties and subview declarations
    
    /// How long to wait (in seconds) between the alignment request and grabbing the transform
    static var alignmentWaitingPeriod = 5
    
    /// A threshold distance between the user's current position and a voice note.  If the user is closer than this value the voice note will be played
    static let voiceNotePlayDistanceThreshold : Float = 1.5
    
    /// The state of the ARKit tracking session as last communicated to us through the delegate protocol.  This is useful if you want to do something different in the delegate method depending on the previous state
    var trackingSessionErrorState : ARTrackingError?
    #if !APPCLIP
    let surveyModel = FirebaseFeedbackSurveyModel.shared
    #endif
    
    /// the last time this particular user was surveyed (nil if we don't know this information or it hasn't been loaded from the database yet)
    var lastSurveyTime: [String: Double] = [:]
    
    /// TEMPORARY to prevent multiple auto alignments
    var autoAlignPending = false
    
    /// Helper Classes
    let firebaseSetup = FirebaseSetup()
    
    /// Allows us to use the core haptics API
    var hapticEngine: CHHapticEngine?
    /// Controls the dynamic haptic pattern at the end of the route
    var hapticPlayer: CHHapticAdvancedPatternPlayer?
    
    let surveyInterface = SurveyInterface()
    
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
            case .startingNameCodeIDProcedure:
                handleStateTransitionToStartingNameCodeIDProcedure()
            case .startingNameSavedRouteProcedure(let worldMap):
                handleStateTransitionToStartingNameSavedRouteProcedure(worldMap: worldMap)
            case .initializing:
                break
            case .startingAutoAlignment:
                handleStateTransitionToAutoAlignment()
            case .startingAutoAnchoring:
                handleStateTransitionToAutoAnchoring()
            case .endScreen(let completedRoute):
                print("transitioned to the end screen")
                showEndScreenInformation(completedRoute: completedRoute)
            }
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
    
    /// A computed attributed that tests if tracking warnings has been suppressed and ensures that the app is in an active state
    var trackingWarningsAllowed: Bool {
        if case .mainScreen(_) = state {
            return false
        }
        return !suppressTrackingWarnings
    }
    
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
    
    ///this Boolean marks whether or not the app is saving a starting anchor point
    var startAnchorPoint: Bool = false
    
    ///this boolean denotes whether or not the app is loading a route from an automatic alignment
    var isAutomaticAlignment: Bool = false
    
    /// ARDataLogger
    #if !APPCLIP
    var arLogger = ARLogger.shared
    #endif
    
    /// This is an audio player that queues up the voice note associated with a particular route Anchor Point. The player is created whenever a saved route is loaded. Loading it before the user clicks the "Play Voice Note" button allows us to call the prepareToPlay function which reduces the latency when the user clicks the "Play Voice Note" button.
    var voiceNoteToPlay: AVAudioPlayer?
    
    /// This is the name of the .crd file of the path to load, which is assigned by SceneDelegate
    var routeID: String = ""
  
    /// This is the identifier of the App Clip Code, which specifies the path to load and is assigned by SceneDelegate
    var appClipCodeID: String = ""
    
    /// This is the list of routes associated with a specific app clip code
    var availableRoutes: RouteListObject = RouteListObject() //[[String: String]]()
    
    /// This is the ARWorldMap of the route being navigated.
    var routeWorldMap: ARWorldMap?
        
    /// Handler for the mainScreen app state
    ///
    /// - Parameter announceArrival: a Boolean that indicates whether the user's arrival should be announced (true means the user has arrived)
    func handleStateTransitionToMainScreen(announceArrival: Bool) {
        hapticTimer?.invalidate()
        do {
            try hapticPlayer?.stop(atTime: 0.0)
                hapticPlayer = nil
        } catch {}
        // cancel the timer that announces tracking errors
        trackingErrorsAnnouncementTimer?.invalidate()
        // if the ARSession is running, pause it to conserve battery
        ARSessionManager.shared.pauseSession()
        // set this to nil to prevent the app from erroneously detecting that we can auto-align to the route
        if #available(iOS 12.0, *) {
            ARSessionManager.shared.initialWorldMap = nil
        }
        showRecordPathButton(announceArrival: announceArrival)
    }
    
    /// Handler for the recordingRoute app state
    func handleStateTransitionToRecordingRoute() {
        // records a new path
        // updates the state Boolean to signify that the program is no longer saving the first anchor point
        startAnchorPoint = false
        attemptingRelocalization = false
        
        // TODO: probably don't need to set this to [], but erring on the side of being conservative
        crumbs = []
        recordingCrumbs = []
        RouteManager.shared.intermediateAnchorPoints = []
        logger.resetPathLog()
        
        #if !APPCLIP
        showStopRecordingButton()
        #endif
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
    func handleStateTransitionToReadyToNavigateOrPause(allowPause: Bool) {
        #if !APPCLIP
            nameCodeIDController!.dismiss(animated: false)
        #endif
        droppingCrumbs?.invalidate()
        updateHeadingOffsetTimer?.invalidate()
        showStartNavigationButton(allowPause: allowPause, allowNavigation: false)
        suggestAdjustOffsetIfAppropriate()
    }
    
    /// Automatically localizes user with popup to begin navigation
    func handleStateTransitionToAutoAlignment() {
        hideAllViewsHelper()
        print("Aligning")
        
        // TODO: L10N
        let navStart = UIAlertController(title: "Press start to begin navigation", message: "", preferredStyle: .alert)
        
        let start = UIAlertAction(title: "Start", style: .default, handler: {(action) -> Void in    // BL L10N
            self.confirmAlignment()
        })
        
        navStart.addAction(start)
        
//        self.present(navStart, animated: true, completion: nil)
    }
    
    /// Automatically sets up anchor point for route recording
    func handleStateTransitionToAutoAnchoring() {
        print("Aligning to anchor image")
        
        hideAllViewsHelper()
        
        // TODO: L10N
        let recordStart = UIAlertController(title: "Press start to begin recording", message: "", preferredStyle: .alert)
        // TODO: cancel any alignment text being read out
        
        let start = UIAlertAction(title: "Start", style: .default, handler: {(action) -> Void in    // BL L10N
            self.confirmAlignment()
        })
        
        recordStart.addAction(start)
        
        self.present(recordStart, animated: true, completion: nil)
    }
    
    // handler for downloaded routes
    // <3 Esme wrote a function !
    func handleStateTransitionToNavigatingExternalRoute() {
        
        // prevent bear left / bear right when the navigation is starting up
        lastDirectionAnnouncement = Date()
        
        // navigate the recorded path

        // If the route has not yet been saved, we can no longer save this route
        routeName = nil
        beginRouteAnchorPoint = RouteAnchorPoint()
        endRouteAnchorPoint = RouteAnchorPoint()

        logger.resetNavigationLog()
        
        // this is where the code would actually pick up B)
        let pathRef = Storage.storage().reference().child("AppClipRoutes/\(routeID).crd")
        
        // download path from Firebase
        pathRef.getData(maxSize: 100000000000) { data, error in
            if error != nil {
                // Handle any errors
                print("Failed to download route from Firebase due to the following error: \(error)")
            } else {
                do {
                    // TODO: Fix this so that it is a function and works for non-app clips
                    NSKeyedUnarchiver.setClass(RouteDocumentData.self, forClassName: "Clew_More.RouteDocumentData")
                    NSKeyedUnarchiver.setClass(SavedRoute.self, forClassName: "Clew_More.SavedRoute")
                    NSKeyedUnarchiver.setClass(LocationInfo.self, forClassName: "Clew_More.LocationInfo")
                    NSKeyedUnarchiver.setClass(RouteAnchorPoint.self, forClassName: "Clew_More.RouteAnchorPoint")
                    if let document = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data!) as? RouteDocumentData {
                        
                        document.importAudioNotes()
                        
                        let thisRoute = document.route
                        ARSessionManager.shared.initialWorldMap = document.map
                        self.state = .startingResumeProcedure(route: thisRoute, worldMap: ARSessionManager.shared.initialWorldMap, navigateStartToEnd: true)
                    }
                } catch {
                    print("error \(error)")
                }
            }
        }
    }
    
    /// Handler for the navigatingRoute app state
    func handleStateTransitionToNavigatingRoute() {
        // navigate the recorded path
        
        // prevent bear left / bear right when the navigation is starting up
        lastDirectionAnnouncement = Date()

        // If the route has not yet been saved, we can no longer save this route
        routeName = nil
        beginRouteAnchorPoint = RouteAnchorPoint()
        endRouteAnchorPoint = RouteAnchorPoint()

        logger.resetNavigationLog()

        // generate path from PathFinder class
        // enabled hapticFeedback generates more keypoints
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
            ARSessionManager.shared.renderPath(self.prevKeypointPosition, nextKeypoint.location, defaultPathColor: self.defaultPathColor)
        }
        
        // render intermediate anchor points
        ARSessionManager.shared.render(intermediateAnchorPoints: RouteManager.shared.intermediateAnchorPoints)
        
        feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        waypointFeedbackGenerator = UINotificationFeedbackGenerator()
        
        showStopNavigationButton()
        remindedUserOfOffsetAdjustment = false
        playedErrorSoundForOffRoute = false
        remindedUserOfDirectionsButton = false

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
        hapticPlayer = nil
    }
    
    /// Handler for the startingResumeProcedure app state
    ///
    /// - Parameters:
    ///   - route: the route to navigate
    ///   - worldMap: the world map to use
    ///   - navigateStartToEnd: a Boolean that is true if we want to navigate from the start to the end and false if we want to navigate from the end to the start.
    func handleStateTransitionToStartingResumeProcedure(route: SavedRoute, worldMap: ARWorldMap?, navigateStartToEnd: Bool) {
        logger.setCurrentRoute(route: route, worldMap: worldMap)
        
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
            if ARSessionManager.shared.adjustRelocalizationStrategy(worldMap: worldMap, route: route) == .none {
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
            pausedTransform = route.beginRouteAnchorPoint.anchor?.transform
        } else {
            crumbs = route.crumbs
            pausedTransform = route.endRouteAnchorPoint.anchor?.transform
        }
        RouteManager.shared.intermediateAnchorPoints = route.intermediateAnchorPoints
        trackingSessionErrorState = nil
        ARSessionManager.shared.startSession()
        continuationAfterSessionIsReady = {
            // the relocalization strategy may have been adjusted during the session startup
            if ARSessionManager.shared.relocalizationStrategy == .none {
                isSameMap = false
                self.attemptingRelocalization = false
            }
            self.state = .readyForFinalResumeAlignment
            self.showResumeTrackingConfirmButton(route: route, navigateStartToEnd: navigateStartToEnd)
        }
    }
    
    /// Handler for the startingNameCodeIDProcedure app state
    func handleStateTransitionToStartingNameCodeIDProcedure(){
        hideAllViewsHelper()
        add(nameCodeIDController)
    }
    
    /// Handler for the startingNameSavedRouteProcedure app state
    func handleStateTransitionToStartingNameSavedRouteProcedure(worldMap: ARWorldMap?){
        hideAllViewsHelper()
        add(nameSavedRouteController)
    }
    
    /// Handler for the startingPauseProcedure app state
    func handleStateTransitionToStartingPauseProcedure() {
        // clear out these variables in case they had already been created
        if creatingRouteAnchorPoint {
            beginRouteAnchorPoint = RouteAnchorPoint()
            try! showPauseTrackingButton()
        } else {
            endRouteAnchorPoint = RouteAnchorPoint()
            
            // if you can get non-nil worldMap, assign it to vc variable
            ARSessionManager.shared.sceneView.session.getCurrentWorldMap { worldMap, error in   // BL: worldMap exists here
                self.routeWorldMap = worldMap
                self.completingPauseProcedureHelper(worldMap: worldMap)
            }
        }
    }
    
    /// Handler for the pauseWaitingPeriod app state
    func handleStateTransitionToPauseWaitingPeriod() {
        hideAllViewsHelper()
        ///sets the length of the timer to be equal to what the person has in their settings
        ViewController.alignmentWaitingPeriod = timerLength
        rootContainerView.countdownTimer.isHidden = false
        rootContainerView.countdownTimer.start(beginingValue: ViewController.alignmentWaitingPeriod, interval: 1)
        delayTransition()
        playAlignmentConfirmation = DispatchWorkItem{
            self.rootContainerView.countdownTimer.isHidden = true
            self.pauseTracking()
            if self.paused && self.recordingSingleUseRoute{
                ///announce to the user that they have successfully saved an anchor point.
                self.delayTransition(announcement: NSLocalizedString("singleUseRouteAnchorPointToPausedStateAnnouncement", comment: "This is the announcement which is spoken after creating an anchor point in the process of pausing the tracking session of recording a single use route"), initialFocus: nil)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(ViewController.alignmentWaitingPeriod), execute: playAlignmentConfirmation!)
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
    
    /// Handler for the completingPauseProcedure app state
    func handleStateTransitionToCompletingPauseProcedure() {
        // TODO: we should not be able to create a route Anchor Point if we are in the relocalizing state... (might want to handle this when the user stops navigation on a route they loaded.... This would obviate the need to handle this in the recordPath code as well
        print("completing pause procedure")
        
        if imageAnchoring {
            if creatingRouteAnchorPoint {
                guard let currentTransform = ARSessionManager.shared.currentFrame?.anchors.compactMap({$0 as? ARImageAnchor}).first?.transform else {
                    print("can't properly save Anchor Point: TODO communicate this to the user somehow")
                    return
                }
                beginRouteAnchorPoint.anchor = ARAnchor(transform: currentTransform)
                pauseTrackingController.remove()
                
                ///PATHPOINT begining anchor point alignment timer -> record route
                ///announce to the user that they have sucessfully saved an anchor point.
                delayTransition(announcement: NSLocalizedString("multipleUseRouteAnchorPointToRecordingRouteAnnouncement", comment: "This is the announcement which is spoken after the first anchor point of a multiple use route is saved. this signifies the completeion of the saving an anchor point procedure and the start of recording a route to be saved."), initialFocus: nil)
                ///sends the user to a route recording of the program is creating a beginning route Anchor Point
                state = .recordingRoute
                return
            } else if let currentTransform = ARSessionManager.shared.currentFrame?.anchors.compactMap({$0 as? ARImageAnchor}).last?.transform {
                print("^^ image anchoring")
                endRouteAnchorPoint.anchor = ARAnchor(transform: currentTransform)
                // no more crumbs
                droppingCrumbs?.invalidate()

                ARSessionManager.shared.sceneView.session.getCurrentWorldMap { worldMap, error in
                    self.completingPauseProcedureHelper(worldMap: worldMap)
                }
            }
        } else {
            if creatingRouteAnchorPoint {
                guard let currentTransform = ARSessionManager.shared.currentFrame?.camera.transform else {
                    print("can't properly save Anchor Point: TODO communicate this to the user somehow")
                    return
                }
                // make sure we log the transform
                let _ = self.getRealCoordinates(record: true)
                beginRouteAnchorPoint.anchor = ARAnchor(transform: currentTransform)
                pauseTrackingController.remove()
                
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
                // no more crumbs
                droppingCrumbs?.invalidate()

                ARSessionManager.shared.sceneView.session.getCurrentWorldMap { worldMap, error in
                    self.completingPauseProcedureHelper(worldMap: worldMap)
                }
            }
        }
    }
    
    func completingPauseProcedureHelper(worldMap: ARWorldMap?) {
        //check whether or not the path was called from the pause menu or not
        if paused {
            ///PATHPOINT pause recording anchor point alignment timer -> resume tracking
            ///proceed as normal with the pause structure (single use route)
            justTraveledRoute = SavedRoute(id: "single use", appClipCodeID: self.appClipCodeID, name: "single use", crumbs: self.crumbs, dateCreated: Date() as NSDate, beginRouteAnchorPoint: self.beginRouteAnchorPoint, endRouteAnchorPoint: self.endRouteAnchorPoint, intermediateAnchorPoints: RouteManager.shared.intermediateAnchorPoints, imageAnchoring: imageAnchoring)
            justUsedMap = worldMap
            showResumeTrackingButton()
            state = .pauseProcedureCompleted
        } else {
            ///PATHPOINT end anchor point alignment timer -> Save Route View
            delayTransition(announcement: NSLocalizedString("multipleUseRouteAnchorPointToSaveARouteAnnouncement", comment: "This is an announcement which is spoken when the user saves the end anchor point for a multiple use route. This signifies the transition from saving an anchor point to the screen where the user can name and save their route"), initialFocus: nil)
            ///sends the user to the screen where they name the route they're saving
            state = .startingNameSavedRouteProcedure(worldMap: worldMap)
        }
    }
    
    /// Called when the user presses the routes button.  The function will display the `Routes` view, which is managed by `RoutesViewController`.
    @objc func routesButtonPressed() {
        ///update state booleans
        paused = false
        isAutomaticAlignment = false
        recordingSingleUseRoute = false
        
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
    
    @objc func manageRoutesButtonPressed(){
        paused = false
        isAutomaticAlignment = false
        recordingSingleUseRoute = false
        self.hideAllViewsHelper()
        #if !APPCLIP
        self.rootContainerView.homeButton.isHidden = false
        #endif
        self.add(self.manageRoutesController)
        print("works")
    }
    
    @objc func saveCodeIDButtonPressed() {
        hideAllViewsHelper()
        ///Announce to the user that they have saved the route ID and are now at the saving route name screen
        // get session ready
        ARSessionManager.shared.startSession()
        self.delayTransition(announcement: NSLocalizedString("saveCodeIDtoCreatingAnchorPointAnnouncement", comment: "This is an announcement which is spoken when the user finishes saving their route's app clip code ID. This announcement signifies the transition from the view where the user can enter the app clip code ID associated with the route to the view where the user can anchor the starting point of the route they are recording."), initialFocus: nil)
        /// send to pause procedure
        self.state = .startingPauseProcedure
    }
    
    @objc func saveRouteButtonPressed(worldMap: ARWorldMap?) {
        let id = String(Int64(NSDate().timeIntervalSince1970 * 1000)) as NSString
        // BL
        try! self.archive(routeId: id, appClipCodeID: self.appClipCodeID, beginRouteAnchorPoint: self.beginRouteAnchorPoint, endRouteAnchorPoint: self.endRouteAnchorPoint, intermediateAnchorPoints: RouteManager.shared.intermediateAnchorPoints, worldMap: self.routeWorldMap, imageAnchoring: self.imageAnchoring)
        hideAllViewsHelper()
        /// PATHPOINT Save Route View -> play/pause
        ///Announce to the user that they have finished the alignment process and are now at the play pause screen
        self.delayTransition(announcement: NSLocalizedString("saveRouteToPlayPauseAnnouncement", comment: "This is an announcement which is spoken when the user finishes saving their route. This announcement signifies the transition from the view where the user can name or save their route to the screen where the user can either pause the AR session tracking or they can perform return navigation."), initialFocus: nil)
    }
    
    /// Hide all the subviews.  TODO: This should probably eventually refactored so it happens more automatically.
    func hideAllViewsHelper() {
        recordPathController.remove()
        stopRecordingController.remove()
        startNavigationController.remove()
        stopNavigationController.remove()
        pauseTrackingController.remove()
        resumeTrackingConfirmController.remove()
        resumeTrackingController.remove()
        nameSavedRouteController?.remove()
        nameCodeIDController?.remove()
        scanTagController?.remove()
        #if CLEWMORE
        selectRouteController.remove()
        enterCodeIDController.remove()
        manageRoutesController.remove()
        routeOptionsController?.dismiss(animated: false)
        endNavigationController?.remove()
        #endif
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
    ///   - appClipCodeID: the ID of the app clip code associated with the start point of the route
    ///   - beginRouteAnchorPoint: the route Anchor Point for the beginning (if there is no route Anchor Point at the beginning, the elements of this struct can be nil)
    ///   - endRouteAnchorPoint: the route Anchor Point for the end (if there is no route Anchor Point at the end, the elements of this struct can be nil)
    ///   - worldMap: the world map
    /// - Throws: an error if something goes wrong

    func archive(routeId: NSString, appClipCodeID: String, beginRouteAnchorPoint: RouteAnchorPoint, endRouteAnchorPoint: RouteAnchorPoint, intermediateAnchorPoints: [RouteAnchorPoint], worldMap: ARWorldMap?, imageAnchoring: Bool) throws {
        let savedRoute = SavedRoute(id: routeId, appClipCodeID: self.appClipCodeID, name: routeName!, crumbs: crumbs, dateCreated: Date() as NSDate, beginRouteAnchorPoint: beginRouteAnchorPoint, endRouteAnchorPoint: endRouteAnchorPoint, intermediateAnchorPoints: intermediateAnchorPoints, imageAnchoring: imageAnchoring)

      try dataPersistence.archive(route: savedRoute, worldMap: worldMap)
        justTraveledRoute = savedRoute
    }

    /// Session for scanning NFC Tags
    var nfcSession: NFCNDEFReaderSession?
    
    var nfcEntryPoint: String = ""

    
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
    
    /// Keypoint object
    var keypointObject : MDLObject!
    
    /// Speaker object
    var speakerObject: MDLObject!
    
    /// Route persistence
    var dataPersistence = DataPersistence()
    
    // MARK: - Parameters that can be controlled remotely via Firebase
    
    /// True if the offset between direction of travel and phone should be updated over time
    var adjustOffset: Bool!
    
    /// True if the user has been reminded that the adjusts offset feature is turned on
    var remindedUserOfOffsetAdjustment = false
    
    /// True if we should use a cone of pi/12 and false if we should use a cone of pi/6 when deciding whether to issue haptic feedback
    var strictHaptic = true
    
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
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String(newValue))
    }
    
    /// Hook in the view class as a view, so that we can access its variables easily
    var rootContainerView: RootContainerView {
        return view as! RootContainerView
    }
    
    /// child view controllers for various app states
    
    /// the controller that hosts the popover survey
    var hostingController: UIViewController?
    
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
    
    /// scan tag controller
    var scanTagController: UIViewController?
    
    // SwiftUI controllers
    var enterCodeIDController: UIViewController!
    
    var selectRouteController: UIViewController!
    
    var manageRoutesController: UIViewController!
    
    var routeOptionsController: UIViewController?
    
    /// saving route code ID VC
    var nameCodeIDController: UIViewController!
    
    /// saving route name VC
    var nameSavedRouteController: UIViewController!
    
    var endNavigationController: UIViewController?
    
    /// start route navigation VC
    var startNavigationController: StartNavigationController!
    
    /// work item for playing alignment confirmation sound
    var playAlignmentConfirmation: DispatchWorkItem?
    
    /// stop route navigation VC
    var stopNavigationController: StopNavigationController!
    
    /// keep track of when the last off course announcement was given
    var lastOffCourseAnnouncement: Date? = Date()
    
    /// last direction announcement
    var lastDirectionAnnouncement = Date()

    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set the main view as active
        view = RootContainerView(frame: UIScreen.main.bounds)
        
        // initialize child view controllers
        pauseTrackingController = PauseTrackingController()
        resumeTrackingController = ResumeTrackingController()
        resumeTrackingConfirmController = ResumeTrackingConfirmController()
        stopRecordingController = StopRecordingController()
        recordPathController = RecordPathController()
      
        startNavigationController = StartNavigationController()
        stopNavigationController = StopNavigationController()
        
        #if CLEWMORE
        /// This is a wrapper to allow SwiftUI views to be used with the existing UIKit framework.
        enterCodeIDController = UIHostingController(rootView: EnterCodeIDView(vc: self))
        enterCodeIDController.view.frame = CGRect(x: 0,
                                                                       y: UIScreen.main.bounds.size.height*0.15,
                                                                       width: UIConstants.buttonFrameWidth * 1,
                                                                       height: UIScreen.main.bounds.size.height*0.75)
        enterCodeIDController.view.backgroundColor = .clear
        
        selectRouteController = UIHostingController(rootView: StartNavigationPopoverView(vc: self, routeList: self.availableRoutes))
        selectRouteController.view.frame = CGRect(x: 0,
                                                                       y: UIScreen.main.bounds.size.height*0.15,
                                                                       width: UIConstants.buttonFrameWidth * 1,
                                                                       height: UIScreen.main.bounds.size.height*0.75)
        
        selectRouteController.view.backgroundColor = .white
        
        manageRoutesController = UIHostingController(rootView: SavedRoutesList(vc: self))
        manageRoutesController.view.frame = CGRect(x: 0,
                                                                       y: UIScreen.main.bounds.size.height*0.15,
                                                                       width: UIConstants.buttonFrameWidth * 1,
                                                                       height: UIScreen.main.bounds.size.height*0.85)
        manageRoutesController.view.backgroundColor = .white
        
        nameSavedRouteController = UIHostingController(rootView: NameSavedRouteView(vc: self))
        nameSavedRouteController.view.frame = CGRect(x: 0,
                                                                       y: UIScreen.main.bounds.size.height*0.15,
                                                                       width: UIConstants.buttonFrameWidth * 1,
                                                                       height: UIScreen.main.bounds.size.height*0.85)
        nameSavedRouteController.view.backgroundColor = .clear
        
        nameCodeIDController = UIHostingController(rootView: NameCodeIDView(vc: self))
        nameCodeIDController.view.frame = CGRect(x: 0,
                                                                       y: UIScreen.main.bounds.size.height*0.15,
                                                                       width: UIConstants.buttonFrameWidth * 1,
                                                                       height: UIScreen.main.bounds.size.height*0.85)
        nameCodeIDController.view.backgroundColor = .clear
        
        
        endNavigationController = UIHostingController(rootView: EndNavigationScreen(vc: self))
        endNavigationController?.view.frame = CGRect(x: 0,
                                                                       y: UIScreen.main.bounds.size.height*0.15,
                                                                       width: UIConstants.buttonFrameWidth * 1,
                                                                       height: UIScreen.main.bounds.size.height*0.85)
        endNavigationController?.view.backgroundColor = .white
        
        #endif
        ARSessionManager.shared.delegate = self
        
        // Add the scene to the view, which is a RootContainerView
        ARSessionManager.shared.sceneView.frame = view.frame
        view.addSubview(ARSessionManager.shared.sceneView)
        
        createAppClipObservers()
        setupAudioPlayers()
        loadAssets()
        createSettingsBundle()
        
        // TODO: we might want to make this wait on the AR session starting up, but since it happens pretty fast it's likely not a big deal
        state = .mainScreen(announceArrival: false)
        view.sendSubviewToBack(ARSessionManager.shared.sceneView)

        //rootContainerView.swiftUIPlaceHolder = UIHostingController(rootView: DefaultView())

        // view.bringSubviewToFront(rootContainerView.swiftUIPlaceHolder.view)
        
        // rootContainerView.swiftUIPlaceHolder.view.isHidden = false
        
        print("its in the front now")
        // targets for global buttons
        ///// TRACK
        #if !APPCLIP
        rootContainerView.burgerMenuButton.addTarget(self, action: #selector(burgerMenuButtonPressed), for: .touchUpInside)
        
        // need to modify this for clewmore
        rootContainerView.homeButton.addTarget(self, action: #selector(homeButtonPressed), for: .touchUpInside)
        
        #endif
        
        rootContainerView.getDirectionButton.addTarget(self, action: #selector(announceDirectionHelpPressed), for: .touchUpInside)

        // make sure this happens after the view is created!
        rootContainerView.countdownTimer.delegate = self
        ///sets the length of the timer to be equal to what the person has in their settings
        ///
        ///
        ViewController.alignmentWaitingPeriod = timerLength
        AnnouncementManager.shared.announcementText = rootContainerView.announcementText

        addGestures()
        firebaseSetup.setupFirebaseObservers(vc: self)
        
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
            if self.stopRecordingController.parent == self {
                /// set  record voice note as active
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.stopRecordingController.recordVoiceNoteButton)
            }
        }

        // we use a custom notification to communicate from the help controller to the main view controller that a popover that should suppress tracking warnings was displayed
        NotificationCenter.default.addObserver(forName: Notification.Name("ClewPopoverDisplayed"), object: nil, queue: nil) { (notification) -> Void in
            self.suppressTrackingWarnings = true
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("SurveyPopoverReadyToDismiss"), object: nil, queue: nil) { (notification) -> Void in
            self.hostingController?.dismiss(animated: true)
            NotificationCenter.default.post(name: Notification.Name("ClewPopoverDismissed"), object: nil)
            // TODO: I18N / L10N
            if let gaveFeedback = notification.object as? Bool, gaveFeedback {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    AnnouncementManager.shared.announce(announcement: NSLocalizedString("thanksForFeedbackAnnouncement", comment: "This is read right after the user fills out a feedback survey."))
                }
            }
        }
        #if !APPCLIP
        arLogger.enabled = logRichData
        arLogger.startTrial()
        #endif

    }
    
    func startEndOfRouteHaptics() {
        do {
            hapticEngine = try CHHapticEngine()
            hapticEngine?.start() { error in
                if error != nil {
                    print("error \(error?.localizedDescription)")
                    return
                }
                let events = [CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1),
                    CHHapticEventParameter(parameterID: .attackTime, value: 0.1),
                    CHHapticEventParameter(parameterID: .releaseTime, value: 0.2),
                    CHHapticEventParameter(parameterID: .decayTime, value: 0.3) ], relativeTime: 0.1, duration: 0.6)]
                
                do {
                    self.hapticPlayer = try self.hapticEngine?.makeAdvancedPlayer(with: CHHapticPattern(events: events, parameters: []))
                    self.hapticPlayer?.loopEnabled = true
                    try self.hapticPlayer?.start(atTime: 0)
                    print("Started Haptics!!")
                } catch {
                    print("HAPTICS ERROR!!!")
                    
                }
            }
        } catch {
            print("Unable to start haptic engine")
        }
    }
    
    /// Create the audio player objects for the various app sounds.  Creating them ahead of time helps reduce latency when playing them later.
    func setupAudioPlayers() {
        let anchorInFrameSound = Bundle.main.path(forResource: "anchorInFrame", ofType: "mp3")
        
        do {
            audioPlayers[1103] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/Tink.caf"))
            audioPlayers[1016] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/tweet_sent.caf"))
            audioPlayers[1050] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/ussd.caf"))
            audioPlayers[1025] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/New/Fanfare.caf"))
            audioPlayers[1234] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: anchorInFrameSound!))

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
        let speakerUrl = NSURL(fileURLWithPath: Bundle.main.path(forResource: "speaker", ofType: "obj")!)
        let speakerAsset = MDLAsset(url: speakerUrl as URL)
        speakerObject = speakerAsset.object(at: 0)
    }
    
    
    /// Called when the view appears on screen.
    ///
    /// - Parameter animated: True if the appearance is animated
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let userDefaults: UserDefaults = UserDefaults.standard
        let firstTimeLoggingIn: Bool? = userDefaults.object(forKey: "firstTimeLogin") as? Bool
        let showedSignificantChangesAlert: Bool? = userDefaults.object(forKey: "showedSignificantChangesAlertv1_3") as? Bool
        
        #if !APPCLIP
        if firstTimeLoggingIn == nil {
            userDefaults.set(Date().timeIntervalSince1970, forKey: "firstUsageTimeStamp")
            userDefaults.set(true, forKey: "firstTimeLogin")
            // make sure not to show the significant changes alert in the future
            userDefaults.set(true, forKey: "showedSignificantChangesAlertv1_3")
            #if !APPCLIP
            showLogAlert()
            #endif
        } else if showedSignificantChangesAlert == nil {
            // we only show the significant changes alert if this is an old installation
            userDefaults.set(true, forKey: "showedSignificantChangesAlertv1_3")
            // don't show this for now, but leave the plumbing in place for a future significant change
            // showSignificantChangesAlert()
        }
        #endif
        
        synth.delegate = self
        NotificationCenter.default.addObserver(forName: UIAccessibility.announcementDidFinishNotification, object: nil, queue: nil) { (notification) -> Void in
            self.currentAnnouncement = nil
            if let nextAnnouncement = self.nextAnnouncement {
                self.nextAnnouncement = nil
                AnnouncementManager.shared.announce(announcement: nextAnnouncement)
            }
        }
        
        let firstUsageTimeStamp =  userDefaults.object(forKey: "firstUsageTimeStamp") as? Double ?? 0.0
        if Date().timeIntervalSince1970 - firstUsageTimeStamp > 3600*24 {
            // it's been long enough, try to trigger the survey
            #if !CLEWMORE
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                // make sure to wait for data to load from firebase.  If they have started using the app, don't interrupt them.
                if case .mainScreen(_) = self.state {
                    self.surveyInterface.presentSurveyIfIntervalHasPassed(mode: "onAppLaunch", logFileURLs: [], vc: self)
                }
            }
            #endif
        }
    }
    
    /// Display a warning that tells the user they must create a Anchor Point to be able to use this route again in the forward direction
    func showRecordPathWithoutAnchorPointWarning() {
        state = .recordingRoute
    }
    
    /// func that prepares the state transition to home by clearing active processes and data
    func clearState() {
        // TODO: check for code reuse
        // Clearing All State Processes and Data
        #if !APPCLIP
        rootContainerView.homeButton.isHidden = true
        #endif
        ARSessionManager.shared.pauseSession()
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
        playAlignmentConfirmation?.cancel()
        rootContainerView.announcementText.isHidden = true
        nav.headingOffset = 0.0
        headingRingBuffer.clear()
        locationRingBuffer.clear()
        logger.resetNavigationLog()
        logger.resetPathLog()
        hapticTimer?.invalidate()
        do {
            try hapticPlayer?.stop(atTime: 0.0)
        } catch {}
        hapticPlayer = nil
        logger.resetStateSequenceLog()
    }
    
    func uploadLocalDataToCloudHelper() {
        #if !APPCLIP
        guard arLogger.hasLocalDataToUploadToCloud(), arLogger.isConnectedToNetwork(), uploadRichData == true else {
            return
        }
        let popoverController = UIHostingController(rootView: UploadingViewNoBinding())
        popoverController.modalPresentationStyle = .fullScreen
        self.present(popoverController, animated: true)
        self.arLogger.uploadLocalDataToCloud() { wasSuccessful in
            DispatchQueue.main.async {
                popoverController.dismiss(animated: true)
            }
        }
        #endif
    }
    
    /// This finishes the process of pressing the home button (after user has given confirmation)
    @objc func goHome() {
        // proceed to home page
        self.clearState()
        self.hideAllViewsHelper()
        #if !APPCLIP
        self.arLogger.finalizeTrial()
        uploadLocalDataToCloudHelper()
        #endif
        self.state = .mainScreen(announceArrival: false)
    }
    
    func askToInitializeNFCTag(tag: NFCNDEFTag, errorMessage: String) {
        if shouldRegister {
            let uuidCode = UUID().uuidString
            guard let url = URL(string: "https://berwinl.com/id?p=\(uuidCode)"), let payload = NFCNDEFPayload
                    .wellKnownTypeURIPayload(url: url)
              else {
                print("Could not create payload")
                return
            }
            let message = NFCNDEFMessage(records: [payload])

            tag.writeNDEF(message) { error in
                if error == nil {
                    self.nfcSession?.invalidate()
                    self.handleNFCURL(url)
                    DispatchQueue.main.async {
                        self.saveCodeIDButtonPressed()
                    }
                } else {
                    self.nfcSession?.invalidate(errorMessage: error!.localizedDescription)
                }
            }
        } else {
            nfcSession?.invalidate(errorMessage: errorMessage)
            let alert = UIAlertController(title: "Register NFC Tag as Place Identifier",
                                          message: "This NFC tag is not registered with Clew Maps.  Would you like to register the tag with Clew Maps the next time you scan it?",
                                          preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Register NFC Tag on Next Scan", style: .default, handler: { action -> Void in
                self.shouldRegister = true
            }
            ))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action -> Void in
                self.NFCEntrySwitch(entryPoint: self.nfcEntryPoint)
            }
            ))
            present(alert, animated: true, completion: nil)
        }
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
        print("alert presented")
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
        #if !APPCLIP
        rootContainerView.homeButton.isHidden = false
        #endif
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
    #if !APPCLIP
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
    #endif
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
        let appDefaults = ["crumbColor": 0, "showPath": true, "pathColor": 0, "hapticFeedback": true, "sendLogs": true, "voiceFeedback": true, "soundFeedback": true, "adjustOffset": false, "units": 0, "timerLength":5, "uploadRichData": false] as [String : Any]
        UserDefaults.standard.register(defaults: appDefaults)
    }

    /// Respond to update events to the `UserDefaults` object (the settings of the app).
    func updateDisplayFromDefaults(){
        let defaults = UserDefaults.standard
        
        defaultUnit = defaults.integer(forKey: "units")
        uploadRichData = defaults.bool(forKey: "uploadRichData")
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
        logRichData = defaults.bool(forKey: "logRichData")
        
        // TODO: log settings here
        logger.logSettings(defaultUnit: defaultUnit, defaultColor: defaultColor, soundFeedback: soundFeedback, voiceFeedback: AnnouncementManager.shared.voiceFeedback, hapticFeedback: hapticFeedback, sendLogs: sendLogs, timerLength: timerLength, adjustOffset: adjustOffset)
        
        // leads to JSON like:
        //   options: { "unit": "meter", "soundFeedback", true, ... }
    }
    
    /// Handles updates to the app settings.
    @objc func defaultsChanged(){
        updateDisplayFromDefaults()
    }
    
    @IBAction func beginScanning(_ sender: Any) {
        if type(of: sender) == ScanButton.self {
            self.nfcEntryPoint = "EnterCode"
        }
        if type(of: sender) == ScanNFCButton.self {
            self.nfcEntryPoint = "NameCode"
        }
        print(sender)
        print("hee")
        guard NFCNDEFReaderSession.readingAvailable else {
            print("Device Won't Support NFC Scanning")
            self.add(self.enterCodeIDController)
            return
        }
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        nfcSession?.begin()
    }
    
    // MARK: - NFCNDEFReaderSessionDelegate

    /// - Tag: processingTagData
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        DispatchQueue.main.async {
            // Process detected NFCNDEFMessage objects.
            print(messages)
            print("NFC detected")
        }
    }

    /// - Tag: processingNDEFTag
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            // Restart polling in 500ms
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "More than 1 tag is detected, please remove all tags and try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
        
        // Connect to the found tag and perform NDEF message reading
        let tag = tags.first!
        session.connect(to: tag, completionHandler: { (error: Error?) in
            if nil != error {
                session.alertMessage = "Unable to connect to tag."
                session.invalidate()
                self.NFCEntrySwitch(entryPoint: self.nfcEntryPoint)
                return
            }
            
            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                if .notSupported == ndefStatus {
                    session.alertMessage = "Tag is not NDEF compliant"
                    session.invalidate()
                    self.NFCEntrySwitch(entryPoint: self.nfcEntryPoint)

                    return
                } else if nil != error {
                    session.alertMessage = "Unable to query NDEF status of tag"
                    session.invalidate()
                    self.NFCEntrySwitch(entryPoint: self.nfcEntryPoint)

                    return
                }
                tag.readNDEF(completionHandler: { (message: NFCNDEFMessage?, error: Error?) in
                    var statusMessage: String
                    if nil != error || nil == message {
                        statusMessage = "Fail to read NDEF from tag"
                        DispatchQueue.main.async {
                            if case .startingNameCodeIDProcedure = self.state {
                                self.askToInitializeNFCTag(tag: tag, errorMessage: statusMessage)
                            } else {
                                session.invalidate(errorMessage: statusMessage)
                            }
                        }
                    } else {
                        statusMessage = "Successfully Read NFC Tag"
                        DispatchQueue.main.async {
                            // Process detected NFCNDEFMessage objects.
                            //print(message)
                            print("data type: \(message!.records[0].typeNameFormat)")
                            
                            let payload = message!.records[0]
                            
                            if payload.typeNameFormat == .nfcWellKnown {
                                let url = payload.wellKnownTypeURIPayload()
                                print(url)
                                print("test")
                                if let url = url {
                                    // currently hardcoded :/, should probably change
                                    if url.host == "berwinl.com" && self.handleNFCURL(url) != nil {
                                        statusMessage = "Success!"
                                        session.alertMessage = statusMessage
                                        session.invalidate()
                                        if self.nfcEntryPoint == "EnterCode"{
                                            self.codeIDEntered()
                                        }
                                        if self.nfcEntryPoint == "NameCode" {
                                            self.saveCodeIDButtonPressed()
                                        }

                                    } else {
                                        statusMessage = "Not a Recognized Clew Route Database"
                                        if case .startingNameCodeIDProcedure = self.state {
                                            self.askToInitializeNFCTag(tag: tag, errorMessage: statusMessage)
                                        } else {
                                            session.invalidate(errorMessage: statusMessage)
                                        }
                                    }
                                } else {
                                    statusMessage = "No URL Data Read"
                                    if case .startingNameCodeIDProcedure = self.state {
                                        self.askToInitializeNFCTag(tag: tag, errorMessage: statusMessage)
                                    } else {
                                        session.invalidate(errorMessage: statusMessage)
                                    }
                                    print("No URL data stored")
                                }
                                
                            } else {
                                statusMessage = "Data could not be recognized"
                                if case .startingNameCodeIDProcedure = self.state {
                                    self.askToInitializeNFCTag(tag: tag, errorMessage: statusMessage)
                                } else {
                                    session.invalidate(errorMessage: statusMessage)
                                }
                                print("NFC data not recognized")
                            }
                        }
                        print("success!")
                    }
                })
            })
        })
    }
    
    func handleNFCURL(_ url: URL)->String? {
        self.appClipCodeID = ""
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true), let queryItems = components.queryItems else {
          return nil
        }
        /// with the invocation URL format https://occamlab.github.io/id?p=appClipCodeID, appClipCodeID being the name of the file in Firebase
        if let appClipCodeID = queryItems.first(where: { $0.name == "p"}) {
            self.appClipCodeID = appClipCodeID.value!
            print("app clip code ID from URL: \(appClipCodeID.value!)")
            return self.appClipCodeID
        }
        return nil
    }
    
    func NFCEntrySwitch(entryPoint: String) {
        switch self.nfcEntryPoint {
        case "EnterCode":
            self.add(self.enterCodeIDController)
        case "NameCode":
            self.add(self.nameCodeIDController)
        default:
            print("huh, weird")
        }
    }
    
    /// - Tag: sessionBecomeActive
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        
    }
    
    /// - Tag: endScanning
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Check the invalidation reason from the returned error.
        if let readerError = error as? NFCReaderError {
            // Show an alert when the invalidation reason is not because of a
            // successful read during a single-tag read session, or because the
            // user canceled a multiple-tag read session from the UI or
            // programmatically using the invalidate method call.
            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                let alertController = UIAlertController(
                    title: "Session Invalidated",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }

        // To read new tags, a new session instance is required.
        self.nfcSession = nil
    }
    
    
    /// Handle the user clicking the confirm alignment to a saved Anchor Point.  Depending on the app state, the behavior of this function will differ (e.g., if the route is being resumed versus reloaded)
    @objc func confirmAlignment() {
        print("confirm alignment function open")
        print("this is food this is beans")
        if case .startingPauseProcedure = state {
            state = .pauseWaitingPeriod
        } else if case .startingResumeProcedure = state {
            resumeTracking()
        } else if case .readyForFinalResumeAlignment = state {
            resumeTracking()
        } else if case .startingAutoAlignment = state {
            /// for navigating a saved route
            hideAllViewsHelper()
            resumeTracking()
        } else if case .startingAutoAnchoring = state {
            /// for recording a saved route
            hideAllViewsHelper()
            
            state = .completingPauseProcedure
        }
        print("alignment confirmed")
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
        #if CLEWMORE
        add(recordPathController)
        #endif
        /// handling main screen transitions outside of the first load
        /// add the view of the child to the view of the parent
        stopNavigationController.remove()
        
        rootContainerView.getDirectionButton.isHidden = true
        // the options button is hidden if the route rating shows up
        ///// TRACK
        #if !APPCLIP
        rootContainerView.homeButton.isHidden = true
        #endif

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
        print("notification posted")
        print(UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: initialFocus))
        print("That was the notification")
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
    
    func alignmentTransition() {
        AnnouncementManager.shared.announce(announcement: NSLocalizedString("resumeAnchorPointToReturnNavigationAnnouncement", comment: "This is an Announcement which indicates that the pause session is complete, that the program was able to align with the anchor point, and that return navigation has started."))
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { timer in
                // check the state in case it has changed in the interim (e.g., a user clicked the home button)
                switch (self.state) {
                case .startingAutoAlignment:
                    self.state = .navigatingRoute
                case .readyForFinalResumeAlignment:
                    self.state = .navigatingRoute
                default:
                    // do nothing since we probably hit the home button in the interim
                    break
                }
            }

    }
    
    /// Display stop recording view/hide all other views
    @objc func showStopRecordingButton() {
        #if !APPCLIP
        rootContainerView.homeButton.isHidden = false // home button here
        #endif
        recordPathController.remove()
        recordPathController.view.isAccessibilityElement = false
        add(stopRecordingController)
        delayTransition(announcement: NSLocalizedString("properDevicePositioningAnnouncement", comment: "This is an announcement which plays to tell the user the best practices for aligning the phone"))
    }
    
    /// Display start navigation view/hide all other views
    @objc func showStartNavigationButton(allowPause: Bool, allowNavigation: Bool) {
        #if !APPCLIP
        rootContainerView.homeButton.isHidden = !recordingSingleUseRoute // home button hidden if we are doing a multi use route (we use the large home button instead)
        #endif
        resumeTrackingController.remove()
        resumeTrackingConfirmController.remove()
        stopRecordingController.remove()
        
        // set appropriate Boolean flags for context
        startNavigationController.isAutomaticAlignment = isAutomaticAlignment
        startNavigationController.recordingSingleUseRoute = recordingSingleUseRoute
        add(startNavigationController)
        startNavigationController.startNavigationButton.isHidden = !allowNavigation
        startNavigationController.pauseButton.isHidden = !allowPause
        startNavigationController.largeHomeButton.isHidden = recordingSingleUseRoute
        startNavigationController.stackView.layoutIfNeeded()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: startNavigationController.startNavigationButton)
    }

    /// Display the pause tracking view/hide all other views
    func showPauseTrackingButton() throws {
        #if !APPCLIP
        rootContainerView.homeButton.isHidden = false
        #endif
        
        #if CLEWMORE
        rootContainerView.homeButton.isHidden = false
        #endif
        
        recordPathController.remove()
        startNavigationController.remove()

        // set appropriate Boolean flags
        pauseTrackingController.paused = paused
        pauseTrackingController.recordingSingleUseRoute = recordingSingleUseRoute
        pauseTrackingController.startAnchorPoint = startAnchorPoint
        pauseTrackingController.imageAnchoring = imageAnchoring
        
        add(pauseTrackingController)
        delayTransition()
    }
    
    /// Display the resume tracking view/hide all other views
    @objc func showResumeTrackingButton() {
        #if !APPCLIP
        rootContainerView.homeButton.isHidden = false // no home button here,, unhomes your button :(
        #endif
        pauseTrackingController.remove()
        add(resumeTrackingController)
        UIApplication.shared.keyWindow!.bringSubviewToFront(rootContainerView)
        delayTransition()    }
    
    /// Display the resume tracking confirm view/hide all other views.
    func showResumeTrackingConfirmButton(route: SavedRoute, navigateStartToEnd: Bool) {
        #if !APPCLIP
        rootContainerView.homeButton.isHidden = false
        #endif
        self.hideAllViewsHelper()
        resumeTrackingController.remove()
        resumeTrackingConfirmController.imageAnchoring = route.imageAnchoring
        // I THINK that's the image anchoring that we want
        add(resumeTrackingConfirmController)
        resumeTrackingConfirmController.view.mainText?.text = ""
        voiceNoteToPlay = nil
        if navigateStartToEnd {
            if let AnchorPointInformation = route.beginRouteAnchorPoint.information as String? {
                let infoString = "\n\n" + NSLocalizedString("anchorPointIntroductionToSavedText", comment: "This is the text which delineates the text that a user saved witht their saved anchor point. This text is shown when a user loads an anchor point and the text that the user saved with their anchor point appears right after this string.") + AnchorPointInformation + "\n\n"
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
                let infoString = "\n\n" + NSLocalizedString("anchorPointIntroductionToSavedText", comment: "This is the text which delineates the text that a user saved with their saved anchor point. This text is shown when a user loads an anchor point and the text that the user saved with their anchor point appears right after this string.") + AnchorPointInformation + "\n\n"
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
        if route.imageAnchoring {
            print("yes good wrked correctly")
            resumeTrackingConfirmController.view.mainText?.text?.append(String.localizedStringWithFormat(NSLocalizedString("imageAnchorPointAlignmentText", comment: "Text describing the process of aligning to an image anchorpoint. This text shows up on the alignment screen."), waitingPeriod))
            
        } else{
            resumeTrackingConfirmController.view.mainText?.text?.append(String.localizedStringWithFormat(NSLocalizedString("anchorPointAlignmentText", comment: "Text describing the process of aligning to an anchorpoint. This text shows up on the alignment screen."), waitingPeriod))
            
        }
        print("State: \(self.state)")
        delayTransition()
    }
    
    func showEndScreenInformation(completedRoute: Bool){
        #if APPCLIP
        self.hideAllViewsHelper()
        //self.sceneView.session.pause()
        
        trackingErrorsAnnouncementTimer?.invalidate()
        
        ARSessionManager.shared.initialWorldMap = nil
        
        self.rootContainerView.getDirectionButton.isHidden = true
        guard let scene = self.view.window?.windowScene else {return}
        
        
        // TODO: i18n/l10n
        if completedRoute{
            delayTransition(announcement: "You have arrived at your destination.")
        } else{
            ARSessionManager.shared.pauseSession()
            delayTransition(announcement: "Route navigation stopped. You may not have arrived at your destination yet.")
        }
        let config = SKOverlay.AppClipConfiguration(position: .bottom)
        let overlay = SKOverlay(configuration: config)
        overlay.present(in: scene)
        #else
        if !completedRoute {
            ARSessionManager.shared.pauseSession()
        }
        self.hideAllViewsHelper()
        self.add(self.endNavigationController!)
        #endif
    }
    
    /// display stop navigation view/hide all other views
    // is this where the timer is set?
    @objc func showStopNavigationButton() {
        #if !APPCLIP
        rootContainerView.homeButton.isHidden = false
        #endif
        rootContainerView.getDirectionButton.isHidden = false
        startNavigationController.remove()
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
    
    // MARK: - BreadCrumbs
    
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
    
    var errorFeedbackTimer = Date()
    var remindedUserOfDirectionsButton = false
    var playedErrorSoundForOffRoute = false
    /// Delay (and interval) before playing the error sound when the user is not facing the next keypoint of the route
    static let delayBeforeErrorSound = 3.0
    /// Delay (and interval) before announcing to the user that they should press the get directions button
    static let delayBeforeErrorAnnouncement = 8.0
    
    static let directionTextGracePeriod = 3.5
    
    static let offTrackCorrectionAnnouncementInterval = 2.0
    
    // MARK: - Settings bundle configuration
    
    /// the bundle configuration has 0 as feet and 1 as meters
    let unit = [0: "ft", 1: "m"]
    
    /// the text to display for each possible unit
    let unitText = [0: NSLocalizedString("imperialUnitText", comment: "this is the text which is displayed in the settings to show the user the option of imperial measurements"), 1: NSLocalizedString("metricUnitText", comment: "this is the text which is displayed in the settings to show the user the option of metric measurements")] as [Int : String]
    
    /// the converstion factor to apply to distances as reported by ARKit so that they are expressed in the user's chosen distance units.  ARKit's unit of distance is meters.
    let unitConversionFactor = [0: Float(100.0/2.54/12.0), 1: Float(1.0)]

    /// the selected default unit index (this index cross-references `unit`, `unitText`, and `unitConversionFactor`
    var defaultUnit: Int!
    
    /// register tag if invalid
    var shouldRegister = false
    
    /// Whether or not to upload the rich data
    var uploadRichData: Bool?
    
    /// the color of the waypoints.  0 is red, 1 is green, 2 is blue, and 3 is random
    var defaultColor: Int!
    
    /// true if path should be shown between waypoints, false otherwise
    var showPath: Bool!
    
    /// true if saved route anchoring happens from images (currently the app only works with this set to true)
    let imageAnchoring = true
    
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
    
    /// This tracks whether the user has consented to log rich (image) data
    var logRichData: Bool!

    /// This keeps track of the paused transform while the current session is being realigned to the saved route
    var pausedTransform : simd_float4x4?
    
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
    
    /// DirectionText based on haptic/voice settings
    var Directions: Dictionary<Int, String> {
        if (hapticFeedback) {
            return HapticDirections
        } else {
            return ClockDirections
        }
    }
    
    /// Announces the any excessive motion or insufficient visual features errors as specified in the last observed tracking state
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
        // clear this flag in case it was set before
        shouldRegister = false

        ///sends the user to create a Anchor Point
        #if !APPCLIP
        rootContainerView.homeButton.isHidden = false
        #endif
        creatingRouteAnchorPoint = true

        hideAllViewsHelper()

        // announce session state
        trackingErrorsAnnouncementTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            self.announceCurrentTrackingErrors()
        }
        self.trackingErrorsAnnouncementTimer?.invalidate()
        // sends the user to the screen where they can enter an app clip code ID for the route they're about to record
        self.state = .startingNameCodeIDProcedure
        ARSessionManager.shared.initialWorldMap = nil
    }
    
    /// handles the user pressing the stop recording button.
    ///
    /// - Parameter sender: the button that generated the event
    @objc func stopRecording(_ sender: UIButton) {
        // copy the recordingCrumbs over for use in path creation
        crumbs = Array(recordingCrumbs)
        isResumedRoute = false

        #if !APPCLIP
        rootContainerView.homeButton.isHidden = false // home button here
        #endif
        resumeTrackingController.remove()
        resumeTrackingConfirmController.remove()
        stopRecordingController.remove()
        setShouldSuggestAdjustOffset()
        // heading offsets should not be updated from this point until route navigation starts
        updateHeadingOffsetTimer?.invalidate()
        recordPhaseHeadingOffsets = []
        
        ///checks if the route is a single use route or a multiple use route
        if !recordingSingleUseRoute {
            ///PATHPOINT two way route recording finished -> create end Anchor Point
            ///sets the variable tracking whether the route is paused to be false
            paused = false
            creatingRouteAnchorPoint = false
            if imageAnchoring {
                /// sends the user to naming the route, skipping creating the end anchorpoint
                state = .startingPauseProcedure
            } else {    /// this probably shouldn't go to startingPauseProcedure but it also currently never gets here
                ///sends the user to the process where they create an end anchorpoint
                state = .startingPauseProcedure
            }
        } else {
            ///PATHPOINT one way route recording finished -> play/pause
            state = .readyToNavigateOrPause(allowPause: true)
        }
        
    }
    
    @objc func shareRouteAfterRecording(_ sender: UIButton) {
        if let route = justTraveledRoute {
            dataPersistence.uploadToFirebase(route: route)
        }
        self.goHome()
    }
    
    /// handles the user pressing the start navigation button.
    ///
    /// - Parameter sender: the button that generated the event
    @objc func startNavigation(_ sender: UIButton) {
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
        
        // erase nearest keypoint
        ARSessionManager.shared.removeNavigationNodes()

        #if !APPCLIP
        //self.surveyInterface.sendLogDataHelper(pathStatus: nil, vc: self)
        self.hideAllViewsHelper()
        self.state = .endScreen(completedRoute: true)
        print("end screen displayed")
        #else
        self.state = .endScreen(completedRoute: false)
        #endif
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
    
    /// presents a view for the user to enter the app clip code ID
    @objc func enterCodeID() {
        self.recordPathController.remove()
        self.add(enterCodeIDController)
        #if !APPCLIP
        self.rootContainerView.homeButton.isHidden = false
        #endif
    }
    
    /// this is called once the app clip code ID has been entered
    @objc func codeIDEntered() {
        self.enterCodeIDController.remove()
        self.getFirebaseRoutesList()
    }
    
    /// this is called after the alignment countdown timer finishes in order to complete the pause tracking procedure
    @objc func pauseTracking() {
        // pause AR pose tracking
        state = .completingPauseProcedure
    }
    
    func handleTransitionToScanTagView() {
        scanTagController = UIHostingController(rootView: ScanTagView())
        scanTagController?.view.frame = CGRect(x: 0,
                                                                       y: UIScreen.main.bounds.size.height*0.15,
                                                                       width: UIConstants.buttonFrameWidth * 1,
                                                                       height: UIScreen.main.bounds.size.height*0.75)
        scanTagController?.view.backgroundColor = .clear
        
        hideAllViewsHelper()
        ARSessionManager.shared.startSession()
        add(scanTagController!)
    }
    
    /// Configure App Clip to query items
    func handleUserActivity(for url: URL) {
        // TODO: update this to load urls into a list of urls to be passed into the popover list <3
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true), let queryItems = components.queryItems else {
            return
        }
        
        /// with the invocation URL format https://occamlab.github.io/id?p=appClipCodeID, appClipCodeID being the name of the file in Firebase
        if let appClipCodeID = queryItems.first(where: { $0.name == "p"}) {
            self.appClipCodeID = appClipCodeID.value!
            print("app clip code ID from URL: \(appClipCodeID.value!)")
        }
    }
    
    func loadRoute() {
        #if !APPCLIP
        arLogger.startTrial()
        #endif
        recordPathController.remove()
        scanTagController?.remove()
        handleStateTransitionToNavigatingExternalRoute()
    }
    
    func createAppClipObservers() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("firebaseLoaded"), object: nil, queue: nil) { (notification) -> Void in
            /// dismiss loading screen
            self.dismiss(animated: false)
            
            /// bring up list of routes
            let popoverController = UIHostingController(rootView: StartNavigationPopoverView(vc: self, routeList: self.availableRoutes))
            popoverController.modalPresentationStyle = .fullScreen
            self.present(popoverController, animated: true)
            print("popover successful B)")
            // create listeners to ensure that the isReadingAnnouncement flag is reset properly
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("firebaseLoadingFailed"), object: nil, queue: nil) { (notification) -> Void in
            /// dismiss loading screen
            self.dismiss(animated: false)
            self.availableRoutes = RouteListObject()
            /// bring up list of routes
            let popoverController = UIHostingController(rootView: StartNavigationPopoverView(vc: self, routeList: self.availableRoutes))
            popoverController.modalPresentationStyle = .fullScreen
            self.present(popoverController, animated: true)
            print("popover successful B)")
            // create listeners to ensure that the isReadingAnnouncement flag is reset properly
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("shouldDismissRoutePopover"), object: nil, queue: nil) { (notification) -> Void in
            print("ATTEMPTING TO LOAD ROUTE!!!")
            self.dismiss(animated: true)
            self.hideAllViewsHelper()
            self.loadRoute()
        }
    }
    
    func populateSceneFromAppClipURL(scene: UIScene, url: URL) {
        /// This loading screen should show up if the URL is properly invoked
        let loadFromAppClipController = UIHostingController(rootView: LoadFromAppClipView())
        loadFromAppClipController.modalPresentationStyle = .fullScreen
        present(loadFromAppClipController, animated: false)
        print("loading screen successful B)")
        
        handleUserActivity(for: url)
        getFirebaseRoutesList()
    }
    
    func getFirebaseRoutesList() {
        let routeRef = Storage.storage().reference().child("AppClipRoutes")
        let appClipRef = routeRef.child("\(self.appClipCodeID).json")
            
            /// attempt to download .json file from Firebase
            appClipRef.getData(maxSize: 100000000000) { appClipJson, error in
                if error != nil {
                    NotificationCenter.default.post(name: NSNotification.Name("firebaseLoadingFailed"), object: nil)
                    
                } else {
                    do {
                        if let appClipJson = appClipJson {
                            /// unwrap NSData, if it exists, to a list, and set equal to existingRoutes
                            let routesFile = try JSONSerialization.jsonObject(with: appClipJson, options: [])
                            print("File: \(routesFile)")
                            if let routesFile = routesFile as? [[String: String]] {
                                self.availableRoutes.routeList = routesFile
                                print("List: \(self.availableRoutes)")
                                NotificationCenter.default.post(name: NSNotification.Name("firebaseLoaded"), object: nil)
                            }
                        }
                    } catch {
                        print("Failed to download Firebase data due to error \(error)")
                    }
                }
            }
        }
    
    /// this is called when the user has confirmed the alignment and is the alignment countdown should begin.  Once the alignment countdown has finished, the alignment will be performed and the app will move to the ready to navigate view.
    func resumeTracking() {
        // resume pose tracking with existing ARSessionConfiguration
        hideAllViewsHelper()
        pauseTrackingController.remove()
        if case .readyForFinalResumeAlignment = self.state {
            rootContainerView.countdownTimer.isHidden = false
            rootContainerView.countdownTimer.start(beginingValue: ViewController.alignmentWaitingPeriod, interval: 1)
            delayTransition()
        }
        
        if case .startingAutoAlignment = self.state, let routeTransform = self.pausedTransform, let tagAnchor = ARSessionManager.shared.currentFrame?.anchors.compactMap({$0 as? ARImageAnchor}).first {
            rootContainerView.countdownTimer.isHidden = true
            
            let tagToWorld = tagAnchor.transform
            let tagToRoute = routeTransform
            let relativeTransform = (tagToWorld * tagToRoute.inverse).alignY()
            ARSessionManager.shared.manualAlignment = relativeTransform
            self.isResumedRoute = true
            self.paused = false
            self.alignmentTransition()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(ViewController.alignmentWaitingPeriod)) {
            self.rootContainerView.countdownTimer.isHidden = true
            // The first check is necessary in case the phone relocalizes before this code executes
                if case .readyForFinalResumeAlignment = self.state, let routeTransform = self.pausedTransform, /*let tagAnchor = self.sceneView.session.currentFrame?.anchors.compactMap({$0 as? ARAppClipCodeAnchor}).filter({$0.isTracked}).first */ let tagAnchor = ARSessionManager.shared.currentFrame?.camera {
                // yaw can be determined by projecting the camera's z-axis into the ground plane and using arc tangent (note: the camera coordinate conventions of ARKit https://developer.apple.com/documentation/arkit/arsessionconfiguration/worldalignment/camera
                let alignYaw = self.getYawHelper(routeTransform)
                let cameraYaw = self.getYawHelper(tagAnchor.transform)

                print("image tag: \(tagAnchor)")
                var tagToWorld = simd_float4x4.makeRotate(radians: cameraYaw, 0, 1, 0)
                tagToWorld.columns.3 = tagAnchor.transform.columns.3
                print(tagAnchor.transform)
                
                var tagToRoute =  simd_float4x4.makeRotate(radians: alignYaw, 0, 1, 0)
                tagToRoute.columns.3 = routeTransform.columns.3
                
                ARSessionManager.shared.manualAlignment = tagToWorld * tagToRoute.inverse
                
                self.isResumedRoute = true
                if self.paused {
                    ///PATHPOINT paused anchor point alignment timer -> return navigation
                    ///announce to the user that they have aligned to the anchor point sucessfully and are starting  navigation.
                    self.paused = false
                    self.delayTransition(announcement: NSLocalizedString("resumeAnchorPointToReturnNavigationAnnouncement", comment: "This is an Announcement which indicates that the pause session is complete, that the program was able to align with the anchor point, and that return navigation has started."), initialFocus: nil)
                    self.state = .navigatingRoute

                } else {
                    ///PATHPOINT load saved route -> start navigation
                    ///announce to the user that they have sucessfully aligned with their saved anchor point.
                    self.delayTransition(announcement: NSLocalizedString("resumeAnchorPointToReturnNavigationAnnouncement", comment: "This is an Announcement which indicates that the pause session is complete, that the program was able to align with the anchor point, and that return navigation has started."), initialFocus: nil)
                    self.state = .navigatingRoute

                }
            }
            }
        }
    }
    
    /// handles the user pressing the resume tracking confirmation button.
    @objc func confirmResumeTracking() {
        print("entered")
        if let route = justTraveledRoute {
            state = .startingResumeProcedure(route: route, worldMap: justUsedMap, navigateStartToEnd: false)
            print("entered if")
        }
    }
    
    // MARK: - Logging
        
    /// drop a crumb during path recording
    @objc func dropCrumb() {
        guard let curLocation = getRealCoordinates(record: true)?.location, case .recordingRoute = state else {
            return
        }
        recordingCrumbs.append(curLocation)
        //Remove these crumbs in case they case issues with performance
        //ARSessionManager.shared.add(anchor: curLocation)
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
            if !RouteManager.shared.onLastKeypoint {                // arrived at keypoint
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
                waypointFeedbackGenerator?.notificationOccurred(.success)
                if (soundFeedback) { SoundEffectManager.shared.success() }

                RouteManager.shared.checkOffKeypoint()
                ARSessionManager.shared.removeNavigationNodes()
                
                followingCrumbs?.invalidate()
                startEndOfRouteHaptics()

                #if !APPCLIP
                //self.surveyInterface.sendLogDataHelper(pathStatus: nil, announceArrival: true, vc: self)
                self.hideAllViewsHelper()
                // if everything breaks, get this outta there B)
                self.state = .endScreen(completedRoute: true)
                print("end screen displayed")
                #else
                self.state = .endScreen(completedRoute: true)
                #endif
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
    func getProjectedHeading(_ transform: simd_float4x4) -> simd_float4 {
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
    func getYawHelper(_ transform: simd_float4x4) -> Float {
        let projectedHeading = getProjectedHeading(transform)
        return atan2f(-projectedHeading.x, -projectedHeading.z)
    }
    
    // MARK: - Render directions
    
    /// send haptic feedback if the device is pointing towards the next keypoint.
    @objc func getHapticFeedback() {
        if RouteManager.shared.isComplete {
            suppressTrackingWarnings = true
            guard let curPos = getRealCoordinates(record: false)?.location.transform.columns.3.dropw(), let routeEndKeypoint = RouteManager.shared.lastKeypoint, let routeEnd = ARSessionManager.shared.getCurrentLocation(of: routeEndKeypoint.location) else {
                // TODO: might want to indicate that something is wrong to the user
                return
            }
            let routeEndPos = routeEnd.transform.columns.3.dropw()
            let routeEndPosFloorPlane = simd_float2(routeEndPos.x, routeEndPos.z)
            let curPosFloorPlane = simd_float2(curPos.x, curPos.z)
            do {
                print("curPos \(curPosFloorPlane) routeEnd \(routeEndPosFloorPlane)")
                print("ADJUSTING \(max(0.0, 1.0 - simd_distance(curPosFloorPlane, routeEndPosFloorPlane)))")
                try hapticPlayer?.sendParameters([CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: max(0.0, 1.0 - simd_distance(curPosFloorPlane, routeEndPosFloorPlane)), relativeTime: 0.0)], atTime: 0.0)
                print("hapticPlayer \(hapticPlayer)")
            } catch {
                print("Unable to update")
            }
            return
        }
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
            lastOffCourseAnnouncement = nil
            if -feedbackTimer.timeIntervalSinceNow > ViewController.FEEDBACKDELAY {
                // wait until desired time interval before sending another feedback
                if hapticFeedback { feedbackGenerator?.impactOccurred()
                }
                if soundFeedback {
                    SoundEffectManager.shared.playSystemSound(id: 1103)
                }
                feedbackTimer = Date()
            }
        } else if -lastDirectionAnnouncement.timeIntervalSinceNow > Self.directionTextGracePeriod {
            let intervalMultiplier = RouteManager.shared.onFirstKeypoint ? 4.0 : 1.0
            if lastOffCourseAnnouncement == nil || -lastOffCourseAnnouncement!.timeIntervalSinceNow > Self.offTrackCorrectionAnnouncementInterval * intervalMultiplier {
                lastOffCourseAnnouncement = Date()
                if RouteManager.shared.onFirstKeypoint {
                    if directionToNextKeypoint.angleDiff > 0 {
                        AnnouncementManager.shared.announce(announcement: "Bear right to face the start")
                    } else {
                        AnnouncementManager.shared.announce(announcement: "Bear left to face the start")
                        }
                } else {
                    if directionToNextKeypoint.angleDiff > 0 {
                        AnnouncementManager.shared.announce(announcement: "Bear right to get on track")
                    } else {
                        AnnouncementManager.shared.announce(announcement: "Bear left to get on track")
                    }
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
    
    // Called when home button is pressed
    // Chooses the states in which the home page alerts pop up
    @objc func homeButtonPressed() {
    // if the state case needs to have a home button alert, send it to the function that creates the relevant alert
        hideAllViewsHelper()
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
        else if case .endScreen = self.state {
            homePageNavigationProcesses()
        }
        else {
            // proceed to home page
            clearState()
            hideAllViewsHelper()
            #if !APPCLIP
            self.arLogger.finalizeTrial()
            uploadLocalDataToCloudHelper()
            #endif
            self.state = .mainScreen(announceArrival: false)
        }
        
    }
    
    @objc func burgerMenuButtonPressed() {
        #if !APPCLIP
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
        #endif
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
        lastDirectionAnnouncement = Date()
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
    
    /// this tells the ARSession that when the app is becoming active again, we should try to relocalize to the previous world map (rather than proceding with the tracking session in the normal state even though the coordinate systems are no longer aligned).
    /// TODO: not sure if this is actually what we should be doing.  Perhaps we should cancel any recording or navigation if this happens rather than trying to relocalize
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
}

// MARK: - methods for implementing RecorderViewControllerDelegate
#if !APPCLIP
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
#endif

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
        if oldTrackingSessionErrorState != nil {
            if trackingWarningsAllowed {
                AnnouncementManager.shared.announce(announcement: NSLocalizedString("fixedTrackingAnnouncement", comment: "Let user know that the ARKit tracking session has returned to its normal quality (this is played after the tracking has been restored from thir being insuficent visual features or excessive motion which degrade the tracking)"))
                if soundFeedback {
                    SoundEffectManager.shared.playSystemSound(id: 1025)
                }
            }
        }
    }
    
    func sessionDidRelocalize() {
        if trackingWarningsAllowed {
            AnnouncementManager.shared.announce(announcement: NSLocalizedString("realignToSavedRouteAnnouncement", comment: "An announcement which lets the user know that their surroundings have been matched to a saved route"))
        }
        attemptingRelocalization = false
        if case .readyForFinalResumeAlignment = state {
            // TODO: this is not doing the right thing for Clew Maps
            // this will cancel any realignment if it hasn't happened yet and go straight to route navigation mode
            resumeTrackingConfirmController.remove()
            isResumedRoute = true
            isAutomaticAlignment = true
            alignmentTransition()
        }
    }
    
    func isRecording() -> Bool {
        if case .recordingRoute = state {
            return true
        } else {
            return false
        }
    }
    
    func receivedImageAnchors(imageAnchors: [ARImageAnchor]) {
        if case .readyForFinalResumeAlignment = state {
            if imageAnchors.first!.isTracked {
                self.state = .startingAutoAlignment
                resumeTracking()
            }
        }
        
        if case .startingPauseProcedure = state {
            print("number of ARImageAnchors: \(imageAnchors.count)")
            if imageAnchors.first!.isTracked {
                self.state = .startingAutoAnchoring
                print("auto anchoring")
            }
        }
        
        for imageAnchor in imageAnchors {
            let imageNode: SCNNode
            if let existingTagNode = ARSessionManager.shared.sceneView.scene.rootNode.childNode(withName: "Image Tag", recursively: false) {
                imageNode = existingTagNode
                imageNode.simdTransform = imageAnchor.transform
            }
            else {
                if (soundFeedback) {
                    SoundEffectManager.shared.meh()
                }
                
                imageNode = SCNNode()
                imageNode.simdTransform = imageAnchor.transform
                imageNode.name = "Image Tag"
                ARSessionManager.shared.sceneView.scene.rootNode.addChildNode(imageNode)
                
                /// Adds plane to the tag to aid in the visualization
                
                let highlightPlane = SCNNode(geometry: SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height))
                
                highlightPlane.eulerAngles.x = -.pi / 2
                
                highlightPlane.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                highlightPlane.opacity = 0.9
                imageNode.addChildNode(highlightPlane)
            }
        }
    }
    
    func shouldLogRichData() -> Bool {
        if case .mainScreen(_) = state {
            return false
        } else if case .endScreen(_) = state {
            return false
        } else {
            return true
        }
    }
    
    func getLoggingTag()->String {
        return state.rawValue
    }
}

extension NFCTypeNameFormat: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nfcWellKnown: return "NFC Well Known type"
        case .media: return "Media type"
        case .absoluteURI: return "Absolute URI type"
        case .nfcExternal: return "NFC External type"
        case .unknown: return "Unknown type"
        case .unchanged: return "Unchanged type"
        case .empty: return "Empty payload"
        @unknown default: return "Invalid data"
        }
    }
}

#if !APPCLIP
class UISurveyHostingController: UIHostingController<FirebaseFeedbackSurvey> {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.view)
        }
    }
}
#endif
