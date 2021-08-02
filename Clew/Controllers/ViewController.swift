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
import AVFoundation
import AudioToolbox
import MediaPlayer
import VectorMath
import Firebase
import FirebaseDatabase
import SRCountdownTimer
import SwiftUI
import Intents
import IntentsUI
import CoreSpotlight
import MobileCoreServices



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
    case startingResumeProcedure(route: SavedRoute, worldMap: Any?, navigateStartToEnd: Bool)
    /// the AR session has entered the relocalizing state, which means that we can now realign the session
    case readyForFinalResumeAlignment
    /// the user is attempting to name the route they're in the process of saving
    case startingNameSavedRouteProcedure(worldMap: Any?)
    
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
        }
    }
}



/// The view controller that handles the main Clew window.  This view controller is always active and handles the various views that are used for different app functionalities.
class ViewController: UIViewController, ARSCNViewDelegate, SRCountdownTimerDelegate, AVSpeechSynthesizerDelegate {
    
    // MARK: - Refactoring UI definition
    
    // MARK: Properties and subview declarations
    
    /// How long to wait (in seconds) between the alignment request and grabbing the transform
    
    //todel
  
    static var alignmentWaitingPeriod = 5
    /// keep count of conditions routes
    ///
    
    static var ConditionsCount = 0
   // static var ConditionsCount = nav.crembs
    static var sRouteType: String!
    static var sExperimentRouteFlag = false
    static var
        s: [String:String]! = [:]
    var storeCrumbs : [Any]!
    
    /// A threshold distance between the user's current position and a voice note.  If the user is closer than this value the voice note will be played
    static let voiceNotePlayDistanceThreshold : Float = 0.75
    static var testLis : [String] = ["one", "two", "three"]
    /// The state of the ARKit tracking session as last communicated to us through the delgate protocol.  This is useful if you want to do something different in the delegate method depending on the previous state
    var trackingSessionState : ARCamera.TrackingState?
    
    let surveyModel = FirebaseFeedbackSurveyModel.shared
    
    /// the last time this particular user was surveyed (nil if we don't know this information or it hasn't been loaded from the database yet)
    var lastSurveyTime: [String: Double] = [:]
    /// the var for holding previous activity
    var prevSiriActivity: String = "start"
    /// the last time this particular user submitted each survey (nil if we don't know this information or it hasn't been loaded from the database yet)
    var lastSurveySubmissionTime: [String: Double] = [:]
    
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
            case .startingNameSavedRouteProcedure(let worldMap):
                handleStateTransitionToStartingNameSavedRouteProcedure(worldMap: worldMap)
            case .initializing:
                break
            }
        }
    }

 
    ///
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
    /// this Boolean marks whetehr or not the app is recording an experiment route
    var recordingExperimentRoute: Bool = false
    ///this Boolean marks whether or not the app is saving a starting anchor point
    var startAnchorPoint: Bool = false
    
    ///this boolean denotes whether or not the app is loading a route from an automatic alignment
    var isAutomaticAlignment: Bool = false
    
    /// This is an audio player that queues up the voice note associated with a particular route Anchor Point. The player is created whenever a saved route is loaded. Loading it before the user clicks the "Play Voice Note" button allows us to call the prepareToPlay function which reduces the latency when the user clicks the "Play Voice Note" button.
    var voiceNoteToPlay: AVAudioPlayer?
    
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
    //todel

    
    
    /// Handler for the mainScreen app state
    ///
    /// - Parameter announceArrival: a Boolean that indicates whether the user's arrival should be announced (true means the user has arrived)
    func handleStateTransitionToMainScreen(announceArrival: Bool) {
        // cancel the timer that announces tracking errors
        trackingErrorsAnnouncementTimer?.invalidate()
        // if the ARSession is running, pause it to conserve battery
        sceneView.session.pause()
        // set this to nil to prevent the app from erroneously detecting that we can auto-align to the route
        if #available(iOS 12.0, *) {
            configuration.initialWorldMap = nil
        }
        showRecordPathButton(announceArrival: announceArrival)
        ///get the value of current route from defaults to start the experment with
        
        ///
  ///      set s
        stack = Stack()
       
      
       // print(siriShortcutsNameTypeDico.capacity??)
        stack.push("start")
       
       
       //  toKeep
        
      //  incase user has used this before
