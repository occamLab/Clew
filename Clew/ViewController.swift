//
//  ViewController.swift
//  ARKitTest
//
//  Created by Chris Seonghwan Yoon & Jeremy Ryan on 7/10/17.
//

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


// MARK: Extensions
extension UIView {
    
    /// Custom fade used for direction text UILabel.
    func fadeTransition(_ duration:CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = kCATransitionPush
        animation.subtype = kCATransitionFromTop
        animation.duration = duration
        layer.add(animation, forKey: kCATransitionFade)
    }
    
    /// Configures a button container view and adds a button.
    ///
    /// - Parameter buttonComponents: holds information about the button to add
    ///
    /// - TODO: generalize for code reuse with the other kinds of subview containers in this app
    func setupButtonContainer(withButton buttonComponents: ActionButtonComponents) {
        self.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        self.isHidden = true
        let button = UIButton.makeImageButton(self, buttonComponents)
        self.addSubview(button)
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
        let buttonWidth = containerView.bounds.size.width / 4.5
        
        let button = UIButton(type: .custom)
        
        button.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: buttonWidth)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        button.center.x = containerView.center.x
        button.center.y = containerView.bounds.size.height * (6/10)
        
        button.setImage(buttonViewParts.image, for: .normal)
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
}

/// Holds information about the buttons that are used to control navigation and tracking.
///
/// These button attributes are the only ones unique to each of these buttons.
public struct ActionButtonComponents {
    
    /// Button image
    var image: UIImage
    
    /// Accessibility label
    var label: String
    
    /// Function to call when the button is tapped
    ///
    /// - TODO: Potentially unnecessary when the transitioning between views is refactored.
    var targetSelector: Selector
}

// TODO: it would be cool to add the state of some of these transitions using indirect enumerations https://docs.swift.org/swift-book/LanguageGuide/Enumerations.html

