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


// MARK: Extensions
extension UIView {
    /// Used to identify the mainText UILabel
    static let mainTextTag: Int = 1001
    static let pauseButtonTag: Int = 1002
    static let readVoiceNoteButtonTag: Int = 1003

    /// Custom fade used for direction text UILabel.
    func fadeTransition(_ duration:CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.push
        animation.subtype = CATransitionSubtype.fromTop
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
    
    /// Configures a button container view and adds a button.
    ///
    /// - Parameter buttonComponents: holds information about the button to add
    ///
    func setupButtonContainer(withButtons buttonComponents: [ActionButtonComponents],
                              withMainText mainText: String? = nil) {
        self.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        self.isHidden = true

        if let mainText = mainText {
            let label = UILabel(frame: CGRect(x: 15, y: UIScreen.main.bounds.size.height/5, width: UIScreen.main.bounds.size.width-30, height: UIScreen.main.bounds.size.height/2))
            label.textColor = UIColor.white
            label.textAlignment = .center
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.font = label.font.withSize(20)

            label.text = mainText
            label.tag = UIView.mainTextTag
            self.addSubview(label)
        }
        for components in buttonComponents {
            let button = UIButton.makeImageButton(self, components)
            self.addSubview(button)
        }
    }
    var mainText: UILabel? {
        for subview in subviews {
            if subview.tag == UIView.mainTextTag, let textLabel = subview as? UILabel {
                return textLabel
            }
        }
        return nil
    }
    
    func getButtonByTag(tag: Int)->UIButton? {
        for subview in subviews {
            if subview.tag == tag, let button = subview as? UIButton {
                return button
            }
        }
        return nil
    }
}

extension UIButton {
    
    /// Factory to make an image button.
    ///
    /// Used for start and stop recording and navigation buttons.
    ///
    /// - Parameters:
    ///   - containerView: button container, configured with `UIView.setupButtonContainer(withButton:)`
    ///   - buttonViewParts: holds information about the button (image, label, and target)
    /// - Returns: A formatted button
    ///
    /// - SeeAlso: `UIView.setupButtonContainer(withButton:)`
    ///
    /// - TODO:
    ///   - Implement AutoLayout
    static func makeImageButton(_ containerView: UIView, _ buttonViewParts: ActionButtonComponents) -> UIButton {
        let buttonWidth = containerView.bounds.size.width / 3.75
        
        let button = UIButton(type: .custom)
        button.tag = buttonViewParts.tag
        button.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: buttonWidth)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        switch buttonViewParts.alignment {
        case .center:
            button.center.x = containerView.center.x
        case .right:
            button.center.x = containerView.center.x + UIScreen.main.bounds.size.width/3
        case .rightcenter:
            button.center.x = containerView.center.x + UIScreen.main.bounds.size.width/4.5
        case .left:
            button.center.x = containerView.center.x - UIScreen.main.bounds.size.width/3
        case .leftcenter:
            button.center.x = containerView.center.x - UIScreen.main.bounds.size.width/4.5
        }
        if containerView.mainText != nil {
            button.center.y = containerView.bounds.size.height * (8/10)
        } else {
            button.center.y = containerView.bounds.size.height * (6/10)
        }
        
        switch buttonViewParts.appearance {
        case .imageButton(let image):
            button.setImage(image, for: .normal)
        case .textButton(let label):
            button.setTitle(label, for: .normal)
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.white.cgColor
        }
        
        button.accessibilityLabel = buttonViewParts.label
        button.addTarget(nil, action: buttonViewParts.targetSelector, for: .touchUpInside)
        
        return button
    }
}

// Neat way of storing the selectors for all the targets we use.
// Source: https://medium.com/swift-programming/swift-selector-syntax-sugar-81c8a8b10df3
fileprivate extension Selector {
    static let recordPathButtonTapped = #selector(ViewController.recordPath)
    static let stopRecordingButtonTapped = #selector(ViewController.stopRecording)
    static let startNavigationButtonTapped = #selector(ViewController.startNavigation)
    static let stopNavigationButtonTapped = #selector(ViewController.stopNavigation)
    static let landmarkButtonTapped = #selector(ViewController.startCreateLandmarkProcedure)
    static let pauseButtonTapped = #selector(ViewController.startPauseProcedure)
    static let thumbsUpButtonTapped = #selector(ViewController.sendLogData)
    static let thumbsDownButtonTapped = #selector(ViewController.sendDebugLogData)
    static let resumeButtonTapped = #selector(ViewController.confirmResumeTracking)
    static let confirmAlignmentButtonTapped = #selector(ViewController.confirmAlignment)
    static let routesButtonTapped = #selector(ViewController.routesButtonPressed)
    static let enterLandmarkDescriptionButtonTapped = #selector(ViewController.showLandmarkInformationDialog)
    static let recordVoiceNoteButtonTapped = #selector(ViewController.recordVoiceNote)
    static let readVoiceNoteButtonTapped = #selector(ViewController.readVoiceNote)
}

/// Holds information about the buttons that are used to control navigation and tracking.
///
/// These button attributes are the only ones unique to each of these buttons.
public struct ActionButtonComponents {
    
    /// The appearance of the button.
    enum Appearance {
        /// An image button appears using the specified UIImage
        case imageButton(image: UIImage)
        /// A text button appears using the specified text label
        case textButton(label: String)
    }
    
    /// How to align the button horizontally within the button frame
    enum ButtonContainerHorizontalAlignment {
        /// put the button in the center
        case center
        /// put the button right of center
        case rightcenter
        /// put the button to the right
        case right
        /// put the button left of center
        case leftcenter
        /// put the button to the left
        case left
    }

    /// Button apperance (image or text)
    var appearance: Appearance
    
    /// Accessibility label
    var label: String
    
    /// Function to call when the button is tapped
    ///
    /// - TODO: Potentially unnecessary when the transitioning between views is refactored.
    var targetSelector: Selector
    
    /// The horizontal alignment within the button container
    var alignment: ButtonContainerHorizontalAlignment
    
    /// Tag to use to identify the button if we need to interact with it later.  Pass 0 if no subsequent interaction is required.
    var tag: Int
}

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
    case startingResumeProcedure(route: SavedRoute, mapAsAny: Any?, navigateStartToEnd: Bool)
    /// the AR session has entered the relocalizing state, which means that we can now realign the session
    case readyForFinalResumeAlignment
    
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
        case .startingResumeProcedure(_, _, let navigateStartToEnd):
            return "startingResumeProcedure(route=notloggedhere, map=notlogged, navigateStartToEnd=\(navigateStartToEnd))"
        case .readyForFinalResumeAlignment:
            return "readyForFinalResumeAlignment"
        }
    }
}

/// The view controller that handles the main Clew window.  This view controller is always active and handles the various views that are used for different app functionalities.
class ViewController: UIViewController, ARSCNViewDelegate, SRCountdownTimerDelegate, AVSpeechSynthesizerDelegate {
    
    // MARK: - Refactoring UI definition
    
    // MARK: Properties and subview declarations
    
    /// How long to wait (in seconds) between the alignment request and grabbing the transform
    static let alignmentWaitingPeriod = 5
    
    /// The state of the ARKit tracking session as last communicated to us through the delgate protocol.  This is useful if you want to do something different in the delegate method depending on the previous state
    var trackingSessionState : ARCamera.TrackingState?
    
    /// The state of the app.  This should be constantly referenced and updated as the app transitions
    var state = AppState.initializing {
        didSet {
            logger.logStateTransition(newState: state)
            switch state {
            case .recordingRoute:
                handleStateTransitionToRecordingRoute()
            case .readyToNavigateOrPause:
                handleStateTransitionToReadyToNavigateOrPause(allowPause: !isResumedRoute)
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
            case .startingResumeProcedure(let route, let mapAsAny, let navigateStartToEnd):
                handleStateTransitionToStartingResumeProcedure(route: route, mapAsAny: mapAsAny, navigateStartToEnd: navigateStartToEnd)
            case .readyForFinalResumeAlignment:
                // nothing happens currently
                break
            case .initializing:
                break
            }
        }
    }

    /// When VoiceOver is not active, we use AVSpeechSynthesizer for speech feedback
    let synth = AVSpeechSynthesizer()
    
    /// The announcement that is currently being read.  If this is nil, that implies nothing is being read
    var currentAnnouncement: String?
    
    /// The announcement that should be read immediately after this one finishes
    var nextAnnouncement: String?
    