//      if(!setShortcutsDisplay){
//        UserDefaults.standard.setValue(false, forKey: "siriShortcutExperimentRoute")
//        }
//        print("dumpAnch")
//        print(siriShortcutExperimentRouteFlag)
//
//        print(!setShortcutsDisplay)
//        //print(siriShortcutExperimentRouteFlag ?? false && !setShortcutsDisplay)
//        dump(voiceShortcuts)
//        print("empty")
//        print(voiceShortcuts.isEmpty)
//        print("announce")
//        print(announceArrival)
//        if( announceArrival && siriShortcutExperimentRouteFlag && !setShortcutsDisplay){
//            setShortcutsDisplay = true
//            print("expLoop")
//            dump(voiceShortcuts)
//            if(!voiceShortcuts.isEmpty){
//                for element in voiceShortcuts{
//                        ViewController.voiceCommandsList.append(shortCutInvocationPhasee(phase: element.invocationPhrase, type: element.shortcut.userActivity!.activityType))
//                       print(element.invocationPhrase)
//                    }
//            for element in voiceShortcuts{
//
//               print(element.invocationPhrase)
//                siriShortcutDisplayList.append(element.invocationPhrase)
//                print("inExpLoop")
//                print(element.invocationPhrase)
//                //print(element.shortcut.userActivity?.activityType)
//                siriShortcutsNameTypeDico[element.invocationPhrase] = element.shortcut.userActivity?.activityType
//                siriShortcutsTypeNameDico[element.shortcut.userActivity?.activityType ?? "type"] = element.invocationPhrase
//                print(siriShortcutsNameTypeDico[element.invocationPhrase])
//
//            }}else{
//                siriShortcutDisplayList = unique(source: siriShortcutDisplayList )
//                for element in siriShortcutDisplayList {
//
//                    ViewController.voiceCommandsList.append(shortCutInvocationPhasee(phase:element,type: siriShortcutsTypeNameDico[element] as! String))
//
//                }
//
//
//            }
//
//            print("lenAnch")
//            print(siriShortcutDisplayList.count)
//            print(siriShortcutsNameTypeDico.count)
//            print(siriShortcutsTypeNameDico.count)
//           // siriShortcutExperimentRouteFlag = true
//
//            UserDefaults.standard.setValue(siriShortcutDisplayList, forKey: "siriShortcutDisplayList")
//            UserDefaults.standard.setValue(siriShortcutsNameTypeDico, forKey:  "siriShortcutsNameTypeDico")
//           UserDefaults.standard.setValue( siriShortcutsTypeNameDico, forKey: " siriShortcutsTypeNameDico")
//            UserDefaults.standard.setValue(true, forKey: "siriShortcutExperimentRoute")
//            logger.logSettings(defaultUnit: defaultUnit, defaultColor: defaultColor, soundFeedback: soundFeedback, voiceFeedback: voiceFeedback, hapticFeedback: hapticFeedback, sendLogs: sendLogs, timerLength: timerLength, currentRoute: currentRoute,adjustOffset: adjustOffset,
//                               currentCondition:currentCondition, experimentRouteFlag: experimentRouteFlag, experimentConditonsDico: experimentConditonsDico,
//                               conditionsDico: conditionsDico,siriShortcutDisplayList:siriShortcutDisplayList, siriShortcutsNameTypeDico: siriShortcutsNameTypeDico, siriShortcutsTypeNameDico :siriShortcutsTypeNameDico)
//            sendLogDataHelper(pathStatus: nil)
//        }
            
        
    
        ViewController.sExperimentRouteFlag = false
        
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
        intermediateAnchorPoints = []
        logger.resetPathLog()
        
        showStopRecordingButton()
        droppingCrumbs = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(dropCrumb), userInfo: nil, repeats: true)
        // make sure there are no old values hanging around
        nav.headingOffset = 0.0
        headingRingBuffer.clear()
        locationRingBuffer.clear()
        recordPhaseHeadingOffsets = []
        updateHeadingOffsetTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: (#selector(updateHeadingOffset)), userInfo: nil, repeats: true)
        
        print("crumbsHere")
        print(crumbs.count)
        dump(crumbs)
    }
    
    /// Handler for the readyToNavigateOrPause app state
    ///
    /// - Parameter allowPause: a Boolean that determines whether the app should allow the user to pause the route (this is only allowed if it is the initial route recording)
    func handleStateTransitionToReadyToNavigateOrPause(allowPause: Bool) {
        droppingCrumbs?.invalidate()
        updateHeadingOffsetTimer?.invalidate()
        showStartNavigationButton(allowPause: allowPause)
      //  suggestAdjustOffsetIfAppropriate()
    }
    
    /// Handler for the navigatingRoute app state
    func handleStateTransitionToNavigatingRoute() {
        // navigate the recorded path

        // If the route has not yet been saved, we can no longer save this route
        routeName = nil
        beginRouteAnchorPoint = RouteAnchorPoint()
        endRouteAnchorPoint = RouteAnchorPoint()

        logger.resetNavigationLog()
        print("checkcrumbs: inside handleStateTransitionToNavigatingRoute()")
        print("capaci")
        print(crumbs.capacity)
        print("dropcrum")
        dump(crumbs)
        
        // generate path from PathFinder class
        // enabled hapticFeedback generates more keypoints
        let path = PathFinder(crumbs: crumbs.reversed(), hapticFeedback: hapticFeedback, voiceFeedback: voiceFeedback)
        keypoints = path.keypoints
        
        // save keypoints data for debug log
        logger.logKeypoints(keypoints: keypoints)
        
        // render 3D keypoints
        renderKeypoint(keypoints[0].location)
        
        // ? getting user location
        prevKeypointPosition = getRealCoordinates(record: true)!.location
        
        // render path
        if (showPath) {
            renderPath(prevKeypointPosition, keypoints[0].location)
        }
        
        // render pathpoints
//        renderPathpoints(prevKeypointPosition, keypoints[0].location)
        
        // render intermediate anchor points
        renderIntermediateAnchorPoints()
        
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
    func handleStateTransitionToStartingResumeProcedure(route: SavedRoute, worldMap: Any?, navigateStartToEnd: Bool) {
        logger.setCurrentRoute(route: route, worldMap: worldMap)
        
        // load the world map and restart the session so that things have a chance to quiet down before putting it up to the wall
        var isTrackingPerformanceNormal = false
        if case .normal? = sceneView.session.currentFrame?.camera.trackingState {
            isTrackingPerformanceNormal = true
        }
        var isRelocalizing = false
        if case .limited(reason: .relocalizing)? = sceneView.session.currentFrame?.camera.trackingState {
            isRelocalizing = true
        }
        var isSameMap = false
        if #available(iOS 12.0, *), let worldMap = worldMap as? ARWorldMap? {
            isSameMap = configuration.initialWorldMap != nil && configuration.initialWorldMap == worldMap
            configuration.initialWorldMap = worldMap
            attemptingRelocalization =  isSameMap && !isTrackingPerformanceNormal || worldMap != nil && !isSameMap
        }
    

        if navigateStartToEnd {
            crumbs = route.crumbs.reversed()
            pausedTransform = route.beginRouteAnchorPoint.transform
        } else {
            crumbs = route.crumbs
            pausedTransform = route.endRouteAnchorPoint.transform
        }
        intermediateAnchorPoints = route.intermediateAnchorPoints
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
    func handleStateTransitionToStartingNameSavedRouteProcedure(worldMap: Any?){
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
                ///announce to the user that they have sucessfully saved an anchor point.
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
            //showAdjustOffsetSuggestion()
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
        if creatingRouteAnchorPoint {
            guard let currentTransform = sceneView.session.currentFrame?.camera.transform else {
                print("can't properly save Anchor Point: TODO communicate this to the user somehow")
                return
            }
            // make sure we log the transform
            let _ = self.getRealCoordinates(record: true)
            beginRouteAnchorPoint.transform = currentTransform
            pauseTrackingController.remove()
            
            ///PATHPOINT begining anchor point alignment timer -> record route
            ///announce to the user that they have sucessfully saved an anchor point.
            delayTransition(announcement: NSLocalizedString("multipleUseRouteAnchorPointToRecordingRouteAnnouncement", comment: "This is the announcement which is spoken after the first anchor point of a multiple use route is saved. this signifies the completeion of the saving an anchor point procedure and the start of recording a route to be saved."), initialFocus: nil)
            ///sends the user to a route recording of the program is creating a beginning route Anchor Point
            state = .recordingRoute
            return
        } else if let currentTransform = sceneView.session.currentFrame?.camera.transform {
            // make sure to log transform
            let _ = self.getRealCoordinates(record: true)
            endRouteAnchorPoint.transform = currentTransform
            // no more crumbs
            droppingCrumbs?.invalidate()

            if #available(iOS 12.0, *) {
                sceneView.session.getCurrentWorldMap { worldMap, error in
                    self.completingPauseProcedureHelper(worldMap: worldMap)
                }
            } else {
                completingPauseProcedureHelper(worldMap: nil)
            }
        }
    }
    
    func completingPauseProcedureHelper(worldMap: Any?) {
        //check whether or not the path was called from the pause menu or not
        if paused {
            ///PATHPOINT pause recording anchor point alignment timer -> resume tracking
            //proceed as normal with the pause structure (single use route)
            justTraveledRoute = SavedRoute(id: "single use", name: "single use", crumbs: self.crumbs, dateCreated: Date() as NSDate, beginRouteAnchorPoint: self.beginRouteAnchorPoint, endRouteAnchorPoint: self.endRouteAnchorPoint, intermediateAnchorPoints: intermediateAnchorPoints)
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
        try! self.archive(routeId: id, beginRouteAnchorPoint: self.beginRouteAnchorPoint, endRouteAnchorPoint: self.endRouteAnchorPoint, intermediateAnchorPoints: self.intermediateAnchorPoints, worldMap: nameSavedRouteController.worldMap)
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
    
    /// saving route name VC
    var nameSavedRouteController: NameSavedRouteController!
    
    /// start route navigation VC
    var startNavigationController: StartNavigationController!
    
    /// work item for playing alignment confirmation sound
    var playAlignmentConfirmation: DispatchWorkItem?
    
    /// stop route navigation VC
    var stopNavigationController: StopNavigationController!
    ///siri shortcuts VC
    var siriShortcutsController: SiriShortcutsController!
    var siriShortcutList: [String] = []
    public var voiceShortcuts: [INVoiceShortcut] = []
    static var voiceCommandsList : [shortCutInvocationPhasee]=[]
    //todel
    var cc: Int = 1
    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.accessibilityIgnoresInvertColors = true
        
        // set the main view as active
        view = RootContainerView(frame: UIScreen.main.bounds)
        self.modalPresentationStyle = .fullScreen
        // initialize child view controllers
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
            if let gaveFeedback = notification.object as? Bool, gaveFeedback {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.announce(announcement: NSLocalizedString("thanksForFeedbackAnnouncement", comment: "This is read right after the user fills out a feedback survey."))
                }
            }
        }
    }
    
    /// Create the audio player objdcts for the various app sounds.  Creating them ahead of time helps reduce latency when playing them later.
    func setupAudioPlayers() {
        do {
            audioPlayers[1103] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/Tink.caf"))
            audioPlayers[1016] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/tweet_sent.caf"))
            audioPlayers[1050] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/ussd.caf"))
            audioPlayers[1025] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/New/Fanfare.caf"))

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
                else if snapshot.exists(), let userDict = snapshot.value as? [String : AnyObject] {
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
        
//        if(!experimentRouteFlag){
//
//            showSignificantChangesHandsFreeAlert()
//            UserDefaults.standard.setValue(true, forKey: "experimentRouteFlag")
//            //expeimentRouteFlag
//        }
//
//
//        updateExperiment()
        let userDefaults: UserDefaults = UserDefaults.standard
        //todel
        //reintialise everythin for test puposes
      //UserDefaults.standard.setValue(false, forKey: "siriShortcutStartNavigatingRoute")
//        siriShortcutExperimentRouteFlag = false
    // UserDefaults.standard.setValue(false, forKey: "siriShortcutExperimentRoute")
        UserDefaults.standard.setValue(false, forKey: "siriShortcutAlert")
        UserDefaults.standard.setValue(startExperimentWithList.randomElement(), forKey: "currentRoute")
        
        UserDefaults.standard.setValue(false, forKey: "singleUseRouteExperimentFlag")
        UserDefaults.standard.setValue(false, forKey: "experimentRouteFlag")
        //UserDefaults.standard.setValue("lanyard", forKey: "currentCondition")
        let cConditions: Dictionary? =  userDefaults.dictionary(forKey: "conditionsDico")
        print("before Condition")
        print(cConditions)
        let tecondtions = ["lanyard":0,"bracing":3,"none":3]
        let recondtions = ["lanyard":0,"bracing":0,"none":0]
    UserDefaults.standard.setValue(recondtions, forKey: "conditionsDico")
        
       
        UserDefaults.standard.setValue(false, forKey:   "completedExperiment")
        UserDefaults.standard.setValue(recondtions, forKey: "experimentConditonsDico")
       
        
     // UserDefaults.standard.setValue(false, forKey: "siriShortcutExperimentRoute")
      //todel
       //ch UserDefaults.standard.setValue([""], forKey: "siriShortcutDisplayList")
        let tConditions: Dictionary? =  userDefaults.dictionary(forKey: "conditionsDico")
        
        print("After tCondition")
        print(tConditions)
        if(!siriShortcutAlert){

            showSignificantChangesHandsFreeAlert()
            UserDefaults.standard.setValue(true, forKey: "siriShortcutAlert")
        }
        
        
        
        
        
        
        
        let firstTimeLoggingIn: Bool? = userDefaults.object(forKey: "firstTimeLogin") as? Bool
        let showedSignificantChangesAlert: Bool? = userDefaults.object(forKey: "showedSignificantChangesAlertv1_3") as? Bool
        
        if firstTimeLoggingIn == nil {
            userDefaults.set(Date().timeIntervalSince1970, forKey: "firstUsageTimeStamp")
            userDefaults.set(true, forKey: "firstTimeLogin")
            // make sure not to show the significant changes alert in the future
            userDefaults.set(true, forKey: "showedSignificantChangesAlertv1_3")
            showLogAlert()
        } else if showedSignificantChangesAlert == nil {
            // we only show the significant changes alert if this is an old installation
            userDefaults.set(true, forKey: "showedSignificantChangesAlertv1_3")
            // don't show this for now, but leave the plumbing in place for a future significant change
            // showSignificantChangesAlert()
        }
        
       
        
        
        synth.delegate = self
        NotificationCenter.default.addObserver(forName: UIAccessibility.announcementDidFinishNotification, object: nil, queue: nil) { (notification) -> Void in
            self.currentAnnouncement = nil
            if let nextAnnouncement = self.nextAnnouncement {
                self.nextAnnouncement = nil
                self.announce(announcement: nextAnnouncement)
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
    
    /// Display a warning that tells the user they must create a Anchor Point to be able to use this route again in the forward direction
    func showRecordPathWithoutAnchorPointWarning() {
        state = .recordingRoute
    }
    
    /// func that prepares the state transition to home by clearing active processes and data
    func clearState() {
        // TODO: check for code reuse
        // Clearing All State Processes and Data
        rootContainerView.homeButton.isHidden = true
        recordPathController.isAccessibilityElement = false
        if case .navigatingRoute = self.state {
            keypointNode.removeFromParentNode()
            pathObj?.removeFromParentNode()
//            pathpointObjs.map({$0.removeFromParentNode()})
//            pathpointObjs = []
            for anchorPointNode in anchorPointNodes {
                anchorPointNode.removeFromParentNode()
            }
        }
        followingCrumbs?.invalidate()
        recordPhaseHeadingOffsets = []
        routeName = nil
        beginRouteAnchorPoint = RouteAnchorPoint()
        endRouteAnchorPoint = RouteAnchorPoint()
        intermediateAnchorPoints = []
        playAlignmentConfirmation?.cancel()
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
            ViewController.sExperimentRouteFlag = false
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
            //UserDefaults.standard.set(true, forKey: "adjustOffset")
        }
        ))
        alert.addAction(UIAlertAction(title: NSLocalizedString("declineTurnOnAdjustOffsetButton", comment: "A button which declines to turn on the adjust offset feature"), style: .default, handler: { action -> Void in
            // nothing to do, just stay on the page
        }
        ))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    //function that creates alerts once 3 routes has been completed
//    func showRedoRoutesSuggestion(condition: String, content: String) {
//        // Create alert to warn users of lost information
//        let alert = UIAlertController(title: NSLocalizedString("redoRoutesSuggestionTitle", comment: "This is the title of an alert which shows up when the user completes 3  routes of a given condition"),
//                                      message: NSLocalizedString(content, comment: "this is the content of an alert which tells the user that they should confirm the completion of 3 routes."),
//                                      preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: NSLocalizedString("completedThreeRoutes", comment: "This text appears on a button that "), style: .default, handler: { action -> Void in
//            // nothing to do
//        }
//        ))
//        alert.addAction(UIAlertAction(title: NSLocalizedString("redoOneRoute", comment: "A button that decrements the number of routess completed"), style: .default, handler: { action -> Void in
//            // nothing to do, just stay on the page
//        }
//        ))
//        alert.addAction(UIAlertAction(title: NSLocalizedString("redoTwoRoutes", comment: "This text appears on a button that "), style: .default, handler: { action -> Void in
//            // nothing to do
//        }
//        ))
//        alert.addAction(UIAlertAction(title: NSLocalizedString("redoThreeRoutes", comment: "This text appears on a button that "), style: .default, handler: { action -> Void in
//            // nothing to do
//        }
//        ))
//
//        self.present(alert, animated: true, completion: nil)
//    }
//

    ///presents a pop after recording an experiment route, to confirm that the use has successfully recorded the route with required condition. if the user selects "completed", route is stores and logs are uploaded. otherwise, the user can redo to the route.
    /// parameters:
    ///           condition: the current condition
////                                content: String:  the localisible string message content for the specific condition
    func showRedoExperimentRoutesSuggestion (condition: String, content: String) {
        // Create alert to warn users of lost information
        let alert = UIAlertController(title: NSLocalizedString("redoRoutesSuggestionTitle", comment: "This is the title of an alert which shows up when the user completes 3  routes of a given condition"),
                                      message: NSLocalizedString(content, comment: "this is the content of an alert which tells the user that they should confirm the completion of 3 routes."),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("completedThreeRoutes", comment: "This text appears on a button that "), style: .default, handler: { [self] action -> Void in
            // nothing to do
            print("insideRedoAlert")
            print("before")
            print(self.experimentConditonsDico)
            experimentConditonsDico[condition]! = experimentConditonsDico[condition] as! Int + 1
            
            UserDefaults.standard.setValue(experimentConditonsDico, forKey: "experimentConditonsDico")
            print("after")
            ViewController.ConditionsCount =  experimentConditonsDico[condition] as! Int
            print(experimentConditonsDico)
            sendExpRouteLog()
            
            
            
            
        }
     
        
        )
    
        )
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("redoOneRoute", comment: "A button that decrements the number of routess completed"), style: .default, handler: { action -> Void in
            // nothing to do, just stay on the page
            
        }
        ))
        //ViewController.ConditionsCount = 200
        print("ttt")
        print(experimentConditonsDico[condition] as! Int )
        
        //ViewController.ConditionsCount =  experimentConditonsDico[condition] as! Int
        self.present(alert, animated: true, completion: nil)
        
        
    }
    
    ///presents a pop after recording a single use route  to confirm that the use has successfully recorded the route with required condition. if the user selects "completed", route is stores and logs are uploaded. otherwise, the user can redo to the route.
    /// parameters:
    ///           condition: the current condition
