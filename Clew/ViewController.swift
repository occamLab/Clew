//
//  ViewController.swift
//  ARKitTest
//
//  Created by Chris Seonghwan Yoon & Jeremy Ryan on 7/10/17.
//
// Known issues
//
// Major features to implement
//  - None currently
//
// Potential enhancements
//  - Possibly create a warning if the phone doesn't appear to be in the correct orientation
//  - revisit turn warning feature.  It doesn't seem to actually help all that much at the moment.
//  - Group record path and record button (for instance)
//  - Might want to suppress old pending tracking status updates (this can be overwhelming and you really only want the latest information)

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
}

/// Holds information about the buttons that are used to control navigation and tracking.
///
/// These button attributes are the only ones unique to each of these buttons.
public struct ActionButtonComponents {
    
    enum Appearance {
        case imageButton(image: UIImage)
        case textButton(label: String)
    }
    
    enum ButtonContainerHorizontalAlignment {
        case center
        case rightcenter
        case right
        case leftcenter
        case left
    }

    /// Button image
    var appearance: Appearance
    
    /// Accessibility label
    var label: String
    
    /// Function to call when the button is tapped
    ///
    /// - TODO: Potentially unnecessary when the transitioning between views is refactored.
    var targetSelector: Selector
    
    var alignment: ButtonContainerHorizontalAlignment
    
    /// Tag to use to identify the button if we need to interact with it later.  Pass 0 if no
    /// subsequent interaction is required.
    var tag: Int
}

enum AppState {
    /// This is the screen the comes up immediately after the splash screen
    case mainScreen(announceArrival: Bool)
    /// User is recording the
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
    case startingResumeProcedure(route: SavedRoute, map: ARWorldMap?, navigateStartToEnd: Bool)
    /// the AR session has entered the relocalizing state, which means that we can now realign the session
    case readyForFinalResumeAlignment
    