    /// A boolean that tracks whether or not to suppress tracking warnings.  By default we don't suppress, but when the help popover is presented we do.
    var suppressTrackingWarnings = false
    
    /// This Boolean marks whether or not the pause procedure is being used to create a landmark at the start of a route (true) or if it is being used to pause an already recorded route
    var creatingRouteLandmark: Bool = false
    
    /// This Boolean marks whether or not the user is resuming a route
    var isResumedRoute: Bool = false
    
    /// Set to true when the user is attempting to load a saved route that has a map associated with it. Once relocalization succeeds, this flag should be set back to false
    var attemptingRelocalization: Bool = false
    
    /// This is an audio player that queues up the voice note associated with a particular route landmark. The player is created whenever a saved route is loaded. Loading it before the user clicks the "Play Voice Note" button allows us to call the prepareToPlay function which reduces the latency when the user clicks the "Play Voice Note" button.
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
    
    /// Handler for the mainScreen app state
    ///
    /// - Parameter announceArrival: a Boolean that indicates whether the user's arrival should be announced (true means the user has arrived)
    func handleStateTransitionToMainScreen(announceArrival: Bool) {
        showRecordPathButton(announceArrival: announceArrival)
    }
    
    /// Handler for the recordingRoute app state
    func handleStateTransitionToRecordingRoute() {
        // records a new path
        
        // make sure to never record a path with a transform set
        sceneView.session.setWorldOrigin(relativeTransform: simd_float4x4.makeTranslation(0, 0, 0))
        attemptingRelocalization = false
        
        crumbs = []
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
    
    /// Handler for the navigatingRoute app state
    func handleStateTransitionToNavigatingRoute() {
        // navigate the recorded path

        // If the route has not yet been saved, we can no longer save this route
        routeName = nil
        beginRouteLandmark = RouteLandmark()
        endRouteLandmark = RouteLandmark()

        logger.resetNavigationLog()

        // generate path from PathFinder class
        // enabled hapticFeedback generates more keypoints
        let path = PathFinder(crumbs: crumbs.reversed(), hapticFeedback: hapticFeedback, voiceFeedback: voiceFeedback)
        keypoints = path.keypoints
        
        // save keypoints data for debug log
        logger.logKeypoints(keypoints: keypoints)
        
        // render 3D keypoints
        renderKeypoint(keypoints[0].location)
        
        turnWarning = false
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
    ///   - mapAsAny: the world map to use (expressed as `Any?` since it is optional and we want to maintain backwards compatibility with iOS 11.3)
    ///   - navigateStartToEnd: a Boolean that is true if we want to navigate from the start to the end and false if we want to navigate from the end to the start.
    func handleStateTransitionToStartingResumeProcedure(route: SavedRoute, mapAsAny: Any?, navigateStartToEnd: Bool) {
        // load the world map and restart the session so that things have a chance to quiet down before putting it up to the wall
        let isTrackingPerformanceNormal: Bool
        if case .normal? = sceneView.session.currentFrame?.camera.trackingState {
            isTrackingPerformanceNormal = true
        } else {
            isTrackingPerformanceNormal = false
        }
        
        var isSameMap = false
        if #available(iOS 12.0, *) {
            let map = mapAsAny as! ARWorldMap?
            isSameMap = configuration.initialWorldMap != nil && configuration.initialWorldMap == map
            configuration.initialWorldMap = map
        
            attemptingRelocalization =  isSameMap && !isTrackingPerformanceNormal || map != nil && !isSameMap
        }

        if navigateStartToEnd {
            crumbs = route.crumbs.reversed()
            pausedTransform = route.beginRouteLandmark.transform
        } else {
            crumbs = route.crumbs
            pausedTransform = route.endRouteLandmark.transform
        }
        // make sure to clear out any relative transform that was saved before so we accurately align
        sceneView.session.setWorldOrigin(relativeTransform: simd_float4x4.makeTranslation(0, 0, 0))
        sceneView.session.run(configuration, options: [.removeExistingAnchors])

        if isTrackingPerformanceNormal, isSameMap {
            // we can skip the whole process of relocalization since we are already using the correct map and tracking is normal.  It helps to strip out old anchors to reduce jitter though
            isResumedRoute = true
            state = .readyToNavigateOrPause(allowPause: false)
        } else {
            // setting this flag after entering the .limited(reason: .relocalizing) state is a bit error prone.  Since there is a waiting period, there is no way that we will ever finish the alignment countdown before the session has successfully restarted
            state = .readyForFinalResumeAlignment
            showResumeTrackingConfirmButton(route: route, navigateStartToEnd: navigateStartToEnd)
        }
    }
    
    /// Handler for the startingPauseProcedure app state
    func handleStateTransitionToStartingPauseProcedure() {
        // clear out these variables in case they had already been created
        if creatingRouteLandmark {
            beginRouteLandmark = RouteLandmark()
        } else {
            endRouteLandmark = RouteLandmark()
        }
        do {
            try showPauseTrackingButton()
        } catch {
            // nothing to fall back on
        }
    }
    
    /// Handler for the pauseWaitingPeriod app state
    func handleStateTransitionToPauseWaitingPeriod() {
        hideAllViewsHelper()
        countdownTimer.isHidden = false
        countdownTimer.start(beginingValue: ViewController.alignmentWaitingPeriod, interval: 1)
        delayTransition()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(ViewController.alignmentWaitingPeriod)) {
            self.countdownTimer.isHidden = true
            self.pauseTracking()
        }
    }
    