////                                content: String:  the localisible string message content for the specific condition
    
    func showRedoRoutesSuggestion(condition: String, content: String) {
        // Create alert to warn users of lost information
        let alert = UIAlertController(title: NSLocalizedString("redoRoutesSuggestionTitle", comment: "This is the title of an alert which shows up when the user completes 3  routes of a given condition"),
                                      message: NSLocalizedString(content, comment: "this is the content of an alert which tells the user that they should confirm the completion of 3 routes."),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("completedThreeRoutes", comment: "This text appears on a button that "), style: .default, handler: { [self] action -> Void in
           // print("in Redo b4")
            //print("before")
            //print(conditionsDico)
            //print(conditionsDico[condition]as! Int)
            conditionsDico[condition] = conditionsDico[condition] as! Int + 1
          //  print("in Redo after")
           // print(conditionsDico[condition]as! Int)
            
            
            
            UserDefaults.standard.setValue(conditionsDico, forKey: "conditionsDico")
           // print("dico after")
          //  print(conditionsDico)
            ViewController.ConditionsCount =  conditionsDico[condition] as! Int
            
            if(conditionsDico[currentCondition]! as! Int == 3){
                showCompleteSurveytAlert()
            }
            sendLogSinglueUseRoute()
            
        }
        ))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("redoOneRoute", comment: "A button that decrements the number of routess completed"), style: .default, handler: { action -> Void in
            
            
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
        
        

       // var ss = String(format:, test1)
        
        let changesAlertVC = UIAlertController(title:NSLocalizedString( "SiriAlert" , comment: "The heading of a pop-up telling the user that significant changes have been made to this app version"),
                                               message: NSLocalizedString("significantVersionChangesPop-UpContent", comment: "An alert shown to the user to alert them to the fact that significant changes have been made to the app."),
                                               preferredStyle: .alert)
        changesAlertVC.addAction(UIAlertAction(title: NSLocalizedString("significantVersionChanges-Confirmation", comment: "What the user clicks to acknowledge the significant changes message and dismiss pop-up"), style: .default, handler: { action -> Void in
        }
        ))
        self.present(changesAlertVC, animated: true, completion: nil)
        if case .recordingRoute = self.state{
            
            changesAlertVC.dismiss(animated: true, completion: nil)
            print("dismiss changes")
        }
    }
    
    func showSignificantChangesHandsFreeAlert() {
        let changesAlertVC = UIAlertController(title: NSLocalizedString("significantVersionChangesPop-UpHeading", comment: "The heading of a pop-up telling the user that significant changes have been made to this app version"),
                                               message: NSLocalizedString("significantVersionChangesPopHandsFree-UpContent", comment: "An alert shown to the user to alert them to the fact that significant changes have been made to the app."),
                                               preferredStyle: .alert)
        changesAlertVC.addAction(UIAlertAction(title: NSLocalizedString("significantVersionChanges-Confirmation", comment: "What the user clicks to acknowledge the significant changes message and dismiss pop-up"), style: .default, handler: { action -> Void in
        }
        ))
        self.present(changesAlertVC, animated: true, completion: nil)
    }
    ///
/// pops up when the user presses on participate on experiment before enabling all siri shortcuts
    func showEnableSiriAlert() {
        let changesAlertVC = UIAlertController(title: NSLocalizedString("ExperimentInstructions" , comment: "Notify the User that they have completed the experiment"),
                                               message: NSLocalizedString("enableSiriContent", comment: "Notify the User that they have completed the experiment."),
                                               preferredStyle: .alert)
        changesAlertVC.addAction(UIAlertAction(title: NSLocalizedString("significantVersionChanges-Confirmation", comment: "What the user clicks to acknowledge the significant changes message and dismiss pop-up"), style: .default, handler: { action -> Void in
        }
        ))
        self.present(changesAlertVC, animated: true, completion: nil)
       
    }
    
    ///pops up when the user has completed all routes
    func showCompletedExperimentAlert() {
        let changesAlertVC = UIAlertController(title: NSLocalizedString("completedExperimentTitle", comment: "Notify the User that they have completed the experiment"),
                                               message: NSLocalizedString("completedExperimentContent", comment: "Notify the User that they have completed the experiment."),
                                               preferredStyle: .alert)
        changesAlertVC.addAction(UIAlertAction(title: NSLocalizedString("significantVersionChanges-Confirmation", comment: "What the user clicks to acknowledge the significant changes message and dismiss pop-up"), style: .default, handler: { action -> Void in
        }
        ))
        self.present(changesAlertVC, animated: true, completion: nil)
       
    }
    
    func showCompleteSurveytAlert() {
        let changesAlertVC = UIAlertController(title: NSLocalizedString("completeSurveyTitle" , comment: "Notify the User that they have completed the experiment"),
                                               message: NSLocalizedString("enableSiriContent", comment: "Notify the User that they have completed the experiment."),
                                               preferredStyle: .alert)
        changesAlertVC.addAction(UIAlertAction(title: NSLocalizedString("completeSurveyContent", comment: "What the user clicks to acknowledge the significant changes message and dismiss pop-up"), style: .default, handler: { action -> Void in
            
            
            
            let wait = false
                       
            let logFileURLs = self.logger.compileLogData(nil)
            
           //  DispatchQueue.main.asyncAfter(deadline: .now() + (false ? 1 : 1)) {
                // self.presentSurveyIfIntervalHasPassed(mode: "afterRoute", logFileURLs: logFileURLs)
             //}
                            
                        
            
        }
        ))
        self.present(changesAlertVC, animated: true, completion: nil)
       
    }
    
//    ///pops up when the user has completed all routes
//    func showCompletedExperimentAlert() {
//        let changesAlertVC = UIAlertController(title: NSLocalizedString("completedExperimentTitle", comment: "Notify the User that they have completed the experiment"),
//                                               message: NSLocalizedString("completedExperimentContent", comment: "Notify the User that they have completed the experiment."),
//                                               preferredStyle: .alert)
//        changesAlertVC.addAction(UIAlertAction(title: NSLocalizedString("significantVersionChanges-Confirmation", comment: "What the user clicks to acknowledge the significant changes message and dismiss pop-up"), style: .default, handler: { action -> Void in
//        }
//        ))
//        self.present(changesAlertVC, animated: true, completion: nil)
//
//    }
    
    