    /// rawValue is useful for serializing state values, which we are currently using for our logging feature
    var rawValue: String {
        switch self {
        case .mainScreen(let announceArrival):
            return "mainScreen(announceArrival=\(announceArrival))"
        case .recordingRoute:
            return "recordingRoute"
        case .readyToNavigateOrPause(let allowPause):
            return "readyToNavigateOrPause(allowPause=\(allowPause))"
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

class ViewController: UIViewController, ARSCNViewDelegate, SRCountdownTimerDelegate {
    
    // MARK: - Refactoring UI definition
    
    // MARK: Properties and subview declarations
    
    /// How long to wait (in seconds) between the volume press and grabbing the transform for pausing
    let pauseWaitingPeriod = 5
    
    /// How long to wait (in seconds) between the volume press and resuming the tracking session based on physical alignment
    let resumeWaitingPeriod = 5
    
    /// The state of the ARKit tracking session as last communicated to us through the delgate protocol.  This is useful if you want to do something different in the delegate method depending on the previous state
    var trackingSessionState : ARCamera.TrackingState?
    
    /// The state of the app.  This should be constantly referenced and updated as the app transitions
    var state = AppState.initializing {
        didSet {
            stateSequenceTime.append(roundToThousandths(-stateTransitionLogTimer.timeIntervalSinceNow))
            stateSequence.append(state.rawValue)
            switch state {
            case .recordingRoute:
                handleStateTransitionToRecordingRoute()
            case .readyToNavigateOrPause(let allowPause):
                handleStateTransitionToReadyToNavigateOrPause(allowPause: allowPause)
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
            case .startingResumeProcedure(let route, let map, let navigateStartToEnd):
                handleStateTransitionToStartingResumeProcedure(route: route, map: map, navigateStartToEnd: navigateStartToEnd)
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
    
    // This Boolean marks whether or not the pause procedure is being used to create a landmark at the start of a route (true) or if it is being used to pause an already recorded route
    // TODO: it would be nice if this could be a property of the state transition, but since it needs to stick around for multiple states it might become cumbersome to constantly pass around.  This is why it is an attribute whereas the announceArrival flag is a part of some of the AppState values.
    var creatingRouteLandmark: Bool = false
    
    /// Set to true when the user is attempting to load a saved route that has a map associated with it
    var attemptingRelocalization: Bool = false
    
    func handleStateTransitionToMainScreen(announceArrival: Bool) {
        showRecordPathButton(announceArrival: announceArrival)
    }
    
    func handleStateTransitionToRecordingRoute() {
        // records a new path
        
        // make sure to never record a path with a transform set
        sceneView.session.setWorldOrigin(relativeTransform: simd_float4x4.makeTranslation(0, 0, 0))
        attemptingRelocalization = false
        
        // reset all logging related variables
        crumbs = []
        pathData = []
        pathDataTime = []
        dataTimer = Date()
        
        trackingErrorData = []
        trackingErrorTime = []
        trackingErrorPhase = []
        
        showStopRecordingButton()
        droppingCrumbs = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(dropCrumb), userInfo: nil, repeats: true)
        // make sure there are no old values hanging around
        nav.headingOffset = 0.0
        headingRingBuffer.clear()
        locationRingBuffer.clear()
        updateHeadingOffsetTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: (#selector(updateHeadingOffset)), userInfo: nil, repeats: true)
    }
    
    func handleStateTransitionToReadyToNavigateOrPause(allowPause: Bool) {
        droppingCrumbs?.invalidate()
        updateHeadingOffsetTimer?.invalidate()
        showStartNavigationButton(allowPause: allowPause)
    }
    
    func handleStateTransitionToNavigatingRoute() {
        // navigate the recorded path

        // If the route has not yet been saved, we can no longer save this route
        routeName = nil
        beginRouteLandmarkTransform = nil
        beginRouteLandmarkInformation = nil
        endRouteLandmarkTransform = nil
        endRouteLandmarkInformation = nil
        
        // clear any old log variables
        navigationData = []
        navigationDataTime = []
        speechData = []
        speechDataTime = []
        dataTimer = Date()
        
        // generate path from PathFinder class
        // enabled hapticFeedback generates more keypoints
        let path = PathFinder(crumbs: crumbs.reversed(), hapticFeedback: hapticFeedback, voiceFeedback: voiceFeedback)
        keypoints = path.keypoints
        
        // save keypoints data for debug log
        keypointData = []
        for keypoint in keypoints {
            let data = [keypoint.location.x, keypoint.location.y, keypoint.location.z, keypoint.location.yaw]
            keypointData.append(data)
        }
        
        // reder 3D keypoints
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
    
    func handleStateTransitionToRatingRoute(announceArrival: Bool) {
        showRouteRating(announceArrival: announceArrival)
    }
    
    func handleStateTransitionToStartingResumeProcedure(route: SavedRoute, map: ARWorldMap?, navigateStartToEnd: Bool) {
        // load the world map and restart the session so that things have a chance to quiet down before putting it up to the wall
        let isTrackingPerformanceNormal: Bool
        if case .normal? = sceneView.session.currentFrame?.camera.trackingState {
            isTrackingPerformanceNormal = true
        } else {
            isTrackingPerformanceNormal = false
        }
        
        let isSameMap = configuration.initialWorldMap != nil && configuration.initialWorldMap == map
        configuration.initialWorldMap = map
        
        attemptingRelocalization =  isSameMap && !isTrackingPerformanceNormal || map != nil && !isSameMap

        if navigateStartToEnd {
            crumbs = route.crumbs.reversed()
            pausedTransform = route.beginRouteLandmarkTransform
        } else {
            crumbs = route.crumbs
            pausedTransform = route.endRouteLandmarkTransform
        }
        // make sure to clear out any relative transform that was saved before so we accurately align
        sceneView.session.setWorldOrigin(relativeTransform: simd_float4x4.makeTranslation(0, 0, 0))
        sceneView.session.run(configuration, options: [.removeExistingAnchors])

        if isTrackingPerformanceNormal, isSameMap {
            // we can skip the whole process of relocalization since we are already using the correct map and tracking is normal.  It helps to strip out old anchors to reduce jitter though
            state = .readyToNavigateOrPause(allowPause: false)
        } else {
            // setting this flag after entering the .limited(reason: .relocalizing) state is a bit error prone.  Since there is a 5-second waiting period, there is no way that we will ever finish the alignment countdown before the session has successfully restarted
            state = .readyForFinalResumeAlignment
            showResumeTrackingConfirmButton(route: route, navigateStartToEnd: navigateStartToEnd)
        }
    }
    
    func handleStateTransitionToStartingPauseProcedure() {
        // clear out these variables in case they had already been created
        if creatingRouteLandmark {
            beginRouteLandmarkInformation = nil
            beginRouteLandmarkTransform = nil
        } else {
            endRouteLandmarkInformation = nil
            endRouteLandmarkTransform = nil
        }
        do {
            try showPauseTrackingButton()
        } catch {
            // nothing to fall back on
        }
    }
    
    func handleStateTransitionToPauseWaitingPeriod() {
        hideAllViewsHelper()
        countdownTimer.isHidden = false
        countdownTimer.start(beginingValue: pauseWaitingPeriod, interval: 1)
        delayTransition()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(pauseWaitingPeriod)) {
            self.countdownTimer.isHidden = true
            self.pauseTracking()
        }
    }
    
    func handleStateTransitionToCompletingPauseProcedure() {
        // TODO: we should not be able to create a route landmark if we are in the relocalizing state... (might want to handle this when the user stops navigation on a route they loaded.... This would obviate the need to handle this in the recordPath code as well
        if creatingRouteLandmark {
            guard let currentTransform = sceneView.session.currentFrame?.camera.transform else {
                print("can't properly save landmark: TODO communicate this to the user somehow")
                return
            }
            beginRouteLandmarkTransform = currentTransform
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(playSound)), userInfo: nil, repeats: false)
            pauseTrackingView.isHidden = true
            state = .mainScreen(announceArrival: false)
            return
        } else if let currentTransform = sceneView.session.currentFrame?.camera.transform {
            sceneView.session.getCurrentWorldMap { worldMap, error in
                do {
                    self.endRouteLandmarkTransform = currentTransform
                    if self.routeName == nil {
                        // get a route name
                        self.showRouteNamingDialog(map: worldMap)
                    } else {
                        // TODO: factor this out
                        let id = String(Int64(NSDate().timeIntervalSince1970 * 1000)) as NSString
                        try self.archive(routeId: id, beginRouteLandmarkTransform: self.beginRouteLandmarkTransform, beginRouteLandmarkInformation: self.beginRouteLandmarkInformation, endRouteLandmarkTransform: self.endRouteLandmarkTransform, endRouteLandmarkInformation: self.endRouteLandmarkInformation, worldMap: worldMap)
                    }
                } catch {
                    fatalError("Can't save map: \(error.localizedDescription)")
                }
                self.showResumeTrackingButton()
                Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(self.playSound)), userInfo: nil, repeats: false)
                self.state = .pauseProcedureCompleted
            }
        }
    }
    
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
    
    func onRouteTableViewCellClicked(route: SavedRoute, navigateStartToEnd: Bool) {
        let worldMap = dataPersistence.unarchive(id: route.id as String)
        hideAllViewsHelper()
        state = .startingResumeProcedure(route: route, map: worldMap, navigateStartToEnd: navigateStartToEnd)
    }
    
    func archive(routeId: NSString, beginRouteLandmarkTransform: simd_float4x4?, beginRouteLandmarkInformation: NSString?, endRouteLandmarkTransform: simd_float4x4?, endRouteLandmarkInformation: NSString?, worldMap: ARWorldMap?) throws {
        let savedRoute = SavedRoute(id: routeId, name: routeName!, crumbs: crumbs, dateCreated: Date() as NSDate, beginRouteLandmarkTransform: beginRouteLandmarkTransform, beginRouteLandmarkInformation: beginRouteLandmarkInformation, endRouteLandmarkTransform: endRouteLandmarkTransform, endRouteLandmarkInformation: endRouteLandmarkInformation)
        try dataPersistence.archive(route: savedRoute, worldMap: worldMap)
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

    let thumbsDownButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "thumbs_down")!), label: "Bad", targetSelector: Selector.thumbsDownButtonTapped, alignment: .leftcenter, tag: 0)
    