    /// Handler for the completingPauseProcedure app state
    func handleStateTransitionToCompletingPauseProcedure() {
        // TODO: we should not be able to create a route landmark if we are in the relocalizing state... (might want to handle this when the user stops navigation on a route they loaded.... This would obviate the need to handle this in the recordPath code as well
        if creatingRouteLandmark {
            guard let currentTransform = sceneView.session.currentFrame?.camera.transform else {
                print("can't properly save landmark: TODO communicate this to the user somehow")
                return
            }
            beginRouteLandmark.transform = currentTransform
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(playSound)), userInfo: nil, repeats: false)
            pauseTrackingView.isHidden = true
            state = .mainScreen(announceArrival: false)
            return
        } else if let currentTransform = sceneView.session.currentFrame?.camera.transform {
            endRouteLandmark.transform = currentTransform

            if #available(iOS 12.0, *) {
                sceneView.session.getCurrentWorldMap { worldMap, error in
                    self.getRouteNameAndSaveRouteHelper(mapAsAny: worldMap)
                    self.showResumeTrackingButton()
                    Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(self.playSound)), userInfo: nil, repeats: false)
                    self.state = .pauseProcedureCompleted
                }
            } else {
                getRouteNameAndSaveRouteHelper(mapAsAny: nil)
                showResumeTrackingButton()
                Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(self.playSound)), userInfo: nil, repeats: false)
                state = .pauseProcedureCompleted
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
            do {
                // TODO: factor this out since it shows up in a few places
                let id = String(Int64(NSDate().timeIntervalSince1970 * 1000)) as NSString
                try archive(routeId: id, beginRouteLandmark: beginRouteLandmark, endRouteLandmark: endRouteLandmark, worldMapAsAny: mapAsAny)
            } catch {
                fatalError("Can't archive route: \(error.localizedDescription)")
            }
        }
    }
    
    /// Called when the user presses the routes button.  The function will display the `Routes` view, which is managed by `RoutesViewController`.
    @objc func routesButtonPressed() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "SettingsAndHelp", bundle: nil)
        let popoverContent = storyBoard.instantiateViewController(withIdentifier: "Routes") as! RoutesViewController
        popoverContent.rootViewController = self
        popoverContent.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: popoverContent, action: #selector(popoverContent.doneWithRoutes))
        popoverContent.updateRoutes(routes: dataPersistence.routes)
        let nav = UINavigationController(rootViewController: popoverContent)
        nav.modalPresentationStyle = .popover
        let popover = nav.popoverPresentationController
        popover?.delegate = self
        popover?.sourceView = self.view
        popover?.sourceRect = CGRect(x: 0, y: settingsAndHelpFrameHeight/2, width: 0,height: 0)
        
        self.present(nav, animated: true, completion: nil)
    }
    
    /// Hide all the subviews.  TODO: This should probably eventually refactored so it happens more automatically.
    func hideAllViewsHelper() {
        recordPathView.isHidden = true
        routeRatingView.isHidden = true
        stopRecordingView.isHidden = true
        startNavigationView.isHidden = true
        stopNavigationView.isHidden = true
        pauseTrackingView.isHidden = true
        resumeTrackingConfirmView.isHidden = true
        resumeTrackingView.isHidden = true
        countdownTimer.isHidden = true
    }
    
    /// This handles when a route cell is clicked (triggering the route to be loaded).
    ///
    /// - Parameters:
    ///   - route: the route that was clicked
    ///   - navigateStartToEnd: a Boolean indicating the navigation direction (true is start to end)
    func onRouteTableViewCellClicked(route: SavedRoute, navigateStartToEnd: Bool) {
        let worldMapAsAny = dataPersistence.unarchiveMap(id: route.id as String)
        hideAllViewsHelper()
        state = .startingResumeProcedure(route: route, mapAsAny: worldMapAsAny, navigateStartToEnd: navigateStartToEnd)
    }
    
    /// Saves the specified route.  The bulk of the work is done by the `DataPersistence` class, but this is a convenient wrapper.
    ///
    /// - Parameters:
    ///   - routeId: the ID of the route
    ///   - beginRouteLandmark: the route landmark for the beginning (if there is no route landmark at the beginning, the elements of this struct can be nil)
    ///   - endRouteLandmark: the route landmark for the end (if there is no route landmark at the end, the elements of this struct can be nil)
    ///   - worldMapAsAny: the world map (we use `Any?` since it is optional and we want to maintain backward compatibility with iOS 11.3)
    /// - Throws: an error if something goes wrong
    func archive(routeId: NSString, beginRouteLandmark: RouteLandmark, endRouteLandmark: RouteLandmark, worldMapAsAny: Any?) throws {
        let savedRoute = SavedRoute(id: routeId, name: routeName!, crumbs: crumbs, dateCreated: Date() as NSDate, beginRouteLandmark: beginRouteLandmark, endRouteLandmark: endRouteLandmark)
        try dataPersistence.archive(route: savedRoute, worldMapAsAny: worldMapAsAny)
        justTraveledRoute = savedRoute
    }

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

    /// Image, label, and target for start recording button.
    let recordPathButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "StartRecording")!), label: "Record path", targetSelector: Selector.recordPathButtonTapped, alignment: .center, tag: 0)

    /// The button that the allows the user to indicate a negative navigation experience
    let thumbsDownButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "thumbs_down")!), label: "Bad", targetSelector: Selector.thumbsDownButtonTapped, alignment: .leftcenter, tag: 0)
    
    /// The button that the allows the user to indicate a positive navigation experience
    let thumbsUpButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "thumbs_up")!), label: "Good", targetSelector: Selector.thumbsUpButtonTapped, alignment: .rightcenter, tag: 0)
    
    /// The button that the allows the user to resume a paused route
    let resumeButton = ActionButtonComponents(appearance: .textButton(label: "Resume"), label: "Resume", targetSelector: Selector.resumeButtonTapped, alignment: .center, tag: 0)
    
    /// The button that allows the user to enter textual description of a route landmark
    let enterLandmarkDescriptionButton = ActionButtonComponents(appearance: .textButton(label: "Describe"), label: "Enter text to help you remember this landmark", targetSelector: Selector.enterLandmarkDescriptionButtonTapped, alignment: .left, tag: 0)
    
    /// The button that allows the user to record a voice description of a route landmark
    let recordVoiceNoteButton = ActionButtonComponents(appearance: .textButton(label: "Voice Note"), label: "Record audio to help you remember this landmark", targetSelector: Selector.recordVoiceNoteButtonTapped, alignment: .right, tag: 0)

    /// The button that allows the user to start the alignment countdown
    let confirmAlignmentButton = ActionButtonComponents(appearance: .textButton(label: "Align"), label: "Start \(ViewController.alignmentWaitingPeriod)-second alignment countdown", targetSelector: Selector.confirmAlignmentButtonTapped, alignment: .center, tag: 0)
    
    /// The button that plays back the recorded voice note associated with a landmark
    let readVoiceNoteButton = ActionButtonComponents(appearance: .textButton(label: "Play Note"), label: "Play recorded voice note", targetSelector: Selector.readVoiceNoteButtonTapped, alignment: .left, tag: UIView.readVoiceNoteButtonTag)
    
    /// Image, label, and target for start recording button. TODO: need an image
    let addLandmarkButton = ActionButtonComponents(appearance: .textButton(label: "Landmark"), label: "Create landmark", targetSelector: Selector.landmarkButtonTapped, alignment: .right, tag: 0)
    
    /// Image, label, and target for stop recording button.
    let stopRecordingButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "StopRecording")!), label: "Stop recording", targetSelector: Selector.stopRecordingButtonTapped, alignment: .center, tag: 0)
    
    /// Image, label, and target for start navigation button.
    let startNavigationButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "StartNavigation")!), label: "Start navigation", targetSelector: Selector.startNavigationButtonTapped, alignment: .center, tag: 0)

    /// Title, label, and target for the pause button
    let pauseButton = ActionButtonComponents(appearance: .textButton(label: "Pause"), label: "Pause session", targetSelector: Selector.pauseButtonTapped, alignment: .right, tag: UIView.pauseButtonTag)
    
    /// Image, label, and target for stop navigation button.
    let stopNavigationButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "StopNavigation")!), label: "Stop navigation", targetSelector: Selector.stopNavigationButtonTapped, alignment: .center, tag: 0)
    
    /// Image, label, and target for routes button.
    let routesButton = ActionButtonComponents(appearance: .textButton(label: "Routes"), label: "Saved routes list", targetSelector: Selector.routesButtonTapped, alignment: .left, tag: 0)

    /// The conection to the Firebase real-time database
    var databaseHandle = Database.database()
    
    /// Keypoint object
    var keypointObject : MDLObject!
    
    /// Route persistence
    var dataPersistence = DataPersistence()
    
    // MARK: - Parameters that can be controlled remotely via Firebase
    
    /// True if the offset between direction of travel and phone should be updated over time
    var adjustOffset = false
    
    /// True if we should use a cone of pi/12 and false if we should use a cone of pi/6 when deciding whether to issue haptic feedback
    var strictHaptic = true
    
    /// True if we should add anchors ahead of the user to encourage more ARWorldMap detail.  In limited testing this did not show promise, therefore it is disabled
    var shouldDropMappingAnchors = false
    
    /// Button view container for stop recording button
    var stopRecordingView: UIView!
    
    /// Button view container for start recording button.
    var recordPathView: UIView!
    
    /// Button view container for start navigation button
    var startNavigationView: UIView!

    /// Button view container for stop navigation button
    var stopNavigationView: UIView!
    
    var sceneView = ARSCNView()
    
    /// Hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    /// Button frame extends the entire width of screen
    var buttonFrameWidth: CGFloat {
        return UIScreen.main.bounds.size.width
    }
    
    /// Height of button frame
    var buttonFrameHeight: CGFloat {
        return UIScreen.main.bounds.size.height * (1/5)
    }
    
    // Height of settings and help buttons
    var settingsAndHelpFrameHeight: CGFloat {
        return UIScreen.main.bounds.size.height * (1/12)
    }
    
    /// The margin from the settings and help buttons to the bottom of the window
    var settingsAndHelpMargin: CGFloat {
        // height of button frame
        return UIScreen.main.bounds.size.height * (1/24)
    }
    
    /// top margin of direction text label
    var textLabelBuffer: CGFloat {
        return buttonFrameHeight * (1/12)
    }
    
    /// y-origin of the get directions button
    var yOriginOfGetDirectionsButton: CGFloat {
        return UIScreen.main.bounds.size.height - settingsAndHelpFrameHeight - settingsAndHelpMargin
    }
    
    /// y-origin of the settings and help buttons
    var yOriginOfSettingsAndHelpButton: CGFloat {
        // y-origin of button frame
        return UIScreen.main.bounds.size.height - settingsAndHelpFrameHeight - settingsAndHelpMargin
    }

    /// y-origin of button frame
    var yOriginOfButtonFrame: CGFloat {
        return UIScreen.main.bounds.size.height - buttonFrameHeight - settingsAndHelpFrameHeight - settingsAndHelpMargin
    }
    
    // y-origin of announcement frame
    var yOriginOfAnnouncementFrame: CGFloat {
        return UIScreen.main.bounds.size.height/15
    }
    
    // MARK: - UIViews for all UI button containers
    var getDirectionButton: UIButton!
    var settingsButton: UIButton!
    var helpButton: UIButton!
    var pauseTrackingView: UIView!
    var resumeTrackingView: UIView!
    var resumeTrackingConfirmView: UIView!
    var announcementText: UILabel!
    var routeRatingView: UIView!
    var countdownTimer: SRCountdownTimer!
    var audioPlayers: [Int: AVAudioPlayer] = [:]
    
    enum ButtonViewType {
        // State of button views
        case recordPath
        case stopRecording
        case startNavigation
        case pauseTracking
        case resumeTracking
        case stopNavigation
    }
    
    @objc func timerDidUpdateCounterValue(newValue: Int) {
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String(newValue))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Scene view setup
        sceneView.frame = view.frame
        view.addSubview(sceneView)

        setupAudioPlayers()
        loadAssets()
        createSettingsBundle()
        createARSession()
        drawUI()
        addGestures()
        setupFirebaseObservers()
        
        // create listeners to ensure that the isReadingAnnouncement flag is reset properly
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { (notification) -> Void in
            self.currentAnnouncement = nil
        }
        
        NotificationCenter.default.addObserver(forName: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil, queue: nil) { (notification) -> Void in
            self.currentAnnouncement = nil
        }
        
        // we use a custom notification to communicate from the help controller to the main view controller that the help was dismissed
        NotificationCenter.default.addObserver(forName: Notification.Name("ClewPopoverDismissed"), object: nil, queue: nil) { (notification) -> Void in
            self.suppressTrackingWarnings = false
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let userDefaults: UserDefaults = UserDefaults.standard
        let firstTimeLoggingIn: Bool? = userDefaults.object(forKey: "firstTimeLogin") as? Bool
        
        if (firstTimeLoggingIn == nil) {
            userDefaults.set(true, forKey: "firstTimeLogin")
            showLogAlert()
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
    
    func showRecordPathWithoutLandmarkWarning() {
        let userDefaults: UserDefaults = UserDefaults.standard
        let showedRecordPathWithoutLandmarkWarning: Bool? = userDefaults.object(forKey: "showedRecordPathWithoutLandmarkWarning") as? Bool
        if showedRecordPathWithoutLandmarkWarning == nil && beginRouteLandmark.transform == nil {
            userDefaults.set(true, forKey: "showedRecordPathWithoutLandmarkWarning")
            // Show logging disclaimer when user opens app for the first time
            let alert = UIAlertController(title: "Creating reusable routes",
                                          message: "To navigate this route in the forward direction at a later time, you must create a landmark before starting the recording.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue with single-use route", style: .default, handler: { action -> Void in
                // proceed to recording
                self.state = .recordingRoute
            }
            ))
            alert.addAction(UIAlertAction(title: "Cancel recording", style: .default, handler: { action -> Void in
                // nothing to do, just stay on the main screen
            }
            ))
            self.present(alert, animated: true, completion: nil)
        } else {
            state = .recordingRoute
        }
        
    }
    
    /// Display a warning that tells the user they must create a landmark
    /// to be able to use this route again in the reverse direction
    func showNavigatePathWithoutLandmarkWarning() {
        let userDefaults: UserDefaults = UserDefaults.standard
        let showedNavigatePathWithoutLandmarkWarning: Bool? = userDefaults.object(forKey: "showedNavigatePathWithoutLandmarkWarning") as? Bool
        if showedNavigatePathWithoutLandmarkWarning == nil && endRouteLandmark.transform == nil && !isResumedRoute {
            userDefaults.set(true, forKey: "showedNavigatePathWithoutLandmarkWarning")
            // Show logging disclaimer when user opens app for the first time
            let alert = UIAlertController(title: "Creating reusable routes",
                                          message: "To navigate this route in the reverse direction at a later time, you must activate the pause button before navigating the route.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue with single-use route", style: .default, handler: { action -> Void in
                // proceed to navigation
                self.state = .navigatingRoute
            }
            ))
            alert.addAction(UIAlertAction(title: "Cancel navigation", style: .default, handler: { action -> Void in
                // nothing to do, just stay on the current screen
            }
            ))
            self.present(alert, animated: true, completion: nil)
        } else {
            state = .navigatingRoute
        }
    }
    
    /*
     * display SAVE ROUTE input dialog
     */
    @objc func showRouteNamingDialog(mapAsAny: Any?) {
        // Set title and message for the alert dialog
        if #available(iOS 12.0, *) {
            justUsedMap = mapAsAny as! ARWorldMap?
        }
        let alertController = UIAlertController(title: "Save route", message: "Enter the name of the route", preferredStyle: .alert)
        // The confirm action taking the inputs
        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            let id = String(Int64(NSDate().timeIntervalSince1970 * 1000)) as NSString
            // Get the input values from user, if it's nil then use timestamp
            self.routeName = alertController.textFields?[0].text as NSString? ?? id
            try! self.archive(routeId: id, beginRouteLandmark: self.beginRouteLandmark, endRouteLandmark: self.endRouteLandmark, worldMapAsAny: mapAsAny)
        }
            
        // The cancel action saves the just traversed route so you can navigate back along it later
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.justTraveledRoute = SavedRoute(id: "dummyid", name: "Last route", crumbs: self.crumbs, dateCreated: Date() as NSDate, beginRouteLandmark: self.beginRouteLandmark, endRouteLandmark: self.endRouteLandmark)
        }
        
        // Add textfield to our dialog box
        alertController.addTextField { (textField) in
            textField.becomeFirstResponder()
            textField.placeholder = "Enter route title"
        }
            
        // Add the action to dialogbox
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
            
        // Finally, present the dialog box
        present(alertController, animated: true, completion: nil)
    }

    
    /*
     * display LANDMARK INFORMATION input dialog
     */
    @objc func showLandmarkInformationDialog() {
        // Set title and message for the alert dialog
        let alertController = UIAlertController(title: "Landmark information", message: "Enter text about the landmark that will help you find it later.", preferredStyle: .alert)
        // The confirm action taking the inputs
        let saveAction = UIAlertAction(title: "Ok", style: .default) { (_) in
            if self.creatingRouteLandmark {
                self.beginRouteLandmark.information = alertController.textFields?[0].text as NSString?
            } else {
                self.endRouteLandmark.information = alertController.textFields?[0].text as NSString?
            }
        }
        
        // The cancel action saves the just traversed route so you can navigate back along it later
        let cancelAction = UIAlertAction(title: "Don't specify this information", style: .cancel) { (_) in
        }
        
        // Add textfield to our dialog box
        alertController.addTextField { (textField) in
            textField.becomeFirstResponder()
            textField.placeholder = "Enter landmark information"
        }
        
        // Add the action to dialogbox
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        // Finally, present the dialog box
        present(alertController, animated: true, completion: nil)
    }
    
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
    
    @objc func recordVoiceNote() {
        let popoverContent = RecorderViewController()
        popoverContent.delegate = self
        popoverContent.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: popoverContent, action: #selector(popoverContent.doneWithRecording))
        let nav = UINavigationController(rootViewController: popoverContent)
        nav.modalPresentationStyle = .popover
        let popover = nav.popoverPresentationController
        popover?.delegate = self
        popover?.sourceView = self.view
        popover?.sourceRect = CGRect(x: 0, y: self.settingsAndHelpFrameHeight/2, width: 0,height: 0)
        suppressTrackingWarnings = true
        self.present(nav, animated: true, completion: nil)
    }
    
    func showLogAlert() {
        // Show logging disclaimer when user opens app for the first time
        let logAlertVC = UIAlertController(title: "Sharing your experience with Clew",
                                           message: "Help us improve the app by logging your Clew experience. These logs will not include any images or personal information. You can turn this off in Settings.",
                                           preferredStyle: .alert)
        logAlertVC.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action -> Void in
            self.showSafetyAlert()
        }
        ))
        self.present(logAlertVC, animated: true, completion: nil)
    }
    
    func showSafetyAlert() {
        // Show safety disclaimer when user opens app for the first time
        let safetyAlertVC = UIAlertController(title: "For your safety",
                                              message: "While using the app, please be aware of your surroundings. You agree that your use of the App is at your own risk, and it is solely your responsibility to maintain your personal safety. Visit www.clewapp.org for more information on how to use the app.",
                                              preferredStyle: .alert)
        safetyAlertVC.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(safetyAlertVC, animated: true, completion: nil)
    }
    
    /*
     * Configure Settings Bundle
     */
    func createSettingsBundle() {
        registerSettingsBundle()
        updateDisplayFromDefaults()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(defaultsChanged),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }
    
    func registerSettingsBundle(){
        let appDefaults = ["crumbColor": 0, "hapticFeedback": true, "sendLogs": true, "voiceFeedback": true, "soundFeedback": true, "units": 0] as [String : Any]
        UserDefaults.standard.register(defaults: appDefaults)
    }

    func updateDisplayFromDefaults(){
        let defaults = UserDefaults.standard
        
        defaultUnit = defaults.integer(forKey: "units")
        defaultColor = defaults.integer(forKey: "crumbColor")
        soundFeedback = defaults.bool(forKey: "soundFeedback")
        voiceFeedback = defaults.bool(forKey: "voiceFeedback")
        hapticFeedback = defaults.bool(forKey: "hapticFeedback")
        sendLogs = defaults.bool(forKey: "sendLogs")
    }
    
    @objc func defaultsChanged(){
        updateDisplayFromDefaults()
    }
    
    /*
     * Create New ARSession
     */
    func createARSession() {
        configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isAutoFocusEnabled = false

        sceneView.session.run(configuration)
        sceneView.delegate = self
    }
    
    @objc func confirmAlignment() {
        if case .startingPauseProcedure = state {
            state = .pauseWaitingPeriod
        } else if case .startingResumeProcedure = state {
            resumeTracking()
        } else if case .readyForFinalResumeAlignment = state {
            resumeTracking()
        }
    }
    
    @objc func playSound() {
        feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator?.impactOccurred()
        feedbackGenerator = nil
        playSystemSound(id: 1103)
    }
    
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
    
    /*
     * Adds TapGesture to the sceneView
     */
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
    func drawUI() {
        // button that shows settings menu
        settingsButton = UIButton(frame: CGRect(x: 0, y: yOriginOfSettingsAndHelpButton, width: buttonFrameWidth/2, height: settingsAndHelpFrameHeight))
        settingsButton.isAccessibilityElement = true
        settingsButton.setTitle("Settings", for: .normal)
        settingsButton.accessibilityLabel = "Settings"
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 24.0)
        settingsButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        settingsButton.addTarget(self, action: #selector(settingsButtonPressed), for: .touchUpInside)

        // button that shows help menu
        helpButton = UIButton(frame: CGRect(x: buttonFrameWidth/2, y: yOriginOfSettingsAndHelpButton, width: buttonFrameWidth/2, height: settingsAndHelpFrameHeight))
        helpButton.isAccessibilityElement = true
        helpButton.setTitle("Help", for: .normal)
        helpButton.titleLabel?.font = UIFont.systemFont(ofSize: 24.0)
        helpButton.accessibilityLabel = "Help"
        helpButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        helpButton.addTarget(self, action: #selector(helpButtonPressed), for: .touchUpInside)

        // button that gives direction to the nearist keypoint
        getDirectionButton = UIButton(frame: CGRect(x: 0, y: 0, width: buttonFrameWidth, height: yOriginOfButtonFrame))
        getDirectionButton.isAccessibilityElement = true
        getDirectionButton.accessibilityLabel = "Get Directions"
        getDirectionButton.isHidden = true
        getDirectionButton.addTarget(self, action: #selector(announceDirectionHelpPressed), for: .touchUpInside)
        
        // textlabel that displays announcements
        announcementText = UILabel(frame: CGRect(x: 0, y: yOriginOfAnnouncementFrame, width: buttonFrameWidth, height: buttonFrameHeight*(1/2)))
        announcementText.textColor = UIColor.white
        announcementText.textAlignment = .center
        announcementText.isAccessibilityElement = false
        announcementText.lineBreakMode = .byWordWrapping
        announcementText.numberOfLines = 2
        announcementText.font = announcementText.font.withSize(20)
        announcementText.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        announcementText.isHidden = true
        
        // button that gives direction to the nearist keypoint
        countdownTimer = SRCountdownTimer(frame: CGRect(x: buttonFrameWidth*1/10, y: yOriginOfButtonFrame/10, width: buttonFrameWidth*8/10, height: buttonFrameWidth*8/10))
        countdownTimer.delegate = self
        countdownTimer.labelFont = UIFont(name: "HelveticaNeue-Light", size: 100)
        countdownTimer.labelTextColor = UIColor.white
        countdownTimer.timerFinishingText = "End"
        countdownTimer.lineWidth = 10
        countdownTimer.lineColor = UIColor.white
        countdownTimer.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        countdownTimer.isHidden = true
        // hide the timer as an accessibility element and announce through VoiceOver by posting appropriate notifications
        countdownTimer.accessibilityElementsHidden = true
        
        // Record Path button container
        recordPathView = UIView(frame: CGRect(x: 0, y: yOriginOfButtonFrame, width: buttonFrameWidth, height: buttonFrameHeight))
        recordPathView.setupButtonContainer(withButtons: [routesButton, recordPathButton, addLandmarkButton])
        
        // Stop Recording button container
        stopRecordingView = UIView(frame: CGRect(x: 0, y: yOriginOfButtonFrame, width: buttonFrameWidth, height: buttonFrameHeight))
        stopRecordingView.setupButtonContainer(withButtons: [stopRecordingButton])
        
        // Start Navigation button container
        startNavigationView = UIView(frame: CGRect(x: 0, y: yOriginOfButtonFrame, width: buttonFrameWidth, height: buttonFrameHeight))
        startNavigationView.setupButtonContainer(withButtons: [startNavigationButton, pauseButton])
        
        pauseTrackingView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        pauseTrackingView.setupButtonContainer(withButtons: [enterLandmarkDescriptionButton, confirmAlignmentButton, recordVoiceNoteButton], withMainText: "Landmarks allow you to save or pause your route. You will need to return to the landmark to load or unpause your route. Before creating the landmark, specify text or voice to help you remember its location. To create a landmark, hold your device flat with the screen facing up. Press the top (short) edge flush against a flat vertical surface (such as a wall).  The \"align\" button starts a \(ViewController.alignmentWaitingPeriod)-second countdown. During this time, do not move the device.")
        
        resumeTrackingView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        resumeTrackingView.setupButtonContainer(withButtons: [resumeButton], withMainText: "Return to the last paused location and press Resume for further instructions.")
        
        resumeTrackingConfirmView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        resumeTrackingConfirmView.setupButtonContainer(withButtons: [confirmAlignmentButton, readVoiceNoteButton], withMainText: "Hold your device flat with the screen facing up. Press the top (short) edge flush against the same vertical surface that you used to create the landmark.  When you are ready, activate the align button to start the \(ViewController.alignmentWaitingPeriod)-second alignment countdown that will complete the procedure. Do not move the device until the phone provides confirmation via a vibration or sound cue.")

        // Stop Navigation button container
        stopNavigationView = UIView(frame: CGRect(x: 0, y: yOriginOfButtonFrame, width: buttonFrameWidth, height: buttonFrameHeight))
        stopNavigationView.setupButtonContainer(withButtons: [stopNavigationButton])
        
        routeRatingView = UIView(frame: CGRect(x: 0, y: 0, width: buttonFrameWidth, height: UIScreen.main.bounds.size.height))
        routeRatingView.setupButtonContainer(withButtons: [thumbsUpButton, thumbsDownButton], withMainText: "Please rate your service.")
        
        self.view.addSubview(recordPathView)
        self.view.addSubview(stopRecordingView)
        self.view.addSubview(startNavigationView)
        self.view.addSubview(pauseTrackingView)
        self.view.addSubview(resumeTrackingView)
        self.view.addSubview(resumeTrackingConfirmView)
        self.view.addSubview(stopNavigationView)
        self.view.addSubview(announcementText)
        self.view.addSubview(getDirectionButton)
        self.view.addSubview(settingsButton)
        self.view.addSubview(helpButton)
        self.view.addSubview(routeRatingView)
        self.view.addSubview(countdownTimer)
        
        state = .mainScreen(announceArrival: false)
    }
    
    /*
     * display RECORD PATH button/hide all other views
     */
    @objc func showRecordPathButton(announceArrival: Bool) {
        recordPathView.isHidden = false
        // the options button is hidden if the route rating shows up
        settingsButton.isHidden = false
        helpButton.isHidden = false
        stopNavigationView.isHidden = true
        getDirectionButton.isHidden = true
        routeRatingView.isHidden = true
        if announceArrival {
            delayTransition(announcement: "You've arrived.")
        } else {
            delayTransition()
        }
    }
    
    func delayTransition(announcement: String? = nil) {
        // this notification currently cuts off the announcement of the button that was just pressed
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: nil)
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
    
    /*
     * display STOP RECORDIN button/hide all other views
     */
    @objc func showStopRecordingButton() {
        recordPathView.isHidden = true
        recordPathView.isAccessibilityElement = false
        stopRecordingView.isHidden = false
        delayTransition(announcement: "Hold vertically with the rear camera facing forward.")
    }
    
    /*
     * display START NAVIGATION button/hide all other views
     */
    @objc func showStartNavigationButton(allowPause: Bool) {
        resumeTrackingView.isHidden = true
        resumeTrackingConfirmView.isHidden = true
        stopRecordingView.isHidden = true
        startNavigationView.getButtonByTag(tag: UIView.pauseButtonTag)?.isHidden = !allowPause
        startNavigationView.isHidden = false
        delayTransition()
    }
    
    /*
     * display PAUSE TRACKING button/hide all other views
     */
    func showPauseTrackingButton() throws {
        recordPathView.isHidden = true
        startNavigationView.isHidden = true
        pauseTrackingView.isHidden = false
        delayTransition()
    }
    
    /*
     * display RESUME TRACKING button/hide all other views
     */
    @objc func showResumeTrackingButton() {
        pauseTrackingView.isHidden = true
        resumeTrackingView.isHidden = false
        delayTransition()
    }
    
    func showResumeTrackingConfirmButton(route: SavedRoute, navigateStartToEnd: Bool) {
        resumeTrackingView.isHidden = true
        resumeTrackingConfirmView.isHidden = false
        resumeTrackingConfirmView.mainText?.text = ""
        voiceNoteToPlay = nil
        if navigateStartToEnd {
            if let landmarkInformation = route.beginRouteLandmark.information as String? {
                resumeTrackingConfirmView.mainText?.text?.append("The landmark information you entered is: " + landmarkInformation + ".\n\n")
            }
            if let beginRouteLandmarkVoiceNote = route.beginRouteLandmark.voiceNote {
                let voiceNoteToPlayURL = beginRouteLandmarkVoiceNote.documentURL
                do {
                    let data = try Data(contentsOf: voiceNoteToPlayURL)
                    voiceNoteToPlay = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.caf.rawValue)
                    voiceNoteToPlay?.prepareToPlay()
                } catch {}
            }
        } else {
            if let landmarkInformation = route.endRouteLandmark.information as String? {
                resumeTrackingConfirmView.mainText?.text?.append("The landmark information you entered is: " + landmarkInformation + ".\n\n")
            }
            if let endRouteLandmarkVoiceNote = route.endRouteLandmark.voiceNote {
                let voiceNoteToPlayURL = endRouteLandmarkVoiceNote.documentURL
                do {
                    let data = try Data(contentsOf: voiceNoteToPlayURL)
                    voiceNoteToPlay = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.caf.rawValue)
                    voiceNoteToPlay?.prepareToPlay()
                } catch {}
            }
        }
        resumeTrackingConfirmView.getButtonByTag(tag: UIView.readVoiceNoteButtonTag)?.isHidden = voiceNoteToPlay == nil
        resumeTrackingConfirmView.mainText?.text?.append("Hold your device flat with the screen facing up. Press the top (short) edge flush against the same vertical surface that you used to create the landmark.  When you are ready, activate the align button to start the \(ViewController.alignmentWaitingPeriod)-second alignment countdown that will complete the procedure. Do not move the device until the phone provides confirmation via a vibration or sound cue.")
        delayTransition()
    }
    
    /*
     * display STOP NAVIGATION button/hide all other views
     */
    @objc func showStopNavigationButton() {
        startNavigationView.isHidden = true
        stopNavigationView.isHidden = false
        getDirectionButton.isHidden = false
        // this does not auto update, so don't use it as an accessibility element
        delayTransition()
    }
    
    /*
     * display ROUTE RATING button/hide all other views
     */
    @objc func showRouteRating(announceArrival: Bool) {
        stopNavigationView.isHidden = true
        getDirectionButton.isHidden = true
        routeRatingView.isHidden = false

        if announceArrival {
            routeRatingView.mainText?.text = "You've arrived. Please rate your service."
        } else {
            routeRatingView.mainText?.text = "Please rate your service."
        }
        
        feedbackGenerator = nil
        waypointFeedbackGenerator = nil
        delayTransition()
    }
    
    /*
     * update directionText UILabel given text string and font size
     * distance Bool used to determine whether to add string "meters" to direction text
     */
    func updateDirectionText(_ description: String, distance: Float, displayDistance: Bool) {
        let distanceToDisplay = roundToTenths(distance * unitConversionFactor[defaultUnit]!)
        var altText = description
        if (displayDistance) {
            if defaultUnit == 0 || distanceToDisplay >= 10 {
                // don't use fractiomal feet or for higher numbers of meters (round instead)
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
    
    // AR Session Configuration
    var configuration: ARWorldTrackingConfiguration!
    
    // Clew internal datastructures
    var crumbs: [LocationInfo]!                 // list of crumbs dropped when recording path
    var keypoints: [KeypointInfo]!              // list of keypoints calculated after path completion
    var keypointNode: SCNNode!                  // SCNNode of the next keypoint
    var prevKeypointPosition: LocationInfo!     // previous keypoint location - originally set to current location
    var turnWarning: Bool!                      // bool to make sure turnWarning happens only once

    /// Interface for logging data about the session and the path
    var logger = PathLogger()
    
    // Timers for background functions
    var droppingCrumbs: Timer?
    var followingCrumbs: Timer?
    var hapticTimer: Timer?
    var announcementRemovalTimer: Timer?
    var updateHeadingOffsetTimer: Timer?
    
    // navigation class and state
    var nav = Navigation()                  // Navigation calculation class
    
    // haptic generators
    var feedbackGenerator : UIImpactFeedbackGenerator? = nil
    var waypointFeedbackGenerator: UINotificationFeedbackGenerator? = nil
    var feedbackTimer: Date!
    let FEEDBACKDELAY = 0.4
    
    // settings bundle configuration
    // the bundle configuration has 0 as feet and 1 as meters
    let unit = [0: "ft", 1: "m"]
    let unitText = [0: " feet", 1: " meters"]
    let unitConversionFactor = [0: Float(100.0/2.54/12.0), 1: Float(1.0)]

    var defaultUnit: Int!
    var defaultColor: Int!
    var soundFeedback: Bool!
    var voiceFeedback: Bool!
    var hapticFeedback: Bool!
    var sendLogs: Bool!

    /// This keeps track of the paused transform while the current session is being realigned to the saved route
    var pausedTransform : simd_float4x4?
    
    var beginRouteLandmark = RouteLandmark()
    var endRouteLandmark = RouteLandmark()

    var routeName: NSString?

    var justTraveledRoute: SavedRoute?
    
    // this is a generically typed placeholder for the justUsedMap computed property.  This is needed due to the fact that @available cannot be used for stored attributes
    var justUsedMapAsAny: Any?
    @available(iOS 12.0, *)
    var justUsedMap : ARWorldMap? {
        get {
            return justUsedMapAsAny as! ARWorldMap?
        }
        set (newValue) {
            justUsedMapAsAny = newValue
        }
    }
    
    // DirectionText based on hapic/voice settings
    var Directions: Dictionary<Int, String> {
        if (hapticFeedback) {
            return HapticDirections
        } else {
            return ClockDirections
        }
    }
    
    @objc func recordPath() {
        showRecordPathWithoutLandmarkWarning()
    }
    
    @objc func stopRecording(_ sender: UIButton) {
        if beginRouteLandmark.transform != nil {
            if #available(iOS 12.0, *) {
                sceneView.session.getCurrentWorldMap { worldMap, error in
                    self.getRouteNameAndSaveRouteHelper(mapAsAny: worldMap)
                }
            } else {
                getRouteNameAndSaveRouteHelper(mapAsAny: nil)
            }
        }

        isResumedRoute = false
        state = .readyToNavigateOrPause(allowPause: true)
    }
    
    @objc func startNavigation(_ sender: UIButton) {
        // this will handle the appropriate state transition if we pass the warning
        showNavigatePathWithoutLandmarkWarning()
    }
    
    /// This helper function will restart the tracking session if a relocalization was in progress but did not succeed.  This is useful in the case when you want to allow for the recording of a new route and don't want to have the possibility achieving relocalization halfway through recording the route.
    func restartSessionIfFailedToRelocalize() {
        if attemptingRelocalization {
            if !suppressTrackingWarnings {
                announce(announcement: "Could not match visually to the saved route. Starting new tracking session.")
            }
            if #available(iOS 12.0, *) {
                configuration.initialWorldMap = nil
            }
            sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
            attemptingRelocalization = false
        }
    }
    
    @objc func stopNavigation(_ sender: UIButton) {
        // stop navigation
        followingCrumbs?.invalidate()
        hapticTimer?.invalidate()
        
        feedbackGenerator = nil
        waypointFeedbackGenerator = nil

        restartSessionIfFailedToRelocalize()
        
        // erase nearest keypoint
        keypointNode.removeFromParentNode()
        
        if(sendLogs) {
            state = .ratingRoute(announceArrival: false)
        } else {
            state = .mainScreen(announceArrival: false)
            logger.resetStateSequenceLog()
        }
    }
    
    @objc func startPauseProcedure() {
        creatingRouteLandmark = false
        state = .startingPauseProcedure
    }
    
    @objc func startCreateLandmarkProcedure() {
        creatingRouteLandmark = true
        // make sure to clear out any relative transform and paused transform so the alignment is accurate
        sceneView.session.setWorldOrigin(relativeTransform: simd_float4x4.makeTranslation(0, 0, 0))
        state = .startingPauseProcedure
    }
    
    @objc func pauseTracking() {
        // pause AR pose tracking
        state = .completingPauseProcedure
    }
    
    @objc func resumeTracking() {
        // resume pose tracking with existing ARSessionConfiguration
        hideAllViewsHelper()
        countdownTimer.isHidden = false
        countdownTimer.start(beginingValue: ViewController.alignmentWaitingPeriod, interval: 1)
        delayTransition()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(ViewController.alignmentWaitingPeriod)) {
            self.countdownTimer.isHidden = true
            // The first check is necessary in case the phone relocalizes before this code executes
            if case .readyForFinalResumeAlignment = self.state, let alignTransform = self.pausedTransform, let camera = self.sceneView.session.currentFrame?.camera {
                // yaw can be determined by projecting the camera's z-axis into the ground plane and using arc tangent (note: the camera coordinate conventions of ARKit https://developer.apple.com/documentation/arkit/arsessionconfiguration/worldalignment/camera
                let alignYaw = self.getYawHelper(alignTransform)
                let cameraYaw = self.getYawHelper(camera.transform)

                var leveledCameraPose = simd_float4x4.makeRotate(radians: cameraYaw, 0, 1, 0)
                leveledCameraPose.columns.3 = camera.transform.columns.3
                
                var leveledAlignPose =  simd_float4x4.makeRotate(radians: alignYaw, 0, 1, 0)
                leveledAlignPose.columns.3 = alignTransform.columns.3
                
                let relativeTransform = leveledCameraPose * leveledAlignPose.inverse
                self.sceneView.session.setWorldOrigin(relativeTransform: relativeTransform)
                
                Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(self.playSound)), userInfo: nil, repeats: false)
                self.isResumedRoute = true
                self.state = .readyToNavigateOrPause(allowPause: false)
            }
        }
    }
    
    @objc func confirmResumeTracking() {
        if let route = justTraveledRoute {
            state = .startingResumeProcedure(route: route, mapAsAny: justUsedMapAsAny, navigateStartToEnd: false)
        }
    }
    
    // MARK: - Logging
    @objc func sendLogData() {
        // send success log data to Firebase
        logger.compileLogData(false)
        logger.resetStateSequenceLog()
        state = .mainScreen(announceArrival: false)
    }
    
    @objc func sendDebugLogData() {
        // send debug log data to Firebase
        logger.compileLogData(true)
        logger.resetStateSequenceLog()
        state = .mainScreen(announceArrival: false)
    }
    
    @objc func dropCrumb() {
        // drop waypoint markers to record path
        // TODO: gracefully handle error
        let curLocation = getRealCoordinates(record: true)!.location
        crumbs.append(curLocation)

        if shouldDropMappingAnchors {
            // This was an experiment that I (Paul) did to see if adding anchors would improve relocalization performance.  I don't believe that it does.
            let headingVector = getProjectedHeading(curLocation.transform)
            let leftToRightVector = simd_make_float4(-headingVector.z, 0, headingVector.x, 0)
            
            let aheadAndDown = simd_float4x4.init(columns: (curLocation.transform.columns.0, curLocation.transform.columns.1, curLocation.transform.columns.2, curLocation.transform.columns.3 + 2*headingVector +
                simd_make_float4(0, -1, 0, 0)))
            var shouldAddAnchor = true
            if let mappingAnchors = sceneView.session.currentFrame?.anchors.compactMap({ $0 as? LocationInfo }) {
                for anchor in mappingAnchors.reversed() {
                    if simd_norm_one(anchor.transform.columns.3 - aheadAndDown.columns.3) < 1.0 {
                        shouldAddAnchor = false
                        break
                    }
                }
            }
            // only add this as an anchor if there aren't any other ones within 1.0m (L1 distance) of the one we plan to add
            if shouldAddAnchor {
                let aheadAndUp = simd_float4x4.init(columns: (curLocation.transform.columns.0, curLocation.transform.columns.1, curLocation.transform.columns.2, curLocation.transform.columns.3 + 2*headingVector +
                    simd_make_float4(0, 2, 0, 0)))
                
                let ahead = simd_float4x4.init(columns: (curLocation.transform.columns.0, curLocation.transform.columns.1, curLocation.transform.columns.2, curLocation.transform.columns.3 + 2*headingVector))
                
                let aheadAndLeft = simd_float4x4.init(columns: (curLocation.transform.columns.0, curLocation.transform.columns.1, curLocation.transform.columns.2, curLocation.transform.columns.3 + 2*headingVector - 2*leftToRightVector))
                
                let aheadAndRight = simd_float4x4.init(columns: (curLocation.transform.columns.0, curLocation.transform.columns.1, curLocation.transform.columns.2, curLocation.transform.columns.3 + 2*headingVector + 2*leftToRightVector))
                
                let anchorTransforms = [aheadAndDown, aheadAndUp, ahead, aheadAndRight, aheadAndLeft]
                
                for anchorTransform in anchorTransforms {
                    sceneView.session.add(anchor: LocationInfo(transform: anchorTransform))
                    let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
                    let node = SCNNode(geometry: box)
                    node.transform = SCNMatrix4(anchorTransform)
                    sceneView.scene.rootNode.addChildNode(node)
                }
            }
        }
    }
    
    @objc func followCrumb() {
        // checks to see if user is on the right path during navigation
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
                
                // update directions to next keypoint
                directionToNextKeypoint = getDirectionToNextKeypoint(currentLocation: curLocation)
                setDirectionText(currentLocation: curLocation.location, direction: directionToNextKeypoint, displayDistance: false)
                turnWarning = false
            } else {
                // arrived at final keypoint
                // send haptic/sonic feedback
                waypointFeedbackGenerator?.notificationOccurred(.success)
                if (soundFeedback) { playSystemSound(id: 1016) }
                
                // erase current keypoint node
                keypointNode.removeFromParentNode()
                
                followingCrumbs?.invalidate()
                hapticTimer?.invalidate()
                
                restartSessionIfFailedToRelocalize()
                
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
    
    func getYawHelper(_ transform: simd_float4x4) -> Float {
        // TODO: this is legacy to match with the stuff in nav, but it doesn't match the getProjectedHeading vector
        let projectedHeading = getProjectedHeading(transform)
        return atan2f(-projectedHeading.x, -projectedHeading.z)
    }
    
    // MARK: - Render directions
    @objc func getHapticFeedback() {
        // send haptic feedback depending on correct device
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
            if(-timeInterval > FEEDBACKDELAY) {
                // wait until desired time interval before sending another feedback
                if (hapticFeedback) { feedbackGenerator?.impactOccurred() }
                if (soundFeedback) { playSystemSound(id: 1103) }
                feedbackTimer = Date()
            }
        }
    }
    
    /// Communicates a message to the user via speech.  If VoiceOver is active, then VoiceOver is used
    /// to communicate the announcement, otherwise we use the AVSpeechEngine
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
        
        announcementText.isHidden = false
        announcementText.text = announcement
        announcementRemovalTimer?.invalidate()
        announcementRemovalTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { timer in
            self.announcementText.isHidden = true
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
    
    func getDirectionToNextKeypoint(currentLocation: CurrentCoordinateInfo) -> DirectionInfo {
        // returns direction to next keypoint from current location
        var dir = nav.getDirections(currentLocation: currentLocation, nextKeypoint: keypoints[0])
        dir.distance = roundToTenths(dir.distance)
        return dir
    }
    
    @objc func announceDirectionHelpPressed() {
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: (#selector(announceDirectionHelp)), userInfo: nil, repeats: false)
    }
    
    @objc func settingsButtonPressed() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "SettingsAndHelp", bundle: nil)
        let popoverContent = storyBoard.instantiateViewController(withIdentifier: "Settings") as! SettingsViewController
        let nav = UINavigationController(rootViewController: popoverContent)
        nav.modalPresentationStyle = .popover
        let popover = nav.popoverPresentationController
        popover?.delegate = self
        popover?.sourceView = self.view
        popover?.sourceRect = CGRect(x: 0, y: settingsAndHelpFrameHeight/2, width: 0,height: 0)
        
        popoverContent.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: popoverContent, action: #selector(popoverContent.doneWithSettings))

        
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc func helpButtonPressed() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "SettingsAndHelp", bundle: nil)
        let popoverContent = storyBoard.instantiateViewController(withIdentifier: "Help") as! HelpViewController
        let nav = UINavigationController(rootViewController: popoverContent)
        nav.modalPresentationStyle = .popover
        let popover = nav.popoverPresentationController
        popover?.delegate = self
        popover?.sourceView = self.view
        popover?.sourceRect = CGRect(x: 0, y: settingsAndHelpFrameHeight/2, width: 0,height: 0)
        popoverContent.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: popoverContent, action: #selector(popoverContent.doneWithHelp))
        suppressTrackingWarnings = true
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc func announceDirectionHelp() {
        // announce directions at any given point to the next keypoint
        if case .navigatingRoute = state, let curLocation = getRealCoordinates(record: false) {
            let directionToNextKeypoint = getDirectionToNextKeypoint(currentLocation: curLocation)
            setDirectionText(currentLocation: curLocation.location, direction: directionToNextKeypoint, displayDistance: true)
        }
    }
    
    func setDirectionText(currentLocation: LocationInfo, direction: DirectionInfo, displayDistance: Bool) {
        // Set direction text for text label and VoiceOver
        let xzNorm = sqrtf(powf(currentLocation.x - keypoints[0].location.x, 2) + powf(currentLocation.z - keypoints[0].location.z, 2))
        let slope = (keypoints[0].location.y - prevKeypointPosition.y) / xzNorm
        var dir = ""
        
        if(slope > 0.3) { // Go upstairs
            if(hapticFeedback) {
                dir += "\(Directions[direction.hapticDirection]!) and proceed upstairs"
            } else {
                dir += "\(Directions[direction.clockDirection]!) and proceed upstairs"
            }
            updateDirectionText(dir, distance: 0, displayDistance: false)
        } else if (slope < -0.3) { // Go downstairs
            if(hapticFeedback) {
                dir += "\(Directions[direction.hapticDirection]!) and proceed downstairs"
            } else {
                dir += "\(Directions[direction.clockDirection]!) and proceed downstairs"
            }
            updateDirectionText(dir, distance: direction.distance, displayDistance: false)
        } else { // nromal directions
            if(hapticFeedback) {
                dir += "\(Directions[direction.hapticDirection]!)"
            } else {
                dir += "\(Directions[direction.clockDirection]!)"
            }
            updateDirectionText(dir, distance: direction.distance, displayDistance:  displayDistance)
        }
    }
    
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
            logger.logTransformMatrix(state: state, scn: scn)
        }
        return CurrentCoordinateInfo(LocationInfo(transform: currTransform), transMatrix: transMatrix)
    }
    
    /*
     * Called when there is a change in tracking state
     */
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var logString: String? = nil

        switch camera.trackingState {
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                logString = "ExcessiveMotion"
                print("Excessive motion")
                if !suppressTrackingWarnings {
                    announce(announcement: "Excessive motion.\nTracking performance is degraded.")
                    if soundFeedback {
                        playSystemSound(id: 1050)
                    }
                }
            case .insufficientFeatures:
                logString = "InsufficientFeatures"
                print("InsufficientFeatures")
                if !suppressTrackingWarnings {
                    announce(announcement: "Insufficient visual features.\nTracking performance is degraded.")
                    if soundFeedback {
                        playSystemSound(id: 1050)
                    }
                }
            case .initializing:
                // don't log anything
                print("initializing")
            case .relocalizing:
                logString = "Relocalizing"
                print("Relocalizing")
            @unknown default:
                print("An error condition arose that we didn't know about when the app was last compiled")
            }
        case .normal:
            logString = "Normal"
            if #available(iOS 12.0, *), configuration.initialWorldMap != nil, attemptingRelocalization {
                if !suppressTrackingWarnings {
                    announce(announcement: "Successfully matched current environment to saved route.")
                }
                attemptingRelocalization = false
            } else if case let .limited(reason)? = trackingSessionState {
                if !suppressTrackingWarnings {
                    if reason == .initializing {
                        announce(announcement: "Tracking session initialized.")
                    } else {
                        announce(announcement: "Tracking performance normal.")
                        if soundFeedback {
                            playSystemSound(id: 1025)
                        }
                    }
                }
            }
            // resetting the origin is needed in the case when we realigned to a saved route
            session.setWorldOrigin(relativeTransform: simd_float4x4.makeTranslation(0,0,0))
            if case .readyForFinalResumeAlignment = state {
                // this will cancel any realignment if it hasn't happened yet and go straight to route navigation mode
                countdownTimer.isHidden = true
                isResumedRoute = true
                
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
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        // TODO: not sure if this is actually what we should be doing.  Perhaps we should cancel any recording or navigation if this happens rather than trying to relocalize
        return true
    }
    
}