//    func showCompleteSurveytAlert() {
//        let changesAlertVC = UIAlertController(title: NSLocalizedString("completeSurveyTitle", comment: "Notify the user about the survey that they should complete"),
//                                               message: NSLocalizedString("completeSurveyContent", comment: "Notify the User that they should complete a survey."),
//                                               preferredStyle: .alert)
//        changesAlertVC.addAction(UIAlertAction(title: NSLocalizedString("significantVersionChanges-Confirmation", comment: "What the user clicks to acknowledge the significant changes message and dismiss pop-up"), style: .default, handler: { action -> Void in
//
//            let logFileURLs = logger.compileLogData(true)
//            let wait = false
//            DispatchQueue.main.asyncAfter(deadline: .now() + (wait ? 1 : 1)) {
//                self.presentSurveyIfIntervalHasPassed(mode: "afterRoute", logFileURLs: logFileURLs)
//            }
//        }
//        ))
//        self.present(changesAlertVC, animated: true, completion: nil)
//
//    }
//
    
    
    func experimentInstructionAlert(instruction: String) {
        
        let changesAlertVC = UIAlertController(title: String(format: NSLocalizedString("ExperimentInstructions", comment: "The heading of a pop-up telling the user what actions to take"), countCompleted()),
                                               message: NSLocalizedString(instruction, comment: "An alert shown to the user to give them instructions."),
                                               preferredStyle: .alert)
        changesAlertVC.addAction(UIAlertAction(title: NSLocalizedString("QuitExperiment", comment: "What the user clicks to acknowledge message and dismiss pop-up"), style: .default, handler: { action -> Void in
            
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
   
    
    public func updateVoiceShortcuts(completion: (() -> Void)?) {
       
         
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { (voiceShortcutsFromCenter, error) in
               guard let voiceShortcutsFromCenter = voiceShortcutsFromCenter else {
                   if let error = error {
                       print("Failed to fetch voice shortcuts with error: \(error.localizedDescription)")
                   }
                   return
               }
               self.voiceShortcuts = voiceShortcutsFromCenter
               if let completion = completion {
                   completion()
               }
           }
       }

    
    /// Register settings bundle
    func registerSettingsBundle(){
        let appDefaults = ["siriShortcutTypeNameDictionary":[" ":" " ],"siriShortcutNameTypeDictionary": [" ":" "], "siriShortcutsTypeNameDico": ["":""],"siriShortcutsNameTypeDico": ["":""],"siriShortcutDisplayList": [""],"crumbColor": 0, "showPath": true, "pathColor": 0, "hapticFeedback": true, "sendLogs": true, "voiceFeedback": true, "soundFeedback": true, "adjustOffset": false, "units": 0, "timerLength":5, "conditionsDico": ["lanyard":0,"bracing":0,"none":0],"experimentConditonsDico": ["lanyard":0,"bracing":0,"none":0], "siriShortcutSingleUseRoute": false,  "siriShortcutStopRecordingRoute": false, "experimentRouteFlag":false,"singleUseRouteExperimentFlag":false,  "currentCondition": conditionsList.randomElement(), "siriShortcutExperimentRoute": false,"siriShortcutStartNavigatingRoute": false,"currentRoute":startExperimentWithList.randomElement(), "siriShortcutAlert": false, "completedExperiment":false, "startedExperiment": false] as [String : Any]
        UserDefaults.standard.register(defaults: appDefaults)
    }

    /// Respond to update events to the `UserDefaults` object (the settings of the app).
    func updateDisplayFromDefaults(){
        let defaults = UserDefaults.standard
        siriShortcutsTypeNameDico = defaults.dictionary(forKey: "siriShortcutsTypeNameDico")
        siriShortcutNameTypeDictionary = defaults.object(forKey: "siriShortcutNameTypeDictionary")  as? [String:String] ?? [:]
        
        siriShortcutTypeNameDictionary = defaults.object(forKey: "siriShortcutTypeNameDictionary")  as? [String:String] ?? [:]
        siriShortcutsNameTypeDico = defaults.dictionary(forKey: "siriShortcutsNameTypeDico")
        startedExperiment = defaults.bool(forKey: "startedExperiment")
        completedExperiment = defaults.bool(forKey: "completedExperiment")
        defaultUnit = defaults.integer(forKey: "units")
        defaultColor = defaults.integer(forKey: "crumbColor")
        showPath = defaults.bool(forKey: "showPath")
        defaultPathColor = defaults.integer(forKey: "pathColor")
        soundFeedback = defaults.bool(forKey: "soundFeedback")
        voiceFeedback = defaults.bool(forKey: "voiceFeedback")
        hapticFeedback = defaults.bool(forKey: "hapticFeedback")
        experimentRouteFlag = defaults.bool(forKey:"experimentRouteFlag")
        singleUseRouteExperimentFlag = defaults.bool(forKey: "singleUseRouteExperimentFlag")
       
        siriShortcutSingleUseRouteFlag = defaults.bool(forKey:"siriShortcutSingleUseRoute")
        //todel
        //defaults.setValue(false, forKey:" siriShortcutExperimentRoute")
       siriShortcutExperimentRouteFlag = defaults.bool(forKey: "siriShortcutExperimentRoute")
       
        siriShortcutStopRecordingRouteFlag = defaults.bool(forKey:"siriShortcutStopRecordingRoute")
        siriShortcutStartNavigatingRouteFlag = defaults.bool(forKey:"siriShortcutStartNavigatingRoute")
        siriShortcutAlert = defaults.bool(forKey: "siriShortcutAlert")
        //distance = defaults.float(forKey: "distance")
        siriShortcutDisplayList = defaults.stringArray(forKey: "siriShortcutDisplayList")
        sendLogs = true // (making this mandatory) defaults.bool(forKey: "sendLogs")
        timerLength = defaults.integer(forKey: "timerLength")
        currentCondition = defaults.string(forKey: "currentCondition")
        
       
        adjustOffset = false // making this off by defualt
        experimentConditonsDico=defaults.dictionary(forKey:"experimentConditonsDico")
        conditionsDico = defaults.dictionary(forKey:"conditionsDico")
        currentRoute =  defaults.string(forKey: "currentRoute")
        nav.useHeadingOffset = adjustOffset
        
        
        
        // TODO: log settings here
        logger.logSettings(siriShortcutTypeNameDictionary: siriShortcutTypeNameDictionary, siriShortcutNameTypeDictionary: siriShortcutNameTypeDictionary, defaultUnit: defaultUnit, defaultColor: defaultColor, soundFeedback: soundFeedback, voiceFeedback: voiceFeedback, hapticFeedback: hapticFeedback, sendLogs: sendLogs, timerLength: timerLength, currentRoute: currentRoute,adjustOffset: adjustOffset,
                           currentCondition:currentCondition, experimentRouteFlag: experimentRouteFlag, experimentConditonsDico: experimentConditonsDico,
                           conditionsDico: conditionsDico,siriShortcutDisplayList:siriShortcutDisplayList, siriShortcutsNameTypeDico: siriShortcutsNameTypeDico, siriShortcutsTypeNameDico :siriShortcutsTypeNameDico )
        
        // leads to JSON like:
        //   options: { "unit": "meter", "soundFeedback", true, ... }
    }
    
    /// Handles updates to the app settings.
    @objc func defaultsChanged(){
        updateDisplayFromDefaults()
    }
    
     
    
    /// Create a new ARSession.
    func createARSessionConfiguration() {
        configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isAutoFocusEnabled = false
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
        add(recordPathController)
        /// handling main screen transitions outside of the first load
        /// add the view of the child to the view of the parent
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
        print("initialFocus \(initialFocus) announcement \(announcement)")
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
     // hide pause button for single use route
         if(recordingSingleUseRoute) {
             startNavigationController.pauseButton.isHidden =  true
         }
        
        
       // startNavigationController.pauseButton.isHidden = !allowPause
        startNavigationController.largeHomeButton.isHidden = recordingSingleUseRoute
        startNavigationController.stackView.layoutIfNeeded()
    
        announce(announcement: NSLocalizedString("stoppedTrachingSessionAnnouncement", comment: "An announcement which lets the user know that they have stopped recording the route."))
        
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
        delayTransition()
    }
    
    /// Display the resume tracking view/hide all other views
    @objc func showResumeTrackingButton() {
        rootContainerView.homeButton.isHidden = false // no home button here
        pauseTrackingController.remove()
        add(resumeTrackingController)
        UIApplication.shared.keyWindow!.bringSubviewToFront(rootContainerView)
        delayTransition()
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
        if !remindedUserOfOffsetAdjustment && adjustOffset {
            altText += ". " + NSLocalizedString("adjustOffsetReminderAnnouncement", comment: "This is the announcement which is spoken after starting navigation if the user has enabled the Correct Offset of Phone / Body option.")
            remindedUserOfOffsetAdjustment = true
        }
        if case .navigatingRoute = state {
            logger.logSpeech(utterance: altText)
        }
        announce(announcement: altText)
    }
    
    // MARK: - BreadCrumbs
    
    /// AR Session Configuration
    var configuration: ARWorldTrackingConfiguration!
    
    /// MARK: - Clew internal datastructures
    
    /// list of crumbs dropped when recording path
    var recordingCrumbs: LinkedList<LocationInfo>!
    
    /// list of crumbs to use for route creation
    var crumbs: [LocationInfo]!
    
    /// list of keypoints calculated after path completion
    var keypoints: [KeypointInfo]!
    
    /// SCNNode of the next keypoint
    var keypointNode: SCNNode!
    
    /// SCNNode of the bar path
    var pathObj: SCNNode?
    
    /// SCNNode of the spherical pathpoints
    var pathpointObjs: [SCNNode] = []
    
    /// SCNNode of the intermediate anchor points
    var anchorPointNodes: [SCNNode] = []
    
    /// previous keypoint location - originally set to current location
    var prevKeypointPosition: LocationInfo!

    /// Interface for logging data about the session and the path
    var logger = PathLogger()
    
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
  ///  true if shortcuts are set, false otherwise.
    var siriShortcutSingleUseRouteFlag : Bool!
    var siriShortcutStopRecordingRouteFlag : Bool!
    var siriShortcutExperimentRouteFlag : Bool!
    var siriShortcutStartNavigatingRouteFlag : Bool!
/// used to determine whether the user has  been shown the new feature pop up
    var siriShortcutAlert: Bool!
    /// if true means that user has been shown the first instruction of the experiment
  //flags that indicates which part of the experiment the user is in
    var experimentRouteFlag: Bool!
    var singleUseRouteExperimentFlag: Bool!
   
    // used to determine which route the user is in (single use or experiment)
    var currentRoute: String!
    // list used for setting the randomisation of routes order
    var startExperimentWithList : [String]! = ["ExperimentRoute", "SingleUseRoute"]
    /// the color of the path.  0 is red, 1 is green, 2 is blue, and 3 is random
    var defaultPathColor: Int!
    // store the distance between the first and last frame of experiment route
    
    var distance: Float!
    
    /// true if sound feedback should be generated when the user is facing the next waypoint, false otherwise
    var soundFeedback: Bool!
    
    /// true if the app should announce directions via text to speech, false otherwise
    var voiceFeedback: Bool!
    
    /// true if haptic feedback should be generated when the user is facing the next waypoint, false otherwise
    var hapticFeedback: Bool!

    /// true if we should prompt the user to rate route navigation and then send log data to the cloud
    var sendLogs: Bool!
    ///
    ///used in app delegate to determine which states are valid to transitin to when using siri shortcuts. 
    var stack: Stack!
    
    
    /// The length of time that the timer will run for
    var timerLength: Int!
    /// stores what condition to do.
    var condition: Int!
    /// holds the conditin
   // var conditionList: [String]!
    /// holds the current condition
    var currentCondition: String!
    var nextCondition: String!
    ///list of condition to randomise from
    var conditionsList:[String]! = ["lanyard", "none", "bracing"]
///used in AppDelegate to detemine if a state transition is valid
  
    
    var setShortcutsDisplay: Bool = false
    // dictionary that holds the state of the experiment in Single user route, where:
    //keys: String: conditions names,
    //values: Any: number of times this conditons has been completed.
    // stored in settings history.
    var conditionsDico: [String :Any]!
    
    var experimentConditonsDico: [String :Any]!
    // stores sirishorcuts phrases to display on burger menu
    var siriShortcutDisplayList : [String]!
    var siriShortcutNameTypeDictionary : [String: String]!
    var siriShortcutTypeNameDictionary : [String: String]!
    var helpNameTypeDictionary : [String: String] = [:]
    var helpTypeNameDictionary : [String: String] = [:]
    //var conditionsDicoSet =
    //determines if the user has started experiment or not
    
    var startedExperiment: Bool!
    var completedExperiment: Bool!
    /// This keeps track of the paused transform while the current session is being realigned to the saved route
    var pausedTransform : simd_float4x4?
    
    /// the Anchor Point to use to mark the beginning of the route currently being recorded
    var beginRouteAnchorPoint = RouteAnchorPoint()
    
    /// the Anchor Point to use to mark the end of the route currently being recorded
    var endRouteAnchorPoint = RouteAnchorPoint()
    /// storeres the types of siri shortcut, where key is type and value is the statment to display on screen
    static var siriShortcutsTypesDico = [kNewSingleUseRouteType : "Single Use Route Siri Shortcut:", kExperimentRouteType: "Experiment Route Siri Shortcut:", kStopRecordingType: "Stop Recording Siri Shortcut:", kStartNavigationType:"Start Navigating Route Siri Shortcut"]
    var siriShortcutsNameTypeDico: [String: Any]!
    var siriShortcutsTypeNameDico: [String: Any]!
    
    /// Intermediate anchor points
    var intermediateAnchorPoints:[RouteAnchorPoint] = []

    /// the name of the route being recorded
    var routeName: NSString?

    /// the route just recorded.  This is useful for when the user resumes a route that wasn't saved.
    var justTraveledRoute: SavedRoute?
    
    
    /// the most recently used map.  This helps us determine whether a route the user is attempting to load requires alignment.  If we have already aligned within a particular map, we can skip the alignment procedure.
    var justUsedMap : Any?
    
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
    
    /// update experiment flaags for single use route
    func updateExperiment(){
        
      
        
        if (currentCondition == "lanyard" ){
            experimentInstructionAlert(instruction:  String(format:NSLocalizedString( "lanyardInstruction" , comment:"experiment instruction" ),   siriShortcutTypeNameDictionary[kNewSingleUseRouteType] as! String, siriShortcutTypeNameDictionary[ kStopRecordingType] as! String, siriShortcutTypeNameDictionary[kStartNavigationType] as! String)
            )
        }
        if (currentCondition == "bracing" ){
            experimentInstructionAlert(instruction:
                                        String(format:NSLocalizedString( "bracingInstruction", comment:"experiment instruction" ),   siriShortcutTypeNameDictionary[kNewSingleUseRouteType] as! String, siriShortcutTypeNameDictionary[ kStopRecordingType] as! String, siriShortcutTypeNameDictionary[kStartNavigationType] as! String))
        }else{
            experimentInstructionAlert(instruction: String(format:NSLocalizedString( "contolledInstruction", comment:"experiment instruction" ),   siriShortcutTypeNameDictionary[kNewSingleUseRouteType] as! String, siriShortcutTypeNameDictionary[ kStopRecordingType] as! String, siriShortcutTypeNameDictionary[kStartNavigationType] as! String))
        }
        
    }
    
    
    /// update experiment flaags
    func updateExperimentExperimentRoute(){
        
        if (currentCondition == "lanyard" ){
            experimentInstructionAlert(instruction:  String(format: NSLocalizedString(
               "ExperimentRouteLanyardInstructions" , comment:"experiment instruction" ),siriShortcutTypeNameDictionary[  kExperimentRouteType] as! String, siriShortcutTypeNameDictionary[ kStopRecordingType] as! String)
            )
        }
        if (currentCondition == "bracing" ){
            experimentInstructionAlert(instruction:
                                        String(format:NSLocalizedString( "ExperimentRouteBracingInstructions", comment:"experiment instruction" ), siriShortcutTypeNameDictionary[  kExperimentRouteType] as! String, siriShortcutTypeNameDictionary[ kStopRecordingType] as! String))
        }else{
         
            experimentInstructionAlert(instruction: String(format:NSLocalizedString( "ExperimentRouteControlledInstructions" , comment:"experiment instruction" ), siriShortcutTypeNameDictionary[  kExperimentRouteType] as! String, siriShortcutTypeNameDictionary[ kStopRecordingType] as! String))
        }
        
    }
    
    
    /// handles the user pressing the record path button.
    @objc func recordPath() {
        ///PATHPOINT record two way path button -> create Anchor Point
        ///route has not been auto aligned
        isAutomaticAlignment = false
        ///tells the program that it is recording a two way route
        recordingSingleUseRoute = false
        recordingExperimentRoute = false
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
        if #available(iOS 12.0, *) {
            configuration.initialWorldMap = nil
        }
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    /// handles the user pressing the stop recording button.
    ///
    /// - Parameter sender: the button that generated the event
    @objc func stopRecording(_ sender: UIButton?) {
        // copy the recordingCrumbs over for use in path creation
        
        
        let activity = SiriShortcutsController.stopRecordingShortcut()
      
        self.userActivity = activity
        self.prevSiriActivity = kStopRecordingType
 
        
        activity.becomeCurrent()
        
        stopRecordingRouteShortcutWasPressed()
        
        crumbs = Array(recordingCrumbs)
        
        isResumedRoute = false

        rootContainerView.homeButton.isHidden = false // home button here
        resumeTrackingController.remove()
        resumeTrackingConfirmController.remove()
        stopRecordingController.remove()
        setShouldSuggestAdjustOffset()
        // heading offsets should not be updated from this point until route navigation starts
        updateHeadingOffsetTimer?.invalidate()
        recordPhaseHeadingOffsets = []

        print("insidestop")
      
        
        
        
  
        
   
        
        ///checks if the route is a single use route or a multiple use route
//        if !recordingSingleUseRoute {
//            ///PATHPOINT two way route recording finished -> create end Anchor Point
//            ///sets the variable tracking whether the route is paused to be false
//            print("Errrr")
//            paused = false
//            creatingRouteAnchorPoint = false
//            ///sends the user to the process where they create an end anchorpoint
//            state = .startingPauseProcedure
//        }
        if(recordingExperimentRoute){
            print("insideStop")
            let size = crumbs.count
            let first = crumbs[0]
            print("first")
            print(first)
            let last = crumbs[size-1]
            let distancecal = nav.getDistance(first: first, last: last)
            
            print("dist")
            print(cc)
            cc = cc + 1
            distance = distancecal
            //storeCrumbs = crumbs
            
           // UserDefaults.standard.setValue(distance ?? 0.0, forKey: "distance")
            print(distance)
            print("CEF")
            print(ViewController.sExperimentRouteFlag)
            if(ViewController.sExperimentRouteFlag){
                
            logger.logFrameDistance(distance: distance)
                sendLogExperimentRouteDataHelper(pathStatus: true)
                
            }else{
                    
                    sendLogDataHelper(pathStatus: true)
                }
            
            
//            self.state = .mainScreen(announceArrival: true)
//            let logFileURLs = logger.compileLogData(nil)
//            logger.resetStateSequenceLog()
            
        }else {
            ///PATHPOINT one way route recording finished -> play/pause
            state = .readyToNavigateOrPause(allowPause: false)
        }
        
    }
    func countCompleted()->Int{
        var count:Int = 0
        for (key, value) in conditionsDico{
            count =  value as! Int + count
        }
        for (key, value ) in experimentConditonsDico{
            count = value as! Int + count
        }
        return count
    }
    
    

    
    
    /// handles the user pressing the start navigation button.
    ///
    /// - Parameter sender: the button that generated the event
    @objc func startNavigation(_ sender: UIButton?) {
        
      
       
        
        ///announce to the user that return navigation has started.
        self.delayTransition(announcement: NSLocalizedString("startingReturnNavigationAnnouncement", comment: "This is an anouncement which is played when the user performs return navigation from the play pause menu. It signifies the start of a navigation session."), initialFocus: nil)
        
      
     
            
            let activity = SiriShortcutsController.startNavigationShortcut()
            self.userActivity = activity
        
            
            activity.becomeCurrent()
            startNavigationShortcutWasPressed()
        
        
        
        // this will handle the appropriate state transition if we pass the warning
        state = .navigatingRoute
    }
    
    @objc func startNavigation2() {
        
        let vcc =  ViewController()
 
        
        let activity = SiriShortcutsController.startNavigationShortcut()
      
        self.userActivity = activity
        print("siricheck2: inside startnav")
        print(activity.activityType)
 
        
        activity.becomeCurrent()
        
        startNavigationShortcutWasPressed()
       
        
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
        keypointNode.removeFromParentNode()
        pathObj?.removeFromParentNode()
//        pathpointObjs.map({$0.removeFromParentNode()})
//        pathpointObjs = []
        for anchorPointNode in anchorPointNodes {
            anchorPointNode.removeFromParentNode()
        }
        if(ViewController.sExperimentRouteFlag){
           sendLogExperimentSingleUseRouteDataHelper(pathStatus: nil)
            
        }else{
            sendLogDataHelper(pathStatus: nil)
        }
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
        //set experiment route to false
        recordingExperimentRoute = false
        // ensure adjustoffset is turned off
      
        if(siriShortcutExperimentRouteFlag && !setShortcutsDisplay){
            setShortcutsDisplay = true
          
            if(!voiceShortcuts.isEmpty){
                for element in voiceShortcuts{
                        ViewController.voiceCommandsList.append(shortCutInvocationPhasee(phase: element.invocationPhrase, type: element.shortcut.userActivity!.activityType))
                       print(element.invocationPhrase)
                    }
            for element in voiceShortcuts{

               print(element.invocationPhrase)
                siriShortcutDisplayList.append(element.invocationPhrase)
           
                
                siriShortcutsNameTypeDico[element.invocationPhrase] = element.shortcut.userActivity?.activityType
               
                                helpTypeNameDictionary [element.shortcut.userActivity?.activityType ?? "type"] = element.invocationPhrase
                
                self.siriShortcutNameTypeDictionary[element.invocationPhrase] = element.shortcut.userActivity?.activityType
                helpNameTypeDictionary[element.invocationPhrase] = element.shortcut.userActivity?.activityType
                print(siriShortcutsNameTypeDico[element.invocationPhrase])
            
            }
                
                UserDefaults.standard.setValue(siriShortcutDisplayList, forKey: "siriShortcutDisplayList")
                UserDefaults.standard.setValue(siriShortcutsNameTypeDico, forKey:  "siriShortcutsNameTypeDico")
               UserDefaults.standard.setValue( helpTypeNameDictionary, forKey: " siriShortcutsTypeNameDico")
                UserDefaults.standard.setValue(true, forKey: "siriShortcutExperimentRoute")
                UserDefaults.standard.set(helpNameTypeDictionary, forKey: "siriShortcutNameTypeDictionary")
                
                UserDefaults.standard.set(helpTypeNameDictionary, forKey: "siriShortcutTypeNameDictionary")
                siriShortcutNameTypeDictionary  =  UserDefaults.standard.object(forKey: "siriShortcutNameTypeDictionary")  as? [String:String] ?? [:]
                
                print("5get")
                print( siriShortcutNameTypeDictionary.count)
                print(siriShortcutTypeNameDictionary.count)
                logger.logSettings(siriShortcutTypeNameDictionary: siriShortcutTypeNameDictionary, siriShortcutNameTypeDictionary: siriShortcutNameTypeDictionary, defaultUnit: defaultUnit, defaultColor: defaultColor, soundFeedback: soundFeedback, voiceFeedback: voiceFeedback, hapticFeedback: hapticFeedback, sendLogs: sendLogs, timerLength: timerLength, currentRoute: currentRoute,adjustOffset: adjustOffset,
                                   currentCondition:currentCondition, experimentRouteFlag: experimentRouteFlag, experimentConditonsDico: experimentConditonsDico,
                                   conditionsDico: conditionsDico,siriShortcutDisplayList:siriShortcutDisplayList, siriShortcutsNameTypeDico: siriShortcutsNameTypeDico, siriShortcutsTypeNameDico :siriShortcutsTypeNameDico)
                
            }else{
                print("1get")
                print(siriShortcutNameTypeDictionary.count)
                print(siriShortcutTypeNameDictionary.count)
                siriShortcutDisplayList = unique(source: siriShortcutDisplayList! )
                for element in siriShortcutDisplayList {

                    ViewController.voiceCommandsList.append(shortCutInvocationPhasee(phase:element,type: siriShortcutTypeNameDictionary[element] ?? "_" ))

                }


            }

            print("lenAnch")
            print(siriShortcutDisplayList.count)
            print(siriShortcutsNameTypeDico.count)
       
            print(self.siriShortcutNameTypeDictionary.count)
           siriShortcutExperimentRouteFlag = true
          
            
            sendLogDataHelper(pathStatus: true)
        }
        rootContainerView.homeButton.isHidden = false
        creatingRouteAnchorPoint = true

        /// create an activity and attach it to the VC
       
        let activity = SiriShortcutsController.newSingleUseRouteShortcut()
      
        self.userActivity = activity
        
 
        
        activity.becomeCurrent()
        newSingleUseRouteShortcutWasPressed()
        

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
            print("users is sent to screen")
        }
        if #available(iOS 12.0, *) {
            configuration.initialWorldMap = nil
        }
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    
    ///Siri shortcuts
    
    
       func newSingleUseRouteShortcutWasPressed(){
        ////startNavigationShortcutWasPressed()
           let newSingleUseRouteActivity = SiriShortcutsController.newSingleUseRouteShortcut()
           let activity = SiriShortcutsController.newSingleUseRouteShortcut()
      
       
           
          // newSingleUseRouteActivity.state = .recordingRoute
           let shortcut = INShortcut(userActivity: activity)
           
           let vcc = INUIAddVoiceShortcutViewController(shortcut:shortcut)
               
         
           vcc.delegate = self
        print("adjustoffset flag")
        print(adjustOffset)
        //if(!siriShortcutSingleUseRouteFlag )
        let sudosirish = false
        if(!siriShortcutSingleUseRouteFlag){
            print("checkf5")
            print(siriShortcutSingleUseRouteFlag)
            present(vcc, animated: true, completion: nil)
            singleUseRouteExperimentFlag = false
            UserDefaults.standard.setValue(true, forKey: "siriShortcutSingleUseRoute")
            print(siriShortcutSingleUseRouteFlag)
            
        }
           
       }
    func experimentRouteShortcutWasPressed(){
        
        let activity = SiriShortcutsController.experimentRouteShortcut()
   
   
        let shortcut = INShortcut(userActivity: activity)
        
        let vcc = INUIAddVoiceShortcutViewController(shortcut:shortcut)
            
      
        vcc.delegate = self
        print("expPressed")
        print(!siriShortcutExperimentRouteFlag)
        
        if(!siriShortcutExperimentRouteFlag){
            present(vcc, animated: true, completion: nil)
            print("expLoop")
            dump(voiceShortcuts)
                    for element in voiceShortcuts{
                        ViewController.voiceCommandsList.append(shortCutInvocationPhasee(phase: element.invocationPhrase, type: element.shortcut.userActivity!.activityType))
                       print(element.invocationPhrase)
                    }
            
            
            for element in voiceShortcuts{
             
               print(element.invocationPhrase)
                siriShortcutDisplayList.append(element.invocationPhrase)
                print("inExpLoop")
                print(element.invocationPhrase)
                //print(element.shortcut.userActivity?.activityType)
                siriShortcutsNameTypeDico[element.invocationPhrase] = element.shortcut.userActivity?.activityType
                siriShortcutsTypeNameDico[element.shortcut.userActivity?.activityType ?? "type"] = element.invocationPhrase
                print(siriShortcutsNameTypeDico[element.invocationPhrase])
            }
            
            siriShortcutDisplayList = unique(source: siriShortcutDisplayList)
            print("lenExp")
            print(siriShortcutDisplayList.count)
            //print(siriShortcutsNameTypeDico.capacity)
            //siriShortcutExperimentRouteFlag = true
            UserDefaults.standard.setValue(siriShortcutDisplayList, forKey: "siriShortcutDisplayList")
            print("sNdico")
            print(siriShortcutsNameTypeDico.count)
            //UserDefaults.standard.setValue(siriShortcutsNameTypeDico, forKey:  "siriShortcutsNameTypeDico")
            UserDefaults.standard.setValue(true, forKey: "siriShortcutExperimentRoute")
        }
    }
    
    @objc func experimentProcedure() {
     // adjustOffset is turned off Ensure it's turned off
        UserDefaults.standard.set(false, forKey: "adjustOffset")
        
        self.recordingExperimentRoute = true
    
        rootContainerView.homeButton.isHidden = false
        creatingRouteAnchorPoint = true

        /// create an activity and attach it to the VC
       
        let activity = SiriShortcutsController.experimentRouteShortcut()
      
        self.userActivity = activity
        
 
        
        activity.becomeCurrent()
        experimentRouteShortcutWasPressed()

        ///the route has not been resumed automaticly from a saved route
        isAutomaticAlignment = false
        ///tell the program that a single use route is not being recorded
        recordingSingleUseRoute = false
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
            self.delayTransition(announcement: NSLocalizedString("experimentToRecordingRouteAnnouncement", comment: "This is an announcement which is spoken when the user starts recording a single use route. it informs the user that they are recording a single use route."), initialFocus: nil)

            //sends the user to the screen where they can start recording a route
            self.state = .recordingRoute
            print("users is sent to screen")
        }
        if #available(iOS 12.0, *) {
            configuration.initialWorldMap = nil
        }
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
   
    func stopRecordingRouteShortcutWasPressed(){
   
        
        let activity = SiriShortcutsController.stopRecordingShortcut()
        
        let shortcut = INShortcut(userActivity: activity)
        
        let vcc = INUIAddVoiceShortcutViewController(shortcut:shortcut)
            
        
        vcc.delegate = self
      //  present(vcc, animated: true, completion: nil)
        //siriShortcutExperimentRouteFlag
        if(!siriShortcutStopRecordingRouteFlag){
            present(vcc, animated: true, completion: nil)
            UserDefaults.standard.setValue(true, forKey: "siriShortcutStopRecordingRoute")
        }
            
    }
    
    @objc func participateInExperiment(){
        print("in Participate")
        if( !siriShortcutExperimentRouteFlag || !siriShortcutSingleUseRouteFlag || !siriShortcutStopRecordingRouteFlag || !siriShortcutStartNavigatingRouteFlag){
            ///Alert to inform users that they haven't enabled the specific shortcut
            showEnableSiriAlert()
            print("please enable shortcuts")
        }
        if(!singleUseRouteExperimentFlag && !experimentRouteFlag){
                  // start experiment
            ViewController.sExperimentRouteFlag = true
            print( ViewController.sRouteType )
            print( ViewController.sExperimentRouteFlag)
                  startExperiment()
              
        }else if (completedExperiment){
            // if completed present completed Alert
            print( ViewController.sRouteType )
            print( ViewController.sExperimentRouteFlag)
            showCompletedExperimentAlert()
        }
        else if (currentRoute as! String == "SingleUseRoute"){
            ViewController.sExperimentRouteFlag = true
            ViewController.sRouteType = currentRoute
            print( ViewController.sRouteType )
            print( ViewController.sExperimentRouteFlag)
            updateExperiment()
            
            
        }else {
            ViewController.sExperimentRouteFlag = true
            ViewController.sRouteType = currentRoute
            print( ViewController.sRouteType )
            print( ViewController.sExperimentRouteFlag)
            updateExperimentExperimentRoute()
            
           
            
        }
        
        
    }
    @objc func participateInExperimentWasPressed(){
        participateInExperiment()
    }
     @objc  func startNavigationShortcutWasPressed(){
        ///
           let newSingleUseRouteActivity = SiriShortcutsController.startNavigationShortcut()
           let activity = SiriShortcutsController.startNavigationShortcut()
      
           
           let shortcut = INShortcut(userActivity: activity)
           
           let vcc = INUIAddVoiceShortcutViewController(shortcut:shortcut)
               
         
           vcc.delegate = self
         
    //present(vcc, animated: true, completion: nil)
        let titlestr = shortcut.userActivity?.suggestedInvocationPhrase
        print(titlestr)
        type(of: titlestr)
        //   siriShortcutList.append(shortcut.userActivity.title!)
        print("dump")
        //dump(siriShortcutList)
        //print("extd")
        dump(voiceShortcuts)
     
        if(!siriShortcutStartNavigatingRouteFlag){
            present(vcc, animated: true, completion: nil)
            UserDefaults.standard.setValue(true, forKey: "siriShortcutStartNavigatingRoute")
       }
           
       }
    
    ///store unique values
    
    func unique<S : Sequence, T : Hashable>(source: S) -> [T] where S.Iterator.Element == T {
        var buffer = [T]()
        var added = Set<T>()
        for elem in source {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
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
        pauseTrackingController.remove()
        rootContainerView.countdownTimer.isHidden = false
        rootContainerView.countdownTimer.start(beginingValue: ViewController.alignmentWaitingPeriod, interval: 1)
        delayTransition()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(ViewController.alignmentWaitingPeriod)) {
            self.rootContainerView.countdownTimer.isHidden = true
            // The first check is necessary in case the phone relocalizes before this code executes
            if case .readyForFinalResumeAlignment = self.state, let alignTransform = self.pausedTransform, let camera = self.sceneView.session.currentFrame?.camera {
                // yaw can be determined by projecting the camera's z-axis into the ground plane and using arc tangent (note: the camera coordinate conventions of ARKit https://developer.apple.com/documentation/arkit/arsessionconfiguration/worldalignment/camera
                // add this call so we make sure that we log the alignment transform
                let _ = self.getRealCoordinates(record: true)
                let alignYaw = self.getYawHelper(alignTransform)
                let cameraYaw = self.getYawHelper(camera.transform)

                var leveledCameraPose = simd_float4x4.makeRotate(radians: cameraYaw, 0, 1, 0)
                leveledCameraPose.columns.3 = camera.transform.columns.3
                
                var leveledAlignPose =  simd_float4x4.makeRotate(radians: alignYaw, 0, 1, 0)
                leveledAlignPose.columns.3 = alignTransform.columns.3
                
                let relativeTransform = leveledCameraPose * leveledAlignPose.inverse
                self.sceneView.session.setWorldOrigin(relativeTransform: relativeTransform)
                
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
    
    /// handles the user pressing the resume tracking confirmation button.
    @objc func confirmResumeTracking() {
        if let route = justTraveledRoute {
            state = .startingResumeProcedure(route: route, worldMap: justUsedMap, navigateStartToEnd: false)
        }
    }
    
    func startExperiment(){
        ViewController.sRouteType = currentRoute
        print("2flagTrue")
        print(siriShortcutAlert && siriShortcutExperimentRouteFlag)
        
        print(
            !singleUseRouteExperimentFlag && !experimentRouteFlag)
        if(siriShortcutAlert && siriShortcutExperimentRouteFlag){
       
            print("inside Both not")
        
        if(currentRoute as! String == "SingleUseRoute"){
            
            updateExperiment()
            singleUseRouteExperimentFlag = true
            UserDefaults.standard.setValue( singleUseRouteExperimentFlag , forKey: "singleUseRouteExperimentFlag")
            
        }else {
            updateExperimentExperimentRoute()
            experimentRouteFlag = true
            UserDefaults.standard.setValue(experimentRouteFlag , forKey: "experimentRouteFlag")
            
        }
        
        }
            
    }
    
    
    // MARK: - Logging
    
    /// send log data for an successful route navigation (thumbs up)
    @objc func sendLogData() {
        sendLogDataHelper(pathStatus: true)
    }
    
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
        state = .mainScreen(announceArrival: announceArrival)
        if sendLogs {
            // do this in a little while to give it time to announce arrival
            print("ShowSurvey1")
//            DispatchQueue.main.asyncAfter(deadline: .now() + (announceArrival ? 3 : 1)) {
//                print("ShowSurvey2")
//                self.presentSurveyIfIntervalHasPassed(mode: "afterRoute", logFileURLs: logFileURLs)
//            }
        }
    }
    
    func sendLogExperimentSingleUseRouteDataHelper(pathStatus: Bool?, announceArrival: Bool = false) {
       
        state = .mainScreen(announceArrival: true)
        var prevConditionsCountsv = conditionsDico[currentCondition] as! Int
        var Condd = UserDefaults.standard.dictionary(forKey: "conditionsDico")
        var prevCondd = Condd![currentCondition]
        var prevC = ViewController.ConditionsCount
        // send success log data to Firebase
          logger.logCurrentExpCondition(condition: currentCondition)
          
          logger.logCurrentRoute(route: currentRoute)
//        if(!singleUseRouteExperimentFlag && !experimentRouteFlag){
//            print("inside startExp")
//            startExperiment()
//        }
         if(currentCondition == "lanyard"){
            showRedoRoutesSuggestion(condition: currentCondition, content: "lanyardRedoContent")
            print("in redo if")
            print(ViewController.ConditionsCount = conditionsDico[currentCondition] as! Int)
        }
         if(currentCondition == "none"){
            showRedoRoutesSuggestion(condition: currentCondition, content: "controlledRedoContent")
            print("in redo if")
            print(ViewController.ConditionsCount = conditionsDico[currentCondition] as! Int)
            
        }
         if(currentCondition == "bracing"){
            
            showRedoRoutesSuggestion(condition: currentCondition, content: "bracingRedoContent")
            print("in redo if")
            print(ViewController.ConditionsCount = conditionsDico[currentCondition] as! Int)
        }
        
        
        print("currentCondition")
        print(currentCondition)
        
        print(conditionsDico[currentCondition])
       
               print(ViewController.ConditionsCount)
              
        print(prevConditionsCountsv)
        print(prevC)
        print(prevCondd)
        let test = 0
        if(test == 0){
            print("checkf")
        }
        //only log if user confirmed completion of route
        if(prevConditionsCountsv !=   ViewController.ConditionsCount ){
        // send success log data to Firebase
            print("fromv")
            print(ViewController.ConditionsCount)
            let prevConditionsCounts =  conditionsDico[currentCondition] as! Int
            print(prevConditionsCounts)
            print(conditionsDico[currentCondition] as! Int)
            
        let logFileURLs = logger.compileLogData(pathStatus)
        logger.resetStateSequenceLog()
          
        // left
            var left : [String] = []
        
            for( key) in conditionsDico.keys{
                if( conditionsDico[key] as! Int == 0){
                    left.append(key)}
                
                
            }
            if(left.isEmpty){
                
                if(!experimentRouteFlag){
                updateExperimentExperimentRoute()
                currentRoute = "ExperimentRoute"
                experimentRouteFlag = true
                 UserDefaults.standard.setValue(currentRoute, forKey: "currentRoute")
                UserDefaults.standard.setValue(experimentRouteFlag, forKey: "experimentRouteFlag")
                }else{
                    showCompletedExperimentAlert()
                    print("completedExperiment")
                    
                }
            }
        if(conditionsDico[currentCondition]! as! Int == 3){
       // if(ViewController.ConditionsCount == 3){
            print("insideIf 1")
            nextCondition = left.randomElement()
            if(conditionsDico[nextCondition]! as! Int == 0){
                print("insideIf 2")
                print("inSendlog")
                print("updateNext")
            
                
                currentCondition = nextCondition
                UserDefaults.standard.setValue(currentCondition, forKey: "currentCondition")
               
                
                updateExperiment()
                
            }
        }
        
        
        if sendLogs {
            // do this in a little while to give it time to announce arrival
            
           
//            DispatchQueue.main.asyncAfter(deadline: .now() + (announceArrival ? 3 : 1)) {
//                self.presentSurveyIfIntervalHasPassed(mode: "afterRoute", logFileURLs: logFileURLs)
//            }
        }
        }
    }
    
    
    ///store route logs and preent survey.  if the condtions has been satisfied, move to the next condition and present the route. if the phase has been completed, move to the experiment phase or end.
    ///
    func sendLogSinglueUseRoute(){
        
        
        //only log if user confirmed completion of route
       
        // send success log data to Firebase
        var presentSurvey: Bool = false
        
        let logFileURLs = logger.compileLogData(true)
        logger.resetStateSequenceLog()
          
        // left
            var left : [String] = []
        
            for( key) in conditionsDico.keys{
                if(conditionsDico[key] as! Int != 3){
                    left.append(key)}
                
                
            }
            
            if(left.isEmpty){
                print("left is empty")
                print("val o")
                presentSurvey = true
                if(!experimentRouteFlag){
                //updateExperimentExperimentRoute()
                print("gon next ")
                currentRoute = "ExperimentRoute"
                 UserDefaults.standard.setValue(currentRoute, forKey: "currentRoute")
                experimentRouteFlag = true
                UserDefaults.standard.setValue(experimentRouteFlag, forKey: "experimentRouteFlag")
                }else{
                    completedExperiment = true
                    showCompletedExperimentAlert()
                    UserDefaults.standard.setValue(completedExperiment, forKey: "completedExperiment")
                    print("completedExperiment")
                }
            }
        else{
      
            //
            presentSurvey = true
           
            dump(left)
            let nextCondition = left.randomElement()
            print(nextCondition)
            if(conditionsDico[currentCondition]! as! Int == 3){
            if(conditionsDico[nextCondition ?? "none"]! as! Int == 0){
             print("next")
            print(nextCondition)
                
                currentCondition = nextCondition
                print("update")
                UserDefaults.standard.setValue(currentCondition, forKey: "currentCondition")
               
                
                //updateExperiment()
                
            }
        }
        
        }
        
        let wait: Bool = true
        print("current")
        print(currentCondition)
        print(conditionsDico)
        if (sendLogs && presentSurvey) {
            print("should present survey")
            // do this in a little while to give it time
            
           
//            DispatchQueue.main.asyncAfter(deadline: .now() + (wait ? 1 : 1)) {
//                self.presentSurveyIfIntervalHasPassed(mode: "afterRoute", logFileURLs: logFileURLs)
//            }
        }
        
    }
    
    
    func sendLogExperimentRouteDataHelper(pathStatus: Bool?, announceArrival: Bool = true) {
       print("in sendLogExperimentRouteDataHelper( ")
        state = .mainScreen(announceArrival: announceArrival)
        let prevConditionsCounts = ViewController.ConditionsCount
        
        if(!singleUseRouteExperimentFlag! && !experimentRouteFlag){
            print("inside move Next")
            startExperiment()
        }
        if(currentCondition == "lanyard"){
            
            showRedoExperimentRoutesSuggestion(condition: currentCondition, content: "lanyardRedoContent")
         
            
        }
        if(currentCondition == "none"){
             showRedoExperimentRoutesSuggestion(condition: currentCondition, content: "controlledRedoContent")
            
            
        }
        if(currentCondition == "bracing"){
            
            showRedoExperimentRoutesSuggestion(condition: currentCondition, content: "bracingRedoContent")
            
          
            
        }
        
        
        print("currentCondition")
        print(currentCondition)
        print(self.experimentConditonsDico[currentCondition])
        
       
        
      
        print("prev")
        print(prevConditionsCounts)
        print("current")
        print( ViewController.ConditionsCount
        )
          
        //only log if user confirmed completion of route
        if(prevConditionsCounts as! Int !=   ViewController.ConditionsCount ){
            print("insideSendLog")
        // send success log data to Firebase
        let logFileURLs = logger.compileLogData(pathStatus)
        logger.resetStateSequenceLog()
          
            
            // left
                var left : [String] = []
            
                for(key) in experimentConditonsDico.keys{
                    if( experimentConditonsDico[key] as! Int > 3){
                        left.append(key)}
                    
                    
                }
                if(left.isEmpty){
                    
                    if(!singleUseRouteExperimentFlag!){
                    updateExperiment()
                    currentRoute = "SingleUseRoute"
                     UserDefaults.standard.setValue(currentRoute, forKey: "currentRoute")
                    UserDefaults.standard.setValue(true, forKey: "singleUseRouteExperimentFlag")
                    }else{
                        print("completedExperiment")
                        
                    }
                }
        
        if(experimentConditonsDico[currentCondition]! as! Int == 3){
        //if(ViewController.ConditionsCount == 3){
            print("insideIf 1")
            print("eq3")
            nextCondition = left.randomElement()
            if(experimentConditonsDico[nextCondition]! as! Int == 0){
                print("insideIf 2")
                print("inSendlog")
                print("updateNext")
            
                
                currentCondition = nextCondition
                UserDefaults.standard.setValue(currentCondition, forKey: "currentCondition")
               
                
               updateExperimentExperimentRoute()
                
            }
        }
        
        
        if sendLogs {
            // do this in a little while to give it time to announce arrival
            
           
            //DispatchQueue.main.asyncAfter(deadline: .now() + (announceArrival ? 3 : 1)) {
                //self.presentSurveyIfIntervalHasPassed(mode: "afterRoute", logFileURLs: logFileURLs)
          //  }
        }
        }
    }
   
    /// this function sends logs of the experiment rotue to firebase when the user confirms the completion of route using the required condition
    func sendExpRouteLog(){
        

      //only log if user confirmed completion of route
    
          
      // send success log data to Firebase
        logger.logCurrentExpCondition(condition: currentCondition)
        logger.logCurrentRoute(route: currentRoute)
        logger.logExpDico(dico: experimentConditonsDico)
        let logFileURLs = logger.compileLogData(true)
        logger.resetStateSequenceLog()
        print(" in sendExpRouteLog")
        print("sendLog")
        print(sendLogs)
          
          // determine which conditions are to be completed
              var left : [String] = []
          
              for(key) in experimentConditonsDico.keys{
                  if( experimentConditonsDico[key] as! Int != 3){
                      left.append(key)}
                  
                  
              }
        print("left")
        dump(left)
              if(left.isEmpty){
               
                  
                if(!(singleUseRouteExperimentFlag ?? false)) {
                  //updateExperiment()
                    print("go singluse")
                currentRoute = "SingleUseRoute"
                  UserDefaults.standard.setValue(currentRoute, forKey: "currentRoute")
                  UserDefaults.standard.setValue(true, forKey: "singleUseRouteExperimentFlag")
                  }else{
                    showCompletedExperimentAlert()
                    completedExperiment = true
                    UserDefaults.standard.setValue(completedExperiment, forKey: "completedExperiment")
                    print("completedExperiment")
                      
                  }
              }
      
     else{
     
        if(experimentConditonsDico[currentCondition]! as! Int == 3){
          
          print("eq3")
          print("next condition")
          nextCondition = left.randomElement()
        print(nextCondition)
          if(experimentConditonsDico[nextCondition]! as! Int == 0){
              
              print("updateNext")
          
              
              currentCondition = nextCondition
              UserDefaults.standard.setValue(currentCondition, forKey: "currentCondition")
             
              
             //updateExperimentExperimentRoute()
              
          }}
      
      
      }
        
      
        
    }
        
    /// drop a crumb during path recording
    @objc func dropCrumb() {
        guard let curLocation = getRealCoordinates(record: true)?.location else {
            return
        }
        recordingCrumbs.append(curLocation)
    }
    
    /// checks to see if user is on the right path during navigation.
    @objc func followCrumb() {
        guard let curLocation = getRealCoordinates(record: true) else {
            // TODO: might want to indicate that something is wrong to the user
            return
        }
        var directionToNextKeypoint = getDirectionToNextKeypoint(currentLocation: curLocation)
        
        if (directionToNextKeypoint.targetState == PositionState.atTarget) {
            if (keypoints.count > 1) {
                // arrived at keypoint
                // send haptic/sonic feedback
                waypointFeedbackGenerator?.notificationOccurred(.success)
                if (soundFeedback) { playSystemSound(id: 1016) }
                
                // remove current visited keypont from keypoint list
                prevKeypointPosition = keypoints[0].location
                keypoints.remove(at: 0)
                
                // erase current keypoint and render next keypoint node
                keypointNode.removeFromParentNode()
                renderKeypoint(keypoints[0].location)
                
                // erase current path and render next path
                if (showPath) {
                    pathObj?.removeFromParentNode()
                    renderPath(prevKeypointPosition, keypoints[0].location)
                }
                
                // erase current set of pathpoints and render next
//                pathpointObjs.map({$0.removeFromParentNode()})
//                pathpointObjs = []
//                renderPathpoints(prevKeypointPosition, keypoints[0].location)
                
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
                pathObj?.removeFromParentNode()
//                pathpointObjs.map({$0.removeFromParentNode()})
//                pathpointObjs = []
                for anchorPointNode in anchorPointNodes {
                    anchorPointNode.removeFromParentNode()
                }
                
                followingCrumbs?.invalidate()
                hapticTimer?.invalidate()
                
                if(ViewController.sExperimentRouteFlag){
                    sendLogExperimentSingleUseRouteDataHelper(pathStatus: true)}
                else{
                sendLogDataHelper(pathStatus: nil, announceArrival: true)
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
        updateHeadingOffset()
        guard let curLocation = getRealCoordinates(record: false) else {
            // TODO: might want to indicate that something is wrong to the user
            return
        }
        let directionToNextKeypoint = getDirectionToNextKeypoint(currentLocation: curLocation)
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
            let timeInterval = feedbackTimer.timeIntervalSinceNow
            if(-timeInterval > ViewController.FEEDBACKDELAY) {
                // wait until desired time interval before sending another feedback
                if (hapticFeedback) { feedbackGenerator?.impactOccurred() }
                if (soundFeedback) { playSystemSound(id: 1103) }
                feedbackTimer = Date()
            }
        }
        for anchorPoint in intermediateAnchorPoints {
            guard let anchorPointTransform = anchorPoint.transform else {
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
    
    /// TODO
    func renderIntermediateAnchorPoints() {
        for intermediateAnchorPoint in intermediateAnchorPoints {
            guard let transform = intermediateAnchorPoint.transform else {
                continue
            }
            // render SCNNode of given keypoint
            let anchorPointNode = SCNNode(mdlObject: speakerObject)
            // configure node attributes
            anchorPointNode.scale = SCNVector3(0.02, 0.02, 0.02)
            anchorPointNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            anchorPointNode.position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            // I don't think yaw really matters here (so we are putting 0 where we used to have location.yaw
            anchorPointNode.rotation = SCNVector4(0, 1, 0, (0 - Float.pi/2))
            
            let bound = SCNVector3(
                x: anchorPointNode.boundingBox.max.x - anchorPointNode.boundingBox.min.x,
                y: anchorPointNode.boundingBox.max.y - anchorPointNode.boundingBox.min.y,
                z: anchorPointNode.boundingBox.max.z - anchorPointNode.boundingBox.min.z)
            anchorPointNode.pivot = SCNMatrix4MakeTranslation(0, bound.y / 2, 0)
            let spin = CABasicAnimation(keyPath: "rotation")
            spin.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: 0))
            spin.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float(CGFloat(2 * Float.pi))))
            spin.duration = 3
            spin.repeatCount = .infinity
            anchorPointNode.addAnimation(spin, forKey: "spin around")

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
            // set flashing color based on settings bundle configuration
            let changeColor = SCNAction.repeatForever(flashBlue)
            // add keypoint node to view
            anchorPointNode.runAction(changeColor)
            anchorPointNodes.append(anchorPointNode)
            sceneView.scene.rootNode.addChildNode(anchorPointNode)
        }
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
    
    /// Create the path SCNNode that corresponds to the long translucent bar element that looks like a route path.
    /// - Parameters:
    ///  - locationFront: the location of the keypoint user is approaching
    ///  - locationBack: the location of the keypoint user is currently at
    func renderPath(_ locationFront: LocationInfo, _ locationBack: LocationInfo) {
        
        let x = (locationFront.x + locationBack.x) / 2
        let y = (locationFront.y + locationBack.y) / 2
        let z = (locationFront.z + locationBack.z) / 2
        let xDist = locationFront.x - locationBack.x
        let yDist = locationFront.y - locationBack.y
        let zDist = locationFront.z - locationBack.z
        let pathDist = sqrt(pow(xDist, 2) + pow(yDist, 2) + pow(zDist, 2))
        
        // render SCNNode of given keypoint
        pathObj = SCNNode(geometry: SCNBox(width: CGFloat(pathDist), height: 0.25, length: 0.08, chamferRadius: 3))
        
        let colors = [UIColor.red, UIColor.green, UIColor.blue]
        var color: UIColor!
        // set color based on settings bundle configuration
        if (defaultPathColor == 3) {
            color = colors[Int(arc4random_uniform(3))]
        } else {
            color = colors[defaultPathColor]
        }
        pathObj?.geometry?.firstMaterial!.diffuse.contents = color
        let xAxis = simd_normalize(simd_float3(xDist, yDist, zDist))
        let yAxis: simd_float3
        if xDist == 0 && zDist == 0 {
            // this is the case where the path goes straight up and we can set yAxis more or less arbitrarily
            yAxis = simd_float3(1, 0, 0)
        } else if xDist == 0 {
            // zDist must be non-zero, which means that for yAxis to be perpendicular to the xAxis and have a zero y-component, we must make yAxis equal to simd_float3(1, 0, 0)
            yAxis = simd_float3(1, 0, 0)
        } else if zDist == 0 {
            // xDist must be non-zero, which means that for yAxis to be perpendicular to the xAxis and have a zero y-component, we must make yAxis equal to simd_float3(0, 0, 1)
            yAxis = simd_float3(0, 0, 1)
        } else {
            // TODO: real math
            let yAxisZComponent = sqrt(1 / (zDist*zDist/(xDist*xDist) + 1))
            let yAxisXComponent = -zDist*yAxisZComponent/xDist
            yAxis = simd_float3(yAxisXComponent, 0, yAxisZComponent)
        }
        let zAxis = simd_cross(xAxis, yAxis)
        
        let pathTransform = simd_float4x4(columns: (simd_float4(xAxis, 0), simd_float4(yAxis, 0), simd_float4(zAxis, 0), simd_float4(x, y - 0.6, z, 1)))
        // configure node attributes
        pathObj!.opacity = CGFloat(0.7)
        pathObj!.simdTransform = pathTransform
        
        sceneView.scene.rootNode.addChildNode(pathObj!)
    }
    
    /// Create several spherical SCNNodes that make up a dotted route path.
    /// - Parameters:
    ///  - locationFront: the location of the keypoint user is approaching
    ///  - locationBack: the location of the keypoint user is currently at
    func renderPathpoints(_ locationFront: LocationInfo, _ locationBack: LocationInfo) {
        
        let xDist = locationFront.x - locationBack.x
        let yDist = locationFront.y - locationBack.y
        let zDist = locationFront.z - locationBack.z
        let pathDist = sqrt(pow(xDist, 2) + pow(yDist, 2) + pow(zDist, 2))
        print(pathDist)
        var numPathpoints = Int(pathDist / 0.5)

        if (numPathpoints == 0) {
            numPathpoints = 1
        }

//         configure attributes for each node
        for index in 1...numPathpoints {
            
            print("Index: ", index)
            // render SCNNode of given keypoint
            let pathpointObj = SCNNode(geometry: SCNSphere(radius: 0.07))
            pathpointObj.geometry?.firstMaterial!.diffuse.contents = UIColor.blue
            pathpointObj.opacity = CGFloat(0.7)
            
            let pointDist = (pathDist / Float(numPathpoints+1)) * Float(index)
            let ratio = pointDist/pathDist
            let x = locationBack.x + ratio * xDist
            let y = locationBack.y + ratio * yDist
            let z = locationBack.z + ratio * zDist
            pathpointObj.position = SCNVector3(x, y - 0.6, z)
            pathpointObjs.append(pathpointObj)
            sceneView.scene.rootNode.addChildNode(pathpointObj)
            print("Here ", index)
        }
        
    }
    
    /// Compute the location of the device based on the ARSession.  If the record flag is set to true, record this position in the logs.
    ///
    /// - Parameter record: a Boolean indicating whether to record the computed position (true if it should be computed, false otherwise)
    /// - Returns: the current location as a `CurrentCoordinateInfo` object
    func getRealCoordinates(record: Bool) -> CurrentCoordinateInfo? {
        guard let currTransform = sceneView.session.currentFrame?.camera.transform else {
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
    
    /// Called when there is a change in tracking state.  This is important for both announcing tracking errors to the user and also to triggering some app state transitions.
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
            
            if #available(iOS 12.0, *), configuration.initialWorldMap != nil, attemptingRelocalization {
                // This call is necessary to cancel any pending setWorldOrigin call from the alignment procedure.  Depending on timing, it's possible for the relocalization *and* the realignment to both be applied.  This results in the origin essentially being shifted twice and things are then way off
                session.setWorldOrigin(relativeTransform: matrix_identity_float4x4)
                if !suppressTrackingWarnings {
                    announce(announcement: NSLocalizedString("realignToSavedRouteAnnouncement", comment: "An announcement which lets the user know that their surroundings have been matched to a saved route"))
                }
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
            if case .readyForFinalResumeAlignment = state {
                // this will cancel any realignment if it hasn't happened yet and go straight to route navigation mode
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
        if case .recordingRoute = state {
            guard let currentTransform = sceneView.session.currentFrame?.camera.transform else {
                print("can't properly save Anchor Point since AR session is not running")
                return
            }
            let noteAnchorPoint = RouteAnchorPoint()
            noteAnchorPoint.voiceNote = audioFileURL.lastPathComponent as NSString
            noteAnchorPoint.transform = currentTransform
            intermediateAnchorPoints.append(noteAnchorPoint)
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


extension ViewController: INUIAddVoiceShortcutViewControllerDelegate {

    func addVoiceShortcutViewController(
      _ controller: INUIAddVoiceShortcutViewController,
      didFinishWith voiceShortcut: INVoiceShortcut?,
      error: Error?
    ) {
        updateVoiceShortcuts(completion: nil)
        print("extdel")
        dump(voiceShortcut)
        var shortcutStrings: [String]! = []
        
        for element in voiceShortcuts{
            ViewController.voiceCommandsList.append(shortCutInvocationPhasee(phase: element.invocationPhrase, type: element.shortcut.userActivity!.activityType))
            print(element.invocationPhrase)
            siriShortcutDisplayList.append(element.invocationPhrase)
            print(element.invocationPhrase)
                 //print(element.shortcut.userActivity?.activityType)
                 siriShortcutsNameTypeDico[element.invocationPhrase] = element.shortcut.userActivity?.activityType
                 siriShortcutsTypeNameDico[element.shortcut.userActivity?.activityType ?? "type"] = element.invocationPhrase
          
          
        }
     
     
        UserDefaults.standard.setValue(siriShortcutDisplayList, forKey: "siriShortcutDisplayList")
        UserDefaults.standard.setValue(siriShortcutsTypeNameDico, forKey: "siriShortcutsTypeNameDico")
        UserDefaults.standard.setValue(siriShortcutsNameTypeDico, forKey:  "siriShortcutsNameTypeDico")
        dismiss(animated: true, completion: nil)

    }

    // Function For cancellation

    func addVoiceShortcutViewControllerDidCancel(
      _ controller: INUIAddVoiceShortcutViewController) {
        dismiss(animated: true, completion: nil)

    }


//end of extensin
}


class UISurveyHostingController: UIHostingController<FirebaseFeedbackSurvey> {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.view)
        }
    }
}