enum AppState {
    /// This is the screen the comes up immediately after the splash screen
    case mainScreen(announceArrival: Bool)
    /// User is recording the
    case recordingRoute
    /// User can either navigate back or pause
    case readyToNavigateOrPause
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
    case startingResumeProcedure
    /// the AR session has entered the relocalizing state, which means that we can now realign the session
    case readyForFinalResumeAlignment
}

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - Refactoring UI definition
    
    // MARK: Properties and subview declarations
    
    /// How long to wait (in seconds) between the volume press and grabbing the transform for pausing
    let pauseWaitingPeriod = 2
    
    /// How long to wait (in seconds) between the volume press and resuming the tracking session based on physical alignment
    let resumeWaitingPeriod = 5
    
    /// The state of the app.  This should be constantly referenced and updated as the app transitions
    var state = AppState.initializing {
        didSet {
            switch state {
            case .recordingRoute:
                handleStateTransitionToRecordingRoute()
            case .readyToNavigateOrPause:
                handleStateTransitionToReadyToNavigateOrPause()
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
            case .startingResumeProcedure:
                handleStateTransitionToStartingResumeProcedure()
            case .readyForFinalResumeAlignment:
                // nothing happens currently
                break
            case .initializing:
                break
            }
        }
    }
    
    func handleStateTransitionToMainScreen(announceArrival: Bool) {
        showRecordPathButton(announceArrival: announceArrival)
    }
    
    func handleStateTransitionToRecordingRoute() {
        // records a new path
        
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
    
    func handleStateTransitionToReadyToNavigateOrPause() {
        droppingCrumbs?.invalidate()
        updateHeadingOffsetTimer?.invalidate()
        showStartNavigationButton()
    }
    
    func handleStateTransitionToNavigatingRoute() {
        // navigate the recorded path
        
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
        followingCrumbs = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: (#selector(followCrumb)), userInfo: nil, repeats: true)
        
        feedbackTimer = Date()
        // make sure there are no old values hanging around
        headingRingBuffer.clear()
        locationRingBuffer.clear()
        hapticTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: (#selector(getHapticFeedback)), userInfo: nil, repeats: true)
    }
    
    func handleStateTransitionToRatingRoute(announceArrival: Bool) {
        showRouteRating(announceArrival: announceArrival)
    }
    
    func handleStateTransitionToStartingResumeProcedure() {
        if #available(iOS 12.0, *) {
            // load the world map and restart the session so that things have a chance to quiet down before putting it up to the wall
            guard let worldMapData = retrieveWorldMapData(id: "hardcodedroute"),
                let pausedWorldMapRetrieved = unarchive(worldMapData: worldMapData),
                let savedRouteUnarchived = unarchiveSavedRoute()
                else {
                    
                    return
            }
            pausedTransform = savedRouteUnarchived.pausedTransform
            configuration.initialWorldMap = pausedWorldMapRetrieved
            crumbs = savedRouteUnarchived.crumbs
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
        showResumeTrackingConfirmButton()
    }
    
    func handleStateTransitionToStartingPauseProcedure() {
        do {
            try showPauseTrackingButton()
        } catch {
            // nothing to fall back on
        }
    }
    
    func handleStateTransitionToPauseWaitingPeriod() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(pauseWaitingPeriod)) {
            self.pauseTracking()
        }
    }
    
    func handleStateTransitionToCompletingPauseProcedure() {
        if #available(iOS 12.0, *), let currentTransform = sceneView.session.currentFrame?.camera.transform {
            sceneView.session.getCurrentWorldMap { worldMap, error in
                if worldMap != nil {
                    do {
                        try self.archive(landmarkTransform: currentTransform, worldMap: worldMap!)
                    } catch {
                        fatalError("Can't save map: \(error.localizedDescription)")
                    }
                    self.handleStateTransitionToCompletingPauseProcedureHelper()
                } else {
                    print("An error occurred getting the world map")
                }
            }
        } else {
            sceneView.session.pause()
            handleStateTransitionToCompletingPauseProcedureHelper()
        }
        
    }
    
    func handleStateTransitionToCompletingPauseProcedureHelper() {
        self.showResumeTrackingButton()
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(playSound)), userInfo: nil, repeats: false)
        state = .pauseProcedureCompleted
    }
    
    @available(iOS 12.0, *)
    func archive(landmarkTransform: simd_float4x4, worldMap: ARWorldMap) throws {
        let savedRoute = SavedRoute(id: "hardcodedroute", name: "hardcodedroute", crumbs: crumbs, dateCreated: Date() as NSDate, pausedTransform: landmarkTransform)
        NSKeyedArchiver.archiveRootObject(savedRoute, toFile: self.worldMapURL(id: "hardcodedroute", isInfo: true).path)
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        try data.write(to: self.worldMapURL(id: "hardcodedroute", isInfo: false), options: [.atomic])
    }
    
    func retrieveWorldMapData(id: String) -> Data? {
        do {
            return try Data(contentsOf: worldMapURL(id: id, isInfo: false))
        } catch {
            print("Error retrieving world map data.")
            return nil
        }
    }
    
    @available(iOS 12.0, *)
    func unarchive(worldMapData data: Data) -> ARWorldMap? {
        guard let unarchivedObject = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data),
            let worldMap = unarchivedObject else { return nil }
        return worldMap
    }
    
    func unarchiveSavedRoute() -> SavedRoute? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: self.worldMapURL(id: "hardcodedroute", isInfo: true).path) as? SavedRoute
    }

    func worldMapURL(id: String, isInfo: Bool) -> URL {
        let fileName = isInfo ? "Info" : id
        return FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
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
    let recordPathButton = ActionButtonComponents(image: UIImage(named: "StartRecording")!, label: "Record path", targetSelector: Selector.recordPathButtonTapped)
    
    /// Image, label, and target for stop recording button.
    let stopRecordingButton = ActionButtonComponents(image: UIImage(named: "StopRecording")!, label: "Stop recording", targetSelector: Selector.stopRecordingButtonTapped)
    
    /// Image, label, and target for start navigation button.
    let startNavigationButton = ActionButtonComponents(image: UIImage(named: "StartNavigation")!, label: "Start navigation", targetSelector: Selector.startNavigationButtonTapped)

    /// Image, label, and target for stop navigation button.
    let stopNavigationButton = ActionButtonComponents(image: UIImage(named: "StopNavigation")!, label: "Stop navigation", targetSelector: Selector.stopNavigationButtonTapped)
    
    /// A handle to the Firebase storage
    let storageBaseRef = Storage.storage().reference()
    var databaseHandle = Database.database()
    
    // MARK: - Parameters that can be controlled remotely via Firebase
    
    /// True if the offset between direction of travel and phone should be updated over time
    var adjustOffset = false
    
    /// True if we should use a cone of pi/12 and false if we should use a cone of pi/6 when deciding whether to issue haptic feedback
    var strictHaptic = true

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
        return UIScreen.main.bounds.size.height - settingsAndHelpFrameHeight
    }
    
    var yOriginOfSettingsAndHelpButton: CGFloat {
        // y-origin of button frame
        return UIScreen.main.bounds.size.height - settingsAndHelpFrameHeight
    }
    
    var yOriginOfButtonFrame: CGFloat {
        // y-origin of button frame
        return UIScreen.main.bounds.size.height - buttonFrameHeight - settingsAndHelpFrameHeight
    }
    
    /*
     * UIViewss for all UI button containers
     */
    var getDirectionButton: UIButton!
    var settingsButton: UIButton!
    var helpButton: UIButton!
    var pauseTrackingView: UIView!
    var resumeTrackingView: UIView!
    var resumeTrackingConfirmView: UIView!
    var directionText: UILabel!
    var routeRatingView: UIView!
    var routeRatingLabel: UILabel?
    
    enum ButtonViewType {
        // State of button views
        case recordPath
        case stopRecording
        case startNavigation
        case pauseTracking
        case resumeTracking
        case stopNavigation
    }
    
    var currentButton = ButtonViewType.recordPath
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Scene view setup
        sceneView.frame = view.frame
        view.addSubview(sceneView)

        createSettingsBundle()
        listenVolumeButton()
        createARSession()
        drawUI()
        addGestures()
        setupFirebaseObservers()
        
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(printCameraTransform)), userInfo: nil, repeats: true)
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
        if #available(iOS 11.3, *) {
            configuration.planeDetection = [.horizontal, .vertical]
        } else {
            // Fallback on earlier versions
            configuration.planeDetection = .horizontal
        }
        sceneView.session.run(configuration)
        sceneView.delegate = self
    }
    
    /*
     * Setup volume listener
     */
    let audioSession = AVAudioSession.sharedInstance()
    func listenVolumeButton() {
        // TODO: this causes it to be impossible to adjust the volume in the app, which is probably not desirable (need to pass this through somehow)
        let volumeView: MPVolumeView = MPVolumeView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        view.addSubview(volumeView)
        // Note: the commented out code below doesn't fire an event if the volume is at the max or min volume level (the notification center one does though)
        //audioSession.addObserver(self, forKeyPath: "outputVolume", options: [.initial, .new], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged), name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)

    }
    
    @objc func volumeChanged(notification: NSNotification) {
        if case .startingPauseProcedure = state {
            state = .pauseWaitingPeriod
        } else if case .startingResumeProcedure = state {
            resumeTracking()
        } else if case .readyForFinalResumeAlignment = state {
            resumeTracking()
        } else if case .mainScreen = state {
            // TODO: this is just a placeholder UI
            recordPathView.isHidden = true
            // the options button is hidden if the route rating shows up
            directionText.isHidden = true
            // hard code this for now (no UI yet)
            state = .startingResumeProcedure
        }
    }
    
    var player: AVAudioPlayer?
    @objc func playSound() {
        // XXX should use a system sound instead
        // guard let url = Bundle.main.url(forResource: "Confirm", withExtension: "mp3") else { return }
        
        feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator?.impactOccurred()
        feedbackGenerator = nil
       /*
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            
            player.play()
            try AVAudioSession.sharedInstance().setActive(false)
        } catch let error {
            print(error.localizedDescription)
        }*/
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
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 28.0)
        settingsButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        settingsButton.addTarget(self, action: #selector(settingsButtonPressed), for: .touchUpInside)

        // button that shows help menu
        helpButton = UIButton(frame: CGRect(x: buttonFrameWidth/2, y: yOriginOfSettingsAndHelpButton, width: buttonFrameWidth/2, height: settingsAndHelpFrameHeight))
        helpButton.isAccessibilityElement = true
        helpButton.setTitle("Help", for: .normal)
        helpButton.titleLabel?.font = UIFont.systemFont(ofSize: 28.0)
        helpButton.accessibilityLabel = "Help"
        helpButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        helpButton.addTarget(self, action: #selector(helpButtonPressed), for: .touchUpInside)
        
        // button that gives direction to the nearist keypoint
        getDirectionButton = UIButton(frame: CGRect(x: 0, y: 0, width: buttonFrameWidth, height: yOriginOfButtonFrame))
        getDirectionButton.isAccessibilityElement = true
        getDirectionButton.accessibilityLabel = "Get Directions"
        getDirectionButton.isHidden = true
        getDirectionButton.addTarget(self, action: #selector(announceDirectionHelpPressed), for: .touchUpInside)

        // textlabel that displys directions
        directionText = UILabel(frame: CGRect(x: 0, y: (yOriginOfButtonFrame + textLabelBuffer), width: buttonFrameWidth, height: buttonFrameHeight*(1/6)))
        directionText.textColor = UIColor.white
        directionText.textAlignment = .center
        directionText.isAccessibilityElement = true
        
        
        // Record Path button container
        recordPathView = UIView(frame: CGRect(x: 0, y: yOriginOfButtonFrame, width: buttonFrameWidth, height: buttonFrameHeight))
        recordPathView.setupButtonContainer(withButton: recordPathButton)
        
        // Stop Recording button container
        stopRecordingView = UIView(frame: CGRect(x: 0, y: yOriginOfButtonFrame, width: buttonFrameWidth, height: buttonFrameHeight))
        stopRecordingView.setupButtonContainer(withButton: stopRecordingButton)
        
        // Start Navigation button container
        startNavigationView = UIView(frame: CGRect(x: 0, y: yOriginOfButtonFrame, width: buttonFrameWidth, height: buttonFrameHeight))
        startNavigationView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        startNavigationView.isHidden = true
        addButtons(buttonView: startNavigationView)
        
        
        pauseTrackingView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        pauseTrackingView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        pauseTrackingView.isHidden = true
        drawPauseTrackingView()
        
        resumeTrackingView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        resumeTrackingView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        resumeTrackingView.isHidden = true
        drawResumeTrackingView()
        
       resumeTrackingConfirmView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        resumeTrackingConfirmView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        resumeTrackingConfirmView.isHidden = true
        drawResumeTrackingConfirmView()
        
        // Stop Navigation button container
        stopNavigationView = UIView(frame: CGRect(x: 0, y: yOriginOfButtonFrame, width: buttonFrameWidth, height: buttonFrameHeight))
        stopNavigationView.setupButtonContainer(withButton: stopNavigationButton)
        
        routeRatingView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        routeRatingView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        drawRouteRatingView()
        
        self.view.addSubview(recordPathView)
        self.view.addSubview(stopRecordingView)
        self.view.addSubview(startNavigationView)
        self.view.addSubview(pauseTrackingView)
        self.view.addSubview(resumeTrackingView)
        self.view.addSubview(resumeTrackingConfirmView)
        self.view.addSubview(stopNavigationView)
        self.view.addSubview(directionText)
        self.view.addSubview(getDirectionButton)
        self.view.addSubview(settingsButton)
        self.view.addSubview(helpButton)
        self.view.addSubview(routeRatingView)
        
        state = .mainScreen(announceArrival: false)
    }
    
    func drawRouteRatingView() {
        self.routeRatingLabel = UILabel(frame: CGRect(x: 0, y: displayHeight/2.5, width: displayWidth, height: displayHeight/6))
        routeRatingLabel?.text = "Rate your service."
        routeRatingLabel?.textColor = UIColor.white
        routeRatingLabel?.textAlignment = .center
        
        let buttonWidth = routeRatingView.bounds.size.width / 4.5
        
        let thumbsUpButton = UIButton(type: .custom)
        thumbsUpButton.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: buttonWidth)
        thumbsUpButton.layer.cornerRadius = 0.5 * thumbsUpButton.bounds.size.width
        thumbsUpButton.clipsToBounds = true
        let thumbsUpButtonImage = UIImage(named: "thumbs_up")
        thumbsUpButton.setImage(thumbsUpButtonImage, for: .normal)
        thumbsUpButton.accessibilityLabel = "Good"
        thumbsUpButton.center.x = routeRatingView.center.x + displayWidth/5
        thumbsUpButton.center.y = routeRatingView.bounds.size.height * (2/3)
        thumbsUpButton.addTarget(self, action: #selector(sendLogData), for: .touchUpInside)
        
        let thumbsDownButton = UIButton(type: .custom)
        thumbsDownButton.frame = CGRect(x: 0, y: 0, width: buttonWidth , height: buttonWidth)
        thumbsDownButton.layer.cornerRadius = 0.5 * thumbsUpButton.bounds.size.width
        thumbsDownButton.clipsToBounds = true
        let thumbsDownButtonImage = UIImage(named: "thumbs_down")
        thumbsDownButton.setImage(thumbsDownButtonImage, for: .normal)
        thumbsDownButton.accessibilityLabel = "Bad"
        thumbsDownButton.center.x = routeRatingView.center.x - displayWidth/5
        thumbsDownButton.center.y = routeRatingView.bounds.size.height * (2/3)
        thumbsDownButton.addTarget(self, action: #selector(sendDebugLogData), for: .touchUpInside)
        
        routeRatingView.addSubview(thumbsDownButton)
        routeRatingView.addSubview(thumbsUpButton)
        routeRatingView.addSubview(routeRatingLabel!)
    }
    
    func drawPauseTrackingView() {
        let label = UILabel(frame: CGRect(x: 15, y: displayHeight/3, width: displayWidth-30, height: displayHeight/4))
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        label.text = "Place the device against a flat vertical surface and press the volume button to pause. Do not move your phone until you feel a haptic confirmation. You will need to return to this surface to resume tracking. You can use other apps while in pause, but please keep the app running in the background."
        
        pauseTrackingView.addSubview(label)
    }
    
    func drawResumeTrackingView() {
        let label = UILabel(frame: CGRect(x: 15, y: displayHeight/2.5, width: displayWidth-30, height: displayHeight/6))
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        label.text = "Return to the last paused location and press Resume for further instructions."
        
        let buttonWidth = resumeTrackingView.bounds.size.width / 4.5
        
        let resumeButton = UIButton(type: .custom)
        resumeButton.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: buttonWidth)
        resumeButton.layer.cornerRadius = 0.5 * resumeButton.bounds.size.width
        resumeButton.clipsToBounds = true
        resumeButton.setTitle("Resume", for: .normal)
        resumeButton.layer.borderWidth = 2
        resumeButton.layer.borderColor = UIColor.white.cgColor
        resumeButton.center.x = pauseTrackingView.center.x
        resumeButton.center.y = pauseTrackingView.bounds.size.height * (4/5)
        resumeButton.addTarget(self, action: #selector(confirmResumeTracking), for: .touchUpInside)
        
        resumeTrackingView.addSubview(resumeButton)
        resumeTrackingView.addSubview(label)
    }
    
    func drawResumeTrackingConfirmView() {
        let label = UILabel(frame: CGRect(x: 15, y: displayHeight/2.5, width: displayWidth-30, height: displayHeight/6))
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        label.text = "Place the device in the same surface facing the same orientation and press the volume button to resume. Do not move the device until you feel the haptic confirmation."
        resumeTrackingConfirmView.addSubview(label)
    }
    
    /*
     * Adds buttons to given UIView container
     */
    /// Adds start navigation and pause buttons the `startNavigationView` button container.
    ///
    /// Largely vestigial. Should be refactored completely out of the code soon.
    ///
    /// - Parameter buttonView: `startNavigationView` button container
    func addButtons(buttonView: UIView) {
        let buttonWidth = buttonView.bounds.size.width / 4.5
        
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: buttonWidth , height: buttonWidth )
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        
        button.center.x = buttonView.center.x
        button.center.y = buttonView.bounds.size.height * (6/10)
        
        let buttonImage = UIImage(named: "StartNavigation")
        button.setImage(buttonImage, for: .normal)
        button.accessibilityLabel = "Start Navigation"
        button.addTarget(self, action: #selector(startNavigation), for: .touchUpInside)
        
        let pauseButton = UIButton(type: .custom)
        pauseButton.frame = CGRect(x: 0, y: 0, width: buttonWidth , height: buttonWidth )
        pauseButton.layer.cornerRadius = 0.5 * button.bounds.size.width
        pauseButton.clipsToBounds = true
        pauseButton.center.x = buttonView.center.x + displayWidth/3
        pauseButton.center.y = buttonView.bounds.size.height * (6/10)
        pauseButton.addTarget(self, action: #selector(startPauseProcedure), for: .touchUpInside)
        pauseButton.setTitle("Pause", for: .normal)
        pauseButton.layer.borderWidth = 2
        pauseButton.layer.borderColor = UIColor.white.cgColor
        
        buttonView.addSubview(pauseButton)
        buttonView.addSubview(button)
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

        directionText.isHidden = false
        routeRatingView.isHidden = true
        currentButton = .recordPath
        var helpText: String
        if announceArrival {
            helpText = "You've arrived. Press to record path"
        } else {
            helpText = "Press to record path"
        }
        updateDirectionText(helpText, distance: 0, size: 16, displayDistance: false)
        directionText.isAccessibilityElement = true
        
        delayTransition()
    }
    
    func delayTransition() {
        // this notification currently cuts off the announcement of the button that was just pressed
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
    }
    
    /*
     * display STOP RECORDIN button/hide all other views
     */
    @objc func showStopRecordingButton() {
        recordPathView.isHidden = true
        recordPathView.isAccessibilityElement = false
        stopRecordingView.isHidden = false
        currentButton = .stopRecording
        directionText.isAccessibilityElement = true
        updateDirectionText("Hold vertically with the rear camera facing forward.", distance: 0, size: 13, displayDistance: false)
        delayTransition()
    }
    
    /*
     * display START NAVIGATION button/hide all other views
     */
    @objc func showStartNavigationButton() {
        resumeTrackingConfirmView.isHidden = true
        stopRecordingView.isHidden = true
        startNavigationView.isHidden = false
        directionText.isHidden = false
        currentButton = .startNavigation
        directionText.isAccessibilityElement = true
        updateDirectionText("Press to start navigation or pause tracking", distance: 0, size: 14, displayDistance: false)
        do {
            try audioSession.setActive(false)
        } catch {
            print("some error")
        }
        delayTransition()
    }
    
    /*
     * display PAUSE TRACKING button/hide all other views
     */
    func showPauseTrackingButton() throws {
        startNavigationView.isHidden = true
        directionText.isHidden = true
        pauseTrackingView.isHidden = false
        currentButton = .resumeTracking
        do {
            try audioSession.setActive(true)
        } catch {
            print("some error")
        }
        delayTransition()
    }
    
    /*
     * display RESUME TRACKING button/hide all other views
     */
    @objc func showResumeTrackingButton() {
        pauseTrackingView.isHidden = true
        resumeTrackingView.isHidden = false
        currentButton = .resumeTracking
        do {
            try audioSession.setActive(false)
        } catch {
            print("some error")
        }
        delayTransition()
    }
    
    func showResumeTrackingConfirmButton() {
        resumeTrackingView.isHidden = true
        resumeTrackingConfirmView.isHidden = false
        do {
            try audioSession.setActive(true)
        } catch {
            print("some error")
        }
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
        directionText.isAccessibilityElement = false
        currentButton = .stopNavigation
        delayTransition()
    }
    
    /*
     * display ROUTE RATING button/hide all other views
     */
    @objc func showRouteRating(announceArrival: Bool) {
        stopNavigationView.isHidden = true
        getDirectionButton.isHidden = true
        settingsButton.isHidden = true
        helpButton.isHidden = true

        directionText.isHidden = true
        routeRatingView.isHidden = false
        if announceArrival {
            routeRatingLabel?.text = "You've arrived. Please rate your service."
        } else {
            routeRatingLabel?.text = "Please rate your service."
        }
        currentButton = .stopNavigation
        
        hapticTimer?.invalidate()
        
        feedbackGenerator = nil
        waypointFeedbackGenerator = nil
        delayTransition()
    }
    
    /*
     * update directionText UILabel given text string and font size
     * distance Bool used to determine whether to add string "meters" to direction text
     */
    func updateDirectionText(_ description: String, distance: Float, size: CGFloat, displayDistance: Bool) {
        directionText.fadeTransition(0.4)
        directionText.font = directionText.font.withSize(size)
        let distanceToDisplay = roundToTenths(distance * unitConversionFactor[defaultUnit]!)
        var altText = ""
        if (displayDistance) {
            directionText.text = description + " for \(distanceToDisplay)" + unit[defaultUnit]!
            if(defaultUnit == 0) {
                altText = description + " for \(Int(distanceToDisplay))" + unitText[defaultUnit]!
            } else {
                if(distanceToDisplay >= 10) {
                    let integer = Int(distanceToDisplay)
                    let decimal = Int((distanceToDisplay - Float(integer)) * 10)
                    altText = description + "\(integer) point \(decimal)" + unitText[defaultUnit]!
                } else {
                    altText = description + "\(distanceToDisplay)" + unitText[defaultUnit]!
                }
            }
        } else {
            directionText.text = description
            altText = description
        }
        if case .navigatingRoute = state {
            speechData.append(altText)
            speechDataTime.append(roundToThousandths(-dataTimer.timeIntervalSinceNow))
        }
        
        // TODO: next line was just if (voiceFeedback)
        if case .navigatingRoute = state {
            if voiceFeedback {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, altText)
            }
        }
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
    var dataTimer = Date()                        // timer to sync data
    var pathData: [[Float]] = []                // path data taken during RECORDPATH - [[1x16 transform matrix]]
    var pathDataTime: [Double] = []               // time stamps for pathData
    var navigationData: [[Float]] = []          // path data taken during NAVIGATION - [[1x16 transform matrix]]
    var navigationDataTime: [Double] = []         // time stamps for navigationData
    var speechData: [String] = []                   // description data during NAVIGATION
    var speechDataTime: [Double] = []               // time stamp for speechData
    var keypointData: [Array<Any>]!             // list of keypoints - [[(LocationInfo)x, y, z, yaw]]
    var trackingErrorData: [String] = []            // list of tracking errors ["InsufficientFeatures", "ExcessiveMotion"]
    var trackingErrorTime: [Double] = []            // time stamp of tracking error
    var trackingErrorPhase: [Bool] = []             // tracking phase - true: recording, false: navigation
    
    // Timers for background functions
    var droppingCrumbs: Timer?
    var followingCrumbs: Timer?
    var hapticTimer: Timer?
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
    
    // DirectionText based on hapic/voice settings
    var Directions: Dictionary<Int, String> {
        if (hapticFeedback) {
            return HapticDirections
        } else {
            return ClockDirections
        }
    }
    
    @objc func recordPath() {
        state = .recordingRoute
    }
    
    @objc func stopRecording(_ sender: UIButton) {
        state = .readyToNavigateOrPause
    }
    
    @objc func startNavigation(_ sender: UIButton) {
        state = .navigatingRoute
    }
    
    @objc func stopNavigation(_ sender: UIButton) {
        // stop navigation
        followingCrumbs?.invalidate()
        hapticTimer?.invalidate()
        
        feedbackGenerator = nil
        waypointFeedbackGenerator = nil
        
        // erase neariest keypoint
        keypointNode.removeFromParentNode()
        
        if(sendLogs) {
            state = .ratingRoute(announceArrival: false)
        } else {
            state = .mainScreen(announceArrival: false)
        }
    }
    
    @objc func startPauseProcedure() {
        state = .startingPauseProcedure
    }
    
    @objc func pauseTracking() {
        // pause AR pose tracking
        state = .completingPauseProcedure
    }
    
    @objc func resumeTracking() {
        // resume pose tracking with existing ARSessionConfiguration
        if #available(iOS 12.0, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(resumeWaitingPeriod)) {
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
                    self.state = .readyToNavigateOrPause
                }
            }
        } else {
            sceneView.session.run(configuration)
        }
    }
    
    @objc func confirmResumeTracking() {
        state = .startingResumeProcedure
    }
    
    // MARK: - Logging
    @objc func sendLogData() {
        // send success log data to AWS
        compileLogData(false)
        state = .mainScreen(announceArrival: false)
    }
    
    @objc func sendDebugLogData() {
        // send debug log data to AWS
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
    }
    
    func sendMetaData(_ pathDate: String, _ pathID: String, _ userId: String, _ debug: Bool) {
        let pathType: String!
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
                                    "trackingErrorData": trackingErrorData]
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
        // XXX TODO: need to check this to see if it improves relocalization
        //sceneView.session.add(anchor: curLocation)
        crumbs.append(curLocation)
    }
    
    @objc func followCrumb() {
        // checks to see if user is on the right path during navigation
        guard let curLocation = getRealCoordinates(record: true) else {
            // TODO: might want to indicate that something is wrong to the user
            return
        }
        var directionToNextKeypoint = getDirectionToNextKeypoint(currentLocation: curLocation)
        
        if (shouldAnnounceTurnWarning(directionToNextKeypoint)) {
            announceTurnWarning(curLocation)
        } else if (directionToNextKeypoint.targetState == PositionState.atTarget) {
            if (keypoints.count > 1) {
                // arrived at keypoint
                // send haptic/sonic feedback
                waypointFeedbackGenerator?.notificationOccurred(.success)
                if (soundFeedback) { AudioServicesPlaySystemSound(SystemSoundID(1016)) }
                
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
                if (soundFeedback) { AudioServicesPlaySystemSound(SystemSoundID(1016)) }
                
                // erase current keypoint node
                keypointNode.removeFromParentNode()
                
                followingCrumbs?.invalidate()
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
    
    // MARK: - print camera transform
    @objc func printCameraTransform() {
        printTransformHelper(transform: sceneView.session.currentFrame?.camera.transform)
    }
    func printTransformHelper(transform: simd_float4x4?) {
        if let transform = transform {
            /*print(transform.columns.0.x, ", ", transform.columns.1.x, ", ", transform.columns.2.x, ", ", transform.columns.3.x)
            print(transform.columns.0.y, ", ", transform.columns.1.y, ", ", transform.columns.2.y, ", ", transform.columns.3.y)
            print(transform.columns.0.z, ", ", transform.columns.1.z, ", ", transform.columns.2.z, ", ", transform.columns.3.z)
            print(transform.columns.0.w, ", ", transform.columns.1.w, ", ", transform.columns.2.w, ", ", transform.columns.3.w)*/
            print("yaw", getYawHelper(transform))
        }
    }
    func getYawHelper(_ transform: simd_float4x4) -> Float {
        if abs(transform.columns.2.y) < abs(transform.columns.0.y) {
            return atan2f(transform.columns.2.x, transform.columns.2.z)
        } else {
            return atan2f(transform.columns.0.x, transform.columns.0.z)
        }
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
        if(fabs(directionToNextKeypoint.angleDiff) < coneWidth) {
            let timeInterval = feedbackTimer.timeIntervalSinceNow
            if(-timeInterval > FEEDBACKDELAY) {
                // wait until desired time interval before sending another feedback
                if (hapticFeedback) { feedbackGenerator?.impactOccurred() }
                if (soundFeedback) { AudioServicesPlaySystemSound(SystemSoundID(1103)) }
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
            updateDirectionText(dir, distance: 0, size: 12, displayDistance: false)
        } else if (slope < -0.3) { // Go downstairs
            if(hapticFeedback) {
                dir += "\(TurnWarnings[direction.hapticDirection]!) and proceed downstairs"
            } else {
                dir += "\(TurnWarnings[direction.clockDirection]!) and proceed downstairs"
            }
            updateDirectionText(dir, distance: direction.distance,size: 12, displayDistance: false)
        } else { // nromal directions
            if(hapticFeedback) {
                dir += "\(TurnWarnings[direction.hapticDirection]!)"
            } else {
                dir += "\(TurnWarnings[direction.clockDirection]!)"
            }
            updateDirectionText(dir, distance: direction.distance, size: 16, displayDistance:  false)
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
            updateDirectionText(dir, distance: 0, size: 12, displayDistance: false)
        } else if (slope < -0.3) { // Go downstairs
            if(hapticFeedback) {
                dir += "\(Directions[direction.hapticDirection]!) and proceed downstairs"
            } else {
                dir += "\(Directions[direction.clockDirection]!) and proceed downstairs"
            }
            updateDirectionText(dir, distance: direction.distance,size: 12, displayDistance: false)
        } else { // nromal directions
            if(hapticFeedback) {
                dir += "\(Directions[direction.hapticDirection]!)"
            } else {
                dir += "\(Directions[direction.clockDirection]!)"
            }
            updateDirectionText(dir, distance: direction.distance, size: 16, displayDistance:  displayDistance)
        }
    }
    
    func renderKeypoint(_ location: LocationInfo) {
        // render SCNNode of given keypoint
        let bundle = Bundle.main
        let path = bundle.path(forResource: "Crumb", ofType: "obj")
        let url = NSURL(fileURLWithPath: path!)
        let asset = MDLAsset(url: url as URL)
        let object = asset.object(at: 0)
        keypointNode = SCNNode(mdlObject: object)
        
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
            if case .navigatingRoute = state {
                navigationData.append([round10k(scn.m11), round10k(scn.m12), round10k(scn.m13), round10k(scn.m14),
                                       round10k(scn.m21), round10k(scn.m22), round10k(scn.m23), round10k(scn.m24),
                                       round10k(scn.m31), round10k(scn.m32), round10k(scn.m33), round10k(scn.m34),
                                       round10k(scn.m41), round10k(scn.m42), round10k(scn.m43), round10k(scn.m44)])
                navigationDataTime.append(roundToThousandths(-dataTimer.timeIntervalSinceNow))
            } else {
                pathData.append([round10k(scn.m11), round10k(scn.m12), round10k(scn.m13), round10k(scn.m14),
                                 round10k(scn.m21), round10k(scn.m22), round10k(scn.m23), round10k(scn.m24),
                                 round10k(scn.m31), round10k(scn.m32), round10k(scn.m33), round10k(scn.m34),
                                 round10k(scn.m41), round10k(scn.m42), round10k(scn.m43), round10k(scn.m44)])
                pathDataTime.append(roundToThousandths(-dataTimer.timeIntervalSinceNow))
            }
        }
        return CurrentCoordinateInfo(LocationInfo(transform: currTransform), transMatrix: transMatrix)
    }
    
    /*
     * Called when there is a change in tracking state
     */
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var logString: String

        switch camera.trackingState {
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                logString = "ExcessiveMotion"
                print("Excessive motion")
            case .insufficientFeatures:
                logString = "InsufficientFeatures"
                print("InsufficientFeatures")
            case .initializing:
                // don't log anything
                print("initializing")
                return
            case .relocalizing:
                logString = "Relocalizing"
                print("Relocalizing")
                if case .startingResumeProcedure = state {
                    state = .readyForFinalResumeAlignment
                }
            }
        case .normal:
            logString = "Normal"
            if #available(iOS 11.3, *) {
                // resetting the origin is a needed in the case when we realigned to a saved route
                print("RESETTING WORLD ORIGIN!!!")
                session.setWorldOrigin(relativeTransform: simd_float4x4.makeTranslation(0,0,0))
                if case .readyForFinalResumeAlignment = state {
                    // this will cancel any realignment if it hasn't happened yet
                    state = .mainScreen(announceArrival: false)
                }
            }
            print("normal")
        case .notAvailable:
            logString = "NotAvailable"
            print("notAvailable")
        }
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
    
    static func makeScale(_ x: Float, _ y: Float, _ z: Float) -> float4x4 {
        return unsafeBitCast(GLKMatrix4MakeScale(x, y, z), to: float4x4.self)
    }
    
    static func makeRotate(radians: Float, _ x: Float, _ y: Float, _ z: Float) -> float4x4 {
        return unsafeBitCast(GLKMatrix4MakeRotation(radians, x, y, z), to: float4x4.self)
    }
    
    static func makeTranslation(_ x: Float, _ y: Float, _ z: Float) -> float4x4 {
        return unsafeBitCast(GLKMatrix4MakeTranslation(x, y, z), to: float4x4.self)
    }
    
    static func makePerspective(fovyRadians: Float, _ aspect: Float, _ nearZ: Float, _ farZ: Float) -> float4x4 {
        return unsafeBitCast(GLKMatrix4MakePerspective(fovyRadians, aspect, nearZ, farZ), to: float4x4.self)
    }
    
    static func makeFrustum(left: Float, _ right: Float, _ bottom: Float, _ top: Float, _ nearZ: Float, _ farZ: Float) -> float4x4 {
        return unsafeBitCast(GLKMatrix4MakeFrustum(left, right, bottom, top, nearZ, farZ), to: float4x4.self)
    }
    
    static func makeOrtho(left: Float, _ right: Float, _ bottom: Float, _ top: Float, _ nearZ: Float, _ farZ: Float) -> float4x4 {
        return unsafeBitCast(GLKMatrix4MakeOrtho(left, right, bottom, top, nearZ, farZ), to: float4x4.self)
    }
    
    static func makeLookAt(eyeX: Float, _ eyeY: Float, _ eyeZ: Float, _ centerX: Float, _ centerY: Float, _ centerZ: Float, _ upX: Float, _ upY: Float, _ upZ: Float) -> float4x4 {
        return unsafeBitCast(GLKMatrix4MakeLookAt(eyeX, eyeY, eyeZ, centerX, centerY, centerZ, upX, upY, upZ), to: float4x4.self)
    }
    
    
    func scale(x: Float, y: Float, z: Float) -> float4x4 {
        return self * float4x4.makeScale(x, y, z)
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