    let thumbsUpButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "thumbs_up")!), label: "Good", targetSelector: Selector.thumbsUpButtonTapped, alignment: .rightcenter, tag: 0)
    
    let resumeButton = ActionButtonComponents(appearance: .textButton(label: "Resume"), label: "Resume", targetSelector: Selector.resumeButtonTapped, alignment: .center, tag: 0)
    
    let enterLandmarkDescriptionButton = ActionButtonComponents(appearance: .textButton(label: "Describe"), label: "Enter information to help you remember this landmark", targetSelector: Selector.enterLandmarkDescriptionButtonTapped, alignment: .left, tag: 0)
    
    let confirmAlignmentButton = ActionButtonComponents(appearance: .textButton(label: "Align"), label: "Start 5-second alignment countdown", targetSelector: Selector.confirmAlignmentButtonTapped, alignment: .center, tag: 0)
    
    
    /// Image, label, and target for start recording button.
    /// TODO: need an image
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
    let routesButton = ActionButtonComponents(appearance: .textButton(label: "Routes"), label: "Saved Routes List", targetSelector: Selector.routesButtonTapped, alignment: .left, tag: 0)

    /// A handle to the Firebase storage
    let storageBaseRef = Storage.storage().reference()
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

    /// A UUID for the current device (note: this can change in various circumstances, so we should be wary of using this, see: https://developer.apple.com/documentation/uikit/uidevice#//apple_ref/occ/instp/UIDevice/identifierForVendor)
    let deviceID = UIDevice.current.identifierForVendor
    
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
    
    var buttonFrameHeight: CGFloat {
        // height of button frame
        return UIScreen.main.bounds.size.height * (1/5)
    }
    
    var settingsAndHelpFrameHeight: CGFloat {
        // height of button frame
        return UIScreen.main.bounds.size.height * (1/12)
    }
    
    var settingsAndHelpMargin: CGFloat {
        // height of button frame
        return UIScreen.main.bounds.size.height * (1/24)
    }
    
    var displayWidth: CGFloat {
        return UIScreen.main.bounds.size.width
    }
    
    var displayHeight: CGFloat {
        return UIScreen.main.bounds.size.height
    }
    
    var textLabelBuffer: CGFloat {
        // top margin of direction text label
        return buttonFrameHeight * (1/12)
    }
    
    var yOriginOfGetDirectionsButton: CGFloat {
        // y-origin of button frame
        return UIScreen.main.bounds.size.height - settingsAndHelpFrameHeight - settingsAndHelpMargin
    }
    
    var yOriginOfSettingsAndHelpButton: CGFloat {
        // y-origin of button frame
        return UIScreen.main.bounds.size.height - settingsAndHelpFrameHeight - settingsAndHelpMargin
    }
    
    var yOriginOfButtonFrame: CGFloat {
        // y-origin of button frame
        return UIScreen.main.bounds.size.height - buttonFrameHeight - settingsAndHelpFrameHeight - settingsAndHelpMargin
    }
    
    var yOriginOfAnnouncementFrame: CGFloat {
        return UIScreen.main.bounds.size.height/15
    }
    
    /*
     * UIViews for all UI button containers
     */
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
    }
    
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
    
    func loadAssets() {
        let url = NSURL(fileURLWithPath: Bundle.main.path(forResource: "Crumb", ofType: "obj")!)
        let asset = MDLAsset(url: url as URL)
        keypointObject = asset.object(at: 0)
    }
    
    func setupFirebaseObservers() {
        let responsePathRef = databaseHandle.reference(withPath: "config/" + deviceID!.uuidString)
        responsePathRef.observe(.childChanged) { (snapshot) -> Void in
            self.handleNewConfig(snapshot: snapshot)
        }
        responsePathRef.observe(.childAdded) { (snapshot) -> Void in
            self.handleNewConfig(snapshot: snapshot)
        }
    }
    
    func handleNewConfig(snapshot: DataSnapshot) {
        if snapshot.key == "adjust_offset", let newValue = snapshot.value as? Bool {
            self.adjustOffset = newValue
            if !self.adjustOffset {
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
    }
    
    func showRecordPathWithoutLandmarkWarning() {
        let userDefaults: UserDefaults = UserDefaults.standard
        let showedRecordPathWithoutLandmarkWarning: Bool? = userDefaults.object(forKey: "showedRecordPathWithoutLandmarkWarning") as? Bool
        if showedRecordPathWithoutLandmarkWarning == nil && beginRouteLandmarkTransform == nil {
            userDefaults.set(true, forKey: "showedRecordPathWithoutLandmarkWarning")
            // Show logging disclaimer when user opens app for the first time
            let alert = UIAlertController(title: "Creating reusable routes",
                                          message: "If you would like to be able to navigate along the forward direction of this route again, you must create a landmark before starting your recording.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue with single-use recording", style: .default, handler: { action -> Void in
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
        if showedNavigatePathWithoutLandmarkWarning == nil && endRouteLandmarkTransform == nil {
            userDefaults.set(true, forKey: "showedNavigatePathWithoutLandmarkWarning")
            // Show logging disclaimer when user opens app for the first time
            let alert = UIAlertController(title: "Creating reusable routes",
                                          message: "If you would like to be able to navigate along the reverse direction of this route again, you must activate the pause button before navigating the route.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue with single-use navigation", style: .default, handler: { action -> Void in
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
    @objc func showRouteNamingDialog(map: ARWorldMap?) {
        // Set title and message for the alert dialog
        justUsedMap = map

        let alertController = UIAlertController(title: "Save route", message: "Enter the name of the route", preferredStyle: .alert)
        // The confirm action taking the inputs
        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            let id = String(Int64(NSDate().timeIntervalSince1970 * 1000)) as NSString
            // Get the input values from user, if it's nil then use timestamp
            self.routeName = alertController.textFields?[0].text as NSString? ?? id
            try! self.archive(routeId: id, beginRouteLandmarkTransform: self.beginRouteLandmarkTransform, beginRouteLandmarkInformation: self.beginRouteLandmarkInformation, endRouteLandmarkTransform: self.endRouteLandmarkTransform, endRouteLandmarkInformation: self.endRouteLandmarkInformation, worldMap: map)
        }
            
        // The cancel action saves the just traversed route so you can navigate back along it later
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.justTraveledRoute = SavedRoute(id: "dummyid", name: "Last route", crumbs: self.crumbs, dateCreated: Date() as NSDate, beginRouteLandmarkTransform: self.beginRouteLandmarkTransform, beginRouteLandmarkInformation: self.beginRouteLandmarkInformation, endRouteLandmarkTransform: self.endRouteLandmarkTransform, endRouteLandmarkInformation: self.endRouteLandmarkInformation)
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
        let alertController = UIAlertController(title: "Landmark information", message: "Enter information about the landmark that will help you find it later.", preferredStyle: .alert)
        // The confirm action taking the inputs
        let saveAction = UIAlertAction(title: "Ok", style: .default) { (_) in
            if self.creatingRouteLandmark {
                self.beginRouteLandmarkInformation = alertController.textFields?[0].text as NSString?
            } else {
                self.endRouteLandmarkInformation = alertController.textFields?[0].text as NSString?
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
        pauseTrackingView.setupButtonContainer(withButtons: [enterLandmarkDescriptionButton, confirmAlignmentButton], withMainText: "Landmarks allow you to save or pause your route. You will need to to return to the landmark on your own to load or unpause your route. When creating a landmark, hold your device flat with the screen facing up. Press the top (short) edge flush against a flat vertical surface (such as a wall). The \"describe\" button lets you enter information to help you remember the location of the landmark. The \"align\" button starts a \(pauseWaitingPeriod)-second alignment countdown. During this time, do not move the device until the phone provides confirmation via a vibration or sound cue.")
        
        resumeTrackingView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        resumeTrackingView.setupButtonContainer(withButtons: [resumeButton], withMainText: "Return to the last paused location and press Resume for further instructions.")
        
        resumeTrackingConfirmView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        resumeTrackingConfirmView.setupButtonContainer(withButtons: [confirmAlignmentButton], withMainText: "Hold your device flat with the screen facing up. Press the top (short) edge flush against the same vertical surface that you used to create the landmark.  When you are ready, activate the align button to start the \(resumeWaitingPeriod)-second alignment countdown that will complete the procedure. Do not move the device until the phone provides confirmation via a vibration or sound cue.")

        // Stop Navigation button container
        stopNavigationView = UIView(frame: CGRect(x: 0, y: yOriginOfButtonFrame, width: buttonFrameWidth, height: buttonFrameHeight))
        stopNavigationView.setupButtonContainer(withButtons: [stopNavigationButton])
        
        routeRatingView = UIView(frame: CGRect(x: 0, y: 0, width: buttonFrameWidth, height: displayHeight))
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
        if navigateStartToEnd {
            if let landmarkInformation = route.beginRouteLandmarkInformation as String? {
                resumeTrackingConfirmView.mainText?.text?.append("The landmark information you entered is: " + landmarkInformation + ".\n\n")
            }
        } else {
            if let landmarkInformation = route.endRouteLandmarkInformation as String? {
                resumeTrackingConfirmView.mainText?.text?.append("The landmark information you entered is: " + landmarkInformation + ".\n\n")
            }
        }
        resumeTrackingConfirmView.mainText?.text?.append("Hold your device flat with the screen facing up. Press the top (short) edge flush against the same vertical surface that you used to create the landmark.  When you are ready, activate the align button to start the \(resumeWaitingPeriod)-second alignment countdown that will complete the procedure. Do not move the device until the phone provides confirmation via a vibration or sound cue.")
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
            speechData.append(altText)
            speechDataTime.append(roundToThousandths(-dataTimer.timeIntervalSinceNow))
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
    
    // internal debug logging datastructure
    var stateTransitionLogTimer = Date()        // timer for logging state transitions
    var dataTimer = Date()                        // timer to sync data
    var pathData: [[Float]] = []                // path data taken during RECORDPATH - [[1x16 transform matrix]]
    var pathDataTime: [Double] = []               // time stamps for pathData
    var navigationData: [[Float]] = []          // path data taken during NAVIGATION - [[1x16 transform matrix]]
    var navigationDataTime: [Double] = []         // time stamps for navigationData
    var speechData: [String] = []                   // description data during NAVIGATION
    var speechDataTime: [Double] = []               // time stamp for speechData
    var keypointData: [Array<Any>] = []             // list of keypoints - [[(LocationInfo)x, y, z, yaw]]
    var trackingErrorData: [String] = []            // list of tracking errors ["InsufficientFeatures", "ExcessiveMotion"]
    var trackingErrorTime: [Double] = []            // time stamp of tracking error
    var trackingErrorPhase: [Bool] = []             // tracking phase - true: recording, false: navigation
    var stateSequence: [String] = []                   // all state transitions the app went through
    var stateSequenceTime: [Double] = []            // time stamp of state transitions
    
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
    
    // TODO: refactor these into a class to ease the handling of these
    var beginRouteLandmarkTransform: simd_float4x4?
    var beginRouteLandmarkInformation: NSString?

    var endRouteLandmarkTransform: simd_float4x4?
    var endRouteLandmarkInformation: NSString?

    var routeName: NSString?

    var justTraveledRoute: SavedRoute?
    var justUsedMap: ARWorldMap?
    
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
        if let beginRouteLandmarkTransform = beginRouteLandmarkTransform {
            sceneView.session.getCurrentWorldMap { worldMap, error in
                if self.routeName == nil {
                    // get a route name
                    self.showRouteNamingDialog(map: worldMap)
                } else {
                    let id = String(Int64(NSDate().timeIntervalSince1970 * 1000)) as NSString
                    try! self.archive(routeId: id, beginRouteLandmarkTransform: beginRouteLandmarkTransform, beginRouteLandmarkInformation: self.beginRouteLandmarkInformation, endRouteLandmarkTransform: self.endRouteLandmarkTransform, endRouteLandmarkInformation: self.endRouteLandmarkInformation, worldMap: worldMap)
                }
            }
        }

        state = .readyToNavigateOrPause(allowPause: true)
    }
    
    @objc func startNavigation(_ sender: UIButton) {
        // this will handle the appropriate state transition if we pass the warning
        showNavigatePathWithoutLandmarkWarning()
    }
    
    /// This helper function will restart the tracking session if a relocalization was in progress but did not succeed.  This is useful in the case when you want to allow for the recording of a new route and don't want to have the possibility achieving relocalization halfway through recording the route.
    func restartSessionIfFailedToRelocalize() {
        if attemptingRelocalization {
            announce(announcement: "Restarting tracking session.")
            configuration.initialWorldMap = nil
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
        
        // erase neariest keypoint
        keypointNode.removeFromParentNode()
        
        if(sendLogs) {
            state = .ratingRoute(announceArrival: false)
        } else {
            state = .mainScreen(announceArrival: false)
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
        countdownTimer.start(beginingValue: pauseWaitingPeriod, interval: 1)
        delayTransition()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(resumeWaitingPeriod)) {
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
                self.state = .readyToNavigateOrPause(allowPause: false)
            }
        }
    }
    
    @objc func confirmResumeTracking() {
        if let route = justTraveledRoute {
            state = .startingResumeProcedure(route: route, map: justUsedMap, navigateStartToEnd: false)
        }
    }
    
    // MARK: - Logging
    @objc func sendLogData() {
        // send success log data to Firebase
        compileLogData(false)
        state = .mainScreen(announceArrival: false)
    }
    
    @objc func sendDebugLogData() {
        // send debug log data to Firebase
        compileLogData(true)
        state = .mainScreen(announceArrival: false)
    }
    
    func compileLogData(_ debug: Bool) {
        // compile log data
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let pathDate = dateFormatter.string(from: date)
        let pathID = deviceID!.uuidString + dateFormatter.string(from: date)
        let userId = deviceID!.uuidString
        print("USER ID", userId)
        
        sendMetaData(pathDate, pathID+"-0", userId, debug)
        sendPathData(pathID, userId)
        
        // reset log variables that aren't tied to path recording or navigation
        stateSequence = []
        stateSequenceTime = []
    }
    
    func sendMetaData(_ pathDate: String, _ pathID: String, _ userId: String, _ debug: Bool) {
        let pathType: String
        if(debug) {
            pathType = "debug"
        } else {
            pathType = "success"
        }
        
        let body: [String : Any] = ["userId": userId,
                                    "PathID": pathID,
                                    "PathDate": pathDate,
                                    "PathType": pathType,
                                    "keypointData": keypointData,
                                    "trackingErrorPhase": trackingErrorPhase,
                                    "trackingErrorTime": trackingErrorTime,
                                    "trackingErrorData": trackingErrorData,
                                    "stateSequence": stateSequence,
                                    "stateSequenceTime": stateSequenceTime]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            // here "jsonData" is the dictionary encoded in JSON data
            let storageRef = storageBaseRef.child(userId + "_" + pathID + "_metadata.json")
            let fileType = StorageMetadata()
            fileType.contentType = "application/json"
            // upload the image to Firebase storage and setup auto snapshotting
            storageRef.putData(jsonData, metadata: fileType) { (metadata, error) in
                guard metadata != nil else {
                    // Uh-oh, an error occurred!
                    print("could not upload meta data to firebase", error!.localizedDescription)
                    return
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func sendPathData(_ pathID: String, _ userId: String) {
        let body: [String : Any] = ["userId": userId,
                                    "PathID": pathID,
                                    "PathDate": "0",
                                    "PathType": "0",
                                    "PathData": pathData,
                                    "pathDataTime": pathDataTime,
                                    "navigationData": navigationData,
                                    "navigationDataTime": navigationDataTime,
                                    "speechData": speechData,
                                    "speechDataTime": speechDataTime]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            // here "jsonData" is the dictionary encoded as a JSON
            let storageRef = storageBaseRef.child(userId + "_" + pathID + "_pathdata.json")
            let fileType = StorageMetadata()
            fileType.contentType = "application/json"
            // upload the image to Firebase storage and setup auto snapshotting
            storageRef.putData(jsonData, metadata: fileType) { (metadata, error) in
                guard metadata != nil else {
                    // Uh-oh, an error occurred!
                    print("could not upload path data to firebase", error!.localizedDescription)
                    return
                }
            }
        } catch {
            print(error.localizedDescription)
        }
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
                print("New offset", newOffset)
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
    
    func shouldAnnounceTurnWarning(_ direction: DirectionInfo) -> Bool {
        // check if app should make a turn warning annoucement
        return direction.targetState == PositionState.closeToTarget &&
            !turnWarning &&
            keypoints.count > 1 &&
            sqrtf(powf(Float(keypoints[0].location.x - prevKeypointPosition.x),2) + powf(Float(keypoints[0].location.z - prevKeypointPosition.z),2)) >= 6
    }
    /* disabled for now
    func announceTurnWarning(_ currentLocation: CurrentCoordinateInfo) {
        // announce upcoming turn
        var dir = nav.getTurnWarningDirections(currentLocation, nextKeypoint: keypoints[0], secondKeypoint: keypoints[1])
        if(defaultUnit == 0) {
            // convert to imperial units
            dir.distance *= 3.28084
        }
        dir.distance = roundToTenths(dir.distance)
        turnWarning = true
        setTurnWarningText(currentLocation: currentLocation.location, direction: dir)
    }*/
    
    /// Communicates a message to the user via speech.  If VoiceOver is active, then VoiceOver is used
    /// to communicate the announcement, otherwise we use the AVSpeechEngine
    ///
    /// - Parameter announcement: the text to read to the user
    func announce(announcement: String) {
        announcementText.isHidden = false
        announcementText.text = announcement
        announcementRemovalTimer?.invalidate()
        announcementRemovalTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { timer in
            self.announcementText.isHidden = true
        }
        if UIAccessibility.isVoiceOverRunning {
            // use the VoiceOver API instead of text to speech
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: announcement)
        } else if voiceFeedback {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSession.Category.playback)
                try audioSession.setActive(true)
                let utterance = AVSpeechUtterance(string: announcement)
                utterance.rate = 0.6
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

        self.present(nav, animated: true, completion: nil)
    }
    
    @objc func announceDirectionHelp() {
        // announce directions at any given point to the next keypoint
        if case .navigatingRoute = state, let curLocation = getRealCoordinates(record: false) {
            let directionToNextKeypoint = getDirectionToNextKeypoint(currentLocation: curLocation)
            setDirectionText(currentLocation: curLocation.location, direction: directionToNextKeypoint, displayDistance: true)
        }
    }
    
    func setTurnWarningText(currentLocation: LocationInfo, direction: DirectionInfo) {
        // update display text for text label and VoiceOver
        let xzNorm = sqrtf(powf(currentLocation.x - keypoints[0].location.x, 2) + powf(currentLocation.z - keypoints[0].location.z, 2))
        let slope = (keypoints[1].location.y - keypoints[0].location.y) / xzNorm
        var dir = ""
        
        if(slope > 0.3) { // Go upstairs
            if(hapticFeedback) {
                dir += "\(TurnWarnings[direction.hapticDirection]!) and proceed upstairs"
            } else {
                dir += "\(TurnWarnings[direction.clockDirection]!) and proceed upstairs"
            }
            updateDirectionText(dir, distance: 0, displayDistance: false)
        } else if (slope < -0.3) { // Go downstairs
            if(hapticFeedback) {
                dir += "\(TurnWarnings[direction.hapticDirection]!) and proceed downstairs"
            } else {
                dir += "\(TurnWarnings[direction.clockDirection]!) and proceed downstairs"
            }
            updateDirectionText(dir, distance: direction.distance, displayDistance: false)
        } else { // nromal directions
            if(hapticFeedback) {
                dir += "\(TurnWarnings[direction.hapticDirection]!)"
            } else {
                dir += "\(TurnWarnings[direction.clockDirection]!)"
            }
            updateDirectionText(dir, distance: direction.distance, displayDistance:  false)
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
            let logMatrix = [round10k(scn.m11), round10k(scn.m12), round10k(scn.m13), round10k(scn.m14),
             round10k(scn.m21), round10k(scn.m22), round10k(scn.m23), round10k(scn.m24),
             round10k(scn.m31), round10k(scn.m32), round10k(scn.m33), round10k(scn.m34),
             round10k(scn.m41), round10k(scn.m42), round10k(scn.m43), round10k(scn.m44)]
            let logTime = roundToThousandths(-dataTimer.timeIntervalSinceNow)
            if case .navigatingRoute = state {
                navigationData.append(logMatrix)
                navigationDataTime.append(logTime)
            } else {
                pathData.append(logMatrix)
                pathDataTime.append(logTime)
            }
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
                announce(announcement: "Excessive motion.\nTracking performance is degraded.")
                if soundFeedback {
                    playSystemSound(id: 1050)
                }
            case .insufficientFeatures:
                logString = "InsufficientFeatures"
                print("InsufficientFeatures")
                announce(announcement: "Insufficient visual features.\nTracking performance is degraded.")
                if soundFeedback {
                    playSystemSound(id: 1050)
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
            if configuration.initialWorldMap != nil, attemptingRelocalization {
                announce(announcement: "Successfully matched current environment to saved route.")
                attemptingRelocalization = false
            } else if case let .limited(reason)? = trackingSessionState {
                if reason == .initializing {
                    announce(announcement: "Tracking session initialized.")
                } else {
                    announce(announcement: "Tracking performance normal.")
                    if soundFeedback {
                        playSystemSound(id: 1025)
                    }
                }
            }
            // resetting the origin is needed in the case when we realigned to a saved route
            session.setWorldOrigin(relativeTransform: simd_float4x4.makeTranslation(0,0,0))
            if case .readyForFinalResumeAlignment = state {
                // this will cancel any realignment if it hasn't happened yet and go straight to route navigation mode
                countdownTimer.isHidden = true
                state = .readyToNavigateOrPause(allowPause: false)
            }
            print("normal")
        case .notAvailable:
            logString = "NotAvailable"
            print("notAvailable")
        }
        if let logString = logString {
            if case .recordingRoute = state {
                trackingErrorPhase.append(true)
                trackingErrorTime.append(roundToThousandths(-dataTimer.timeIntervalSinceNow))
                trackingErrorData.append(logString)
            } else if case .navigatingRoute = state {
                trackingErrorPhase.append(false)
                trackingErrorTime.append(roundToThousandths(-dataTimer.timeIntervalSinceNow))
                trackingErrorData.append(logString)
            }
        }
        // update the tracking state so we can use it in the next call to this function
        trackingSessionState = camera.trackingState
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
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