extension ViewController: RecorderViewControllerDelegate {
    func didStartRecording() {
    }
    
    func didFinishRecording(audioFileURL: URL) {
        if creatingRouteLandmark {
            // delete the file since we are re-recording it
            if let beginRouteLandmarkVoiceNote = self.beginRouteLandmark.voiceNote {
                do {
                    try FileManager.default.removeItem(at: beginRouteLandmarkVoiceNote.documentURL)
                } catch { }
            }
            beginRouteLandmark.voiceNote = audioFileURL.lastPathComponent as NSString
        } else {
            // delete the file since we are re-recording it
            if let endRouteLandmarkVoiceNote = self.endRouteLandmark.voiceNote {
                do {
                    try FileManager.default.removeItem(at: endRouteLandmarkVoiceNote.documentURL)
                } catch { }
            }
            endRouteLandmark.voiceNote = audioFileURL.lastPathComponent as NSString
        }
    }
}

extension ViewController: UIPopoverPresentationControllerDelegate {
    // MARK: - UIPopoverPresentationControllerDelegate
    
    /// Makes sure that popovers are not modal
    ///
    /// - Parameter controller: the presentation controller
    /// - Returns: whether or not to use modal style
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
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


extension NSString {
    var documentURL: URL {
        return FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(self as String)
    }
}

extension float4x4 {
    
    static func makeRotate(radians: Float, _ x: Float, _ y: Float, _ z: Float) -> float4x4 {
        return unsafeBitCast(GLKMatrix4MakeRotation(radians, x, y, z), to: float4x4.self)
    }
    
    static func makeTranslation(_ x: Float, _ y: Float, _ z: Float) -> float4x4 {
        return unsafeBitCast(GLKMatrix4MakeTranslation(x, y, z), to: float4x4.self)
    }
    
    func rotate(radians: Float, _ x: Float, _ y: Float, _ z: Float) -> float4x4 {
        return self * float4x4.makeRotate(radians: radians, x, y, z)
    }
    
    func translate(x: Float, _ y: Float, _ z: Float) -> float4x4 {
        return self * float4x4.makeTranslation(x, y, z)
    }
    
    var x: Float {
        return columns.3.x
    }
    var y: Float {
        return columns.3.y
    }
    var z: Float {
        return columns.3.z
    }
    var yaw: Float {
        return LocationInfo(anchor: ARAnchor(transform: self)).yaw
    }
}
