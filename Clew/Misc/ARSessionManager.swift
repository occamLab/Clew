//
//  ARSessionManager.swift
//  Clew
//
//  Created by Paul Ruvolo on 10/14/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import Foundation
import ARKit
import ARCore

enum ARTrackingError {
    case insufficientFeatures
    case excessiveMotion
}

/// This tells the app how to deal with the ARWorldMap in light of the major changes introduced iOS 15 with regards to handling the ARWorldMap
enum RelocalizationStrategy {
    /// The map is unusable
    case none
    /// The current session's coordinate system will be mapped to the ARWorldMap's coordinate system (we don't have to do very much)
    case coordinateSystemAutoAligns
    /// We can use the origin as a guide for updating all of the anchors
    case useOriginAnchorForAlignment
    /// Each individual crumb will have its own anchor
    case useCrumbAnchorsForAlignment
}

protocol ARSessionManagerDelegate {
    func trackingErrorOccurred(_ : ARTrackingError)
    func sessionInitialized()
    func sessionRelocalizing()
    func trackingIsNormal()
    func isRecording()->Bool
    func getPathColor()->Int
    func getKeypointColor()->Int
    func getShowPath()->Bool
    func newFrameAvailable()
    func sessionDidRelocalize()
    func didHostCloudAnchor(cloudIdentifier: String, withTransform transform : simd_float4x4)
}

class ARSessionManager: NSObject {
    static var shared = ARSessionManager()
    var delegate: ARSessionManagerDelegate?
    var lastTorchChange = 0.0
    enum LocalizationState {
        case none
        case withCloudAnchors
        case withARWorldMap
    }
    var localization: LocalizationState = .none

    // TODO: we can probably get rid of these and use the cloudIdentifier as our key
    private var sessionCloudAnchors: [UUID: ARAnchor] = [:]
    
    var lastResolvedCloudAnchorID: String?
    
    var cloudAnchorsForAlignment: [NSString: ARAnchor] = [:] {
        didSet {
            sessionCloudAnchors = [:]
            if cloudAnchorsForAlignment.count > 20 {
                let tooManyAnchors = "Too many cloud anchors. Results may be unpredictable."
                AnnouncementManager.shared.announce(announcement: tooManyAnchors)
                PathLogger.shared.logSpeech(utterance: tooManyAnchors)
            }
            for cloudAnchor in cloudAnchorsForAlignment {
                do {
                    if let gAnchor = try garSession?.resolveCloudAnchor(String(cloudAnchor.0)) {
                        sessionCloudAnchors[gAnchor.identifier] = cloudAnchor.1
                        print("trying to resolve \(cloudAnchor.0)")
                    }
                } catch {
                    print("synchronous failure to resolve")
                }
            }
        }
    }
    
    private override init() {
        super.init()
        sceneView.session.delegate = self
        sceneView.delegate = self
        sceneView.accessibilityIgnoresInvertColors = true
        createARSessionConfiguration()
        loadAssets()
        sceneView.backgroundColor = .systemBackground
    }
    
    // animation - SCNNode flashes red
    private let flashRed = SCNAction.customAction(duration: 2) { (node, elapsedTime) -> () in
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
    private let flashGreen = SCNAction.customAction(duration: 2) { (node, elapsedTime) -> () in
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
    private let flashBlue = SCNAction.customAction(duration: 2) { (node, elapsedTime) -> () in
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
    
    /// This is embeds an AR scene.  The ARSession is a part of the scene view, which allows us to capture where the phone is in space and the state of the world tracking.  The scene also allows us to insert virtual objects
    var sceneView: ARSCNView = ARSCNView()
    
    /// this is the alignment between the reloaded route
    var manualAlignment: simd_float4x4?
    
    /// the strategy to employ with respect to the worldmap
    var relocalizationStrategy: RelocalizationStrategy = .none
    
    var initialWorldMap: ARWorldMap? {
        set {
            configuration.initialWorldMap = newValue
        }
        get {
            return configuration.initialWorldMap
        }
    }
    
    /// AR Session Configuration
    private var configuration: ARWorldTrackingConfiguration!
    
    /// Use these variables to keep track of rendering work that has to be done.  This allows us to do all of the rendering from one thread
    private var keypointRenderJob: (()->())?
    private var pathRenderJob: (()->())?
    private var intermediateAnchorRenderJobs: [RouteAnchorPoint : (()->())?] = [:]
    
    /// SCNNode of the next keypoint
    private var keypointNode: SCNNode?
    
    /// SCNNode of the bar path
    private var pathObj: SCNNode?
    
    /// SCNNode of the intermediate anchor points
    private var anchorPointNodes: [RouteAnchorPoint: SCNNode] = [:]
    /// Keypoint object
    var keypointObject : MDLObject!
    
    /// Speaker object
    var speakerObject: MDLObject!
    
    var currentFrame: ARFrame? {
        return sceneView.session.currentFrame
    }
    
    var currentGARFrame: GARFrame?
    
    var garSession: GARSession?

    /// Create a new ARSession.
    func createARSessionConfiguration() {
        configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isAutoFocusEnabled = false
    }
    
    func adjustTorch(lightingIntensity: Float, timestamp: Double) {
        guard
            let device = AVCaptureDevice.default(for: AVMediaType.video),
            device.hasTorch
        else { return }
        if device.torchMode == .off && lightingIntensity < 500 {
            do {
                try device.lockForConfiguration()
                try device.setTorchModeOn(level: 1.0)
                lastTorchChange = timestamp
            } catch {
                print("torch error")
            }
        } else if device.torchMode == .on && lightingIntensity > 1200 && timestamp - lastTorchChange > 60.0 {
            do {
                try device.lockForConfiguration()
                device.torchMode = .off
                lastTorchChange = timestamp
            } catch {
                print("torch error")
            }
        }
    }
    
    func startSession() {
        lastTorchChange = 0.0
        manualAlignment = nil
        localization = .none
        removeNavigationNodes()
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
        startGARSession()
    }
    
    /// This seems to interfere with placement of ARAnchors in the scene when reloading maps
    func pauseSession() {
        sceneView.session.pause()
    }
    
    func hostCloudAnchor(withTransform transform: simd_float4x4)->(GARAnchor, ARAnchor)? {
        let newAnchor = ARAnchor(transform: transform)
        add(anchor: newAnchor)
        do {
            if let newGARAnchor = try garSession?.hostCloudAnchor(newAnchor) {
                return (newGARAnchor, newAnchor)
            }
        } catch {
            print("host cloud anchor failed \(error.localizedDescription)")
        }
        return nil
    }
    
    private func startGARSession() {
        do {
            garSession = try GARSession(apiKey: garAPIKey, bundleIdentifier: nil)
            var error: NSError?
            let configuration = GARSessionConfiguration()
            configuration.cloudAnchorMode = .enabled
            garSession?.setConfiguration(configuration, error: &error)
            garSession?.delegate = self
            print("gar set configuration error \(error)")
        } catch {
            print("failed to create GARSession")
        }
    }
    
    func adjustRelocalizationStrategy(worldMap: ARWorldMap)->RelocalizationStrategy {
        if #available(iOS 15.0, *) {
            if worldMap.anchors.firstIndex(where: {anchor in anchor is LocationInfo}) != nil {
                relocalizationStrategy = .useCrumbAnchorsForAlignment
            } else if worldMap.anchors.firstIndex(where: {anchor in anchor.name == "origin"}) != nil {
                relocalizationStrategy = .useOriginAnchorForAlignment
            } else {
                relocalizationStrategy = .none
            }
        } else {
            relocalizationStrategy = .coordinateSystemAutoAligns
        }
        return relocalizationStrategy
    }
    
    /// Create the keypoint SCNNode that corresponds to the rotating flashing element that looks like a navigation pin.
    ///
    /// - Parameter location: the location of the keypoint
    func renderKeypoint(_ location: LocationInfo, defaultColor: Int) {
        keypointRenderJob = {
            self.renderKeypointHelper(location, defaultColor: defaultColor)
        }
    }
    
    func renderKeypointHelper(_ location: LocationInfo, defaultColor: Int) {
        if keypointNode == nil {
            keypointNode = SCNNode(mdlObject: keypointObject)
            keypointNode!.scale = SCNVector3(0.0004, 0.0004, 0.0004)
            // configure node attributes
            keypointNode!.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                
            let bound = SCNVector3(
                x: keypointNode!.boundingBox.max.x - keypointNode!.boundingBox.min.x,
                y: keypointNode!.boundingBox.max.y - keypointNode!.boundingBox.min.y,
                z: keypointNode!.boundingBox.max.z - keypointNode!.boundingBox.min.z)
            keypointNode!.pivot = SCNMatrix4MakeTranslation(bound.x / 2, bound.y / 2, bound.z / 2)
            
            let spin = CABasicAnimation(keyPath: "rotation")
            spin.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: 0))
            spin.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float(CGFloat(2 * Float.pi))))
            spin.duration = 3
            spin.repeatCount = .infinity
            keypointNode!.addAnimation(spin, forKey: "spin around")
            let flashColors = [flashRed, flashGreen, flashBlue]
            
            // set flashing color based on settings bundle configuration
            var changeColor: SCNAction!
            if (defaultColor == 3) {
                changeColor = SCNAction.repeatForever(flashColors[Int(arc4random_uniform(3))])
            } else {
                changeColor = SCNAction.repeatForever(flashColors[defaultColor])
            }
            
            // add keypoint node to view
            keypointNode!.runAction(changeColor)
            sceneView.scene.rootNode.addChildNode(keypointNode!)
        }
        
        // determine if the node is already in the scene
        if let priorNode = sceneView.node(for: location) {
            keypointNode!.position = priorNode.position
        } else {
            if let manualAlignment = manualAlignment {
                let alignedLocation = manualAlignment*location.transform
                keypointNode!.position = SCNVector3(alignedLocation.x, alignedLocation.y - 0.2, alignedLocation.z)
            } else {
                keypointNode!.position = SCNVector3(location.x, location.y - 0.2, location.z)
            }
            keypointNode!.rotation = SCNVector4(0, 1, 0, (location.yaw - Float.pi/2))
        }
    }
    
    func add(anchor: ARAnchor) {
        sceneView.session.add(anchor: anchor)
    }
    
    /// This function renders a spinning blue speaker icon at the location of a voice note
    func render(intermediateAnchorPoints: [RouteAnchorPoint]) {
        for intermediateAnchorPoint in intermediateAnchorPoints {
            intermediateAnchorRenderJobs[intermediateAnchorPoint] = {
                self.renderHelper(intermediateAnchorPoint: intermediateAnchorPoint)
            }
        }
    }
    
    /// This function renders a spinning blue speaker icon at the location of a voice note
    func renderHelper(intermediateAnchorPoint: RouteAnchorPoint) {
        guard let intermediateARAnchor = intermediateAnchorPoint.anchor else {
            return
        }
        let anchorPointNode: SCNNode
        if let node = anchorPointNodes[intermediateAnchorPoint] {
            anchorPointNode = node
        } else {
            anchorPointNode = SCNNode(mdlObject: speakerObject)
            // render SCNNode of given keypoint
            // configure node attributes
            anchorPointNode.scale = SCNVector3(0.02, 0.02, 0.02)
            anchorPointNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
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
            
            // set flashing color based on settings bundle configuration
            let changeColor = SCNAction.repeatForever(flashBlue)
            // add keypoint node to view
            anchorPointNode.runAction(changeColor)
            anchorPointNodes[intermediateAnchorPoint] = anchorPointNode
            sceneView.scene.rootNode.addChildNode(anchorPointNode)
        }
        
        if let priorNode = sceneView.node(for: intermediateARAnchor) {
            anchorPointNode.position = priorNode.position
        } else {
            if let manualAlignment = manualAlignment {
                let alignedLocation = manualAlignment*intermediateARAnchor.transform
                anchorPointNode.position = SCNVector3(alignedLocation.x, alignedLocation.y - 0.2, alignedLocation.z)
            } else {
                anchorPointNode.position = SCNVector3(intermediateARAnchor.transform.x, intermediateARAnchor.transform.y - 0.2, intermediateARAnchor.transform.z)
            }
        }
    }
    
    func getCurrentLocation(of anchor: ARAnchor)->LocationInfo? {
        if let node = sceneView.node(for: anchor), let anchor = sceneView.anchor(for: node) {
            return LocationInfo(anchor: anchor)
        } else if let manualAlignment = manualAlignment {
            return LocationInfo(anchor: ARAnchor(transform: manualAlignment*anchor.transform))
        } else {
            return nil
        }
    }
    
    func removeNavigationNodes() {
        keypointNode?.removeFromParentNode()
        keypointNode = nil
        pathObj?.removeFromParentNode()
        pathObj = nil
        for anchorPointNode in anchorPointNodes {
            anchorPointNode.1.removeFromParentNode()
        }
        anchorPointNodes = [:]
    }
    
    /// Create the path SCNNode that corresponds to the long translucent bar element that looks like a route path.
    /// - Parameters:
    ///  - locationFront: the location of the keypoint user is approaching
    ///  - locationBack: the location of the keypoint user is currently at
    func renderPath(_ locationFront: LocationInfo, _ locationBack: LocationInfo, defaultPathColor: Int) {
        pathRenderJob = {
            self.renderPathHelper(locationFront, locationBack, defaultPathColor: defaultPathColor)
        }
    }

    func renderPathHelper(_ locationFront: LocationInfo, _ locationBack: LocationInfo, defaultPathColor: Int) {
        guard let locationFront = getCurrentLocation(of: locationFront), let locationBack = getCurrentLocation(of: locationBack) else {
            return
        }
        
        if pathObj == nil {
            pathObj = SCNNode(geometry: SCNBox(width: 1.0, height: 0.25, length: 0.08, chamferRadius: 3))
            let colors = [UIColor.red, UIColor.green, UIColor.blue]
            let color: UIColor
            // set color based on settings bundle configuration
            if (defaultPathColor == 3) {
                color = colors[Int(arc4random_uniform(3))]
            } else {
                color = colors[defaultPathColor]
            }
            pathObj?.geometry?.firstMaterial!.diffuse.contents = color
            // configure node attributes
            pathObj?.opacity = CGFloat(0.7)
            sceneView.scene.rootNode.addChildNode(pathObj!)
        }
        let x = (locationFront.x + locationBack.x) / 2
        let y = (locationFront.y + locationBack.y) / 2
        let z = (locationFront.z + locationBack.z) / 2
        let xDist = locationFront.x - locationBack.x
        let yDist = locationFront.y - locationBack.y
        let zDist = locationFront.z - locationBack.z
        let pathDist = sqrt(pow(xDist, 2) + pow(yDist, 2) + pow(zDist, 2))
        
        
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
        pathObj!.simdTransform = pathTransform
        pathObj!.scale.x = pathDist
    }
    
    /// Load the crumb 3D model
    private func loadAssets() {
        let url = NSURL(fileURLWithPath: Bundle.main.path(forResource: "Crumb", ofType: "obj")!)
        let asset = MDLAsset(url: url as URL)
        keypointObject = asset.object(at: 0)
        let speakerUrl = NSURL(fileURLWithPath: Bundle.main.path(forResource: "speaker", ofType: "obj")!)
        let speakerAsset = MDLAsset(url: speakerUrl as URL)
        speakerObject = speakerAsset.object(at: 0)
    }
}

class ARData: ObservableObject {
    public static var shared = ARData()
    
    private(set) var transform: simd_float4x4?
    private(set) var intrinsics: simd_float3x3?
    private(set) var image: CVPixelBuffer?
    
    func set(transform: simd_float4x4, intrinsics: simd_float3x3, image: CVPixelBuffer) {
        self.transform = transform
        self.intrinsics = intrinsics
        self.image = image
        objectWillChange.send()
    }
}

extension ARSessionManager: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        ARData.shared.set(transform: frame.camera.transform, intrinsics: frame.camera.intrinsics, image: frame.capturedImage)
        if let lighting = frame.lightEstimate {
            adjustTorch(lightingIntensity: Float(lighting.ambientIntensity), timestamp: frame.timestamp)
        }
        
        do {
            //ARFrameStatusAdapter.adjustTrackingStatus(frame)
            let garFrame = try garSession?.update(frame)
            self.currentGARFrame = garFrame
            // don't use Cloud Anchors if we have localized with the ARWorldMap
            if localization != .withARWorldMap, let gAnchors = currentGARFrame?.anchors {
                checkForCloudAnchorAlignment(anchors: gAnchors)
            }
        } catch {
            print("couldn't update GAR Frame")
        }
        if let keypointRenderJob = keypointRenderJob {
            keypointRenderJob()
            self.keypointRenderJob = nil
        }
        if let pathRenderJob = pathRenderJob {
            pathRenderJob()
            self.pathRenderJob = nil
        }
        for intermediateAnchorRenderJob in intermediateAnchorRenderJobs {
            if let renderJob = intermediateAnchorRenderJob.1 {
                renderJob()
                intermediateAnchorRenderJobs[intermediateAnchorRenderJob.0] = nil
            }
        }
        delegate?.newFrameAvailable()
    }
    
    /// Update alignment based on cloud anchors that have been detected
    /// - Parameter anchors: the current GARAnchors
    private func checkForCloudAnchorAlignment(anchors: [GARAnchor]) {
        for anchor in anchors {
            if anchor.hasValidTransform, let correspondingARAnchor = sessionCloudAnchors[anchor.identifier], anchor.cloudIdentifier == lastResolvedCloudAnchorID  {
                manualAlignment = anchor.transform.alignY() * correspondingARAnchor.transform.inverse.alignY()
            }
        }
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
                delegate?.trackingErrorOccurred(.excessiveMotion)
            case .insufficientFeatures:
                logString = "InsufficientFeatures"
                delegate?.trackingErrorOccurred(.insufficientFeatures)
            case .initializing:
                // don't log anything
                print("initializing")
            case .relocalizing:
                delegate?.sessionInitialized()
                delegate?.sessionRelocalizing()
            @unknown default:
                print("An error condition arose that we didn't know about when the app was last compiled")
            }
        case .normal:
            logString = "Normal"
            delegate?.sessionInitialized()
            delegate?.trackingIsNormal()
            if relocalizationStrategy == .coordinateSystemAutoAligns {
                manualAlignment = matrix_identity_float4x4
                legacyHandleRelocalization()
            }
            print("normal")
        case .notAvailable:
            logString = "NotAvailable"
            print("notAvailable")
        }
        if let logString = logString, let recordingPhase = delegate?.isRecording() {
            PathLogger.shared.logTrackingError(isRecordingPhase: recordingPhase, trackingError: logString)
        }
    }
    
    func legacyHandleRelocalization() {
        removeNavigationNodes()
        guard let defaultColor = delegate?.getKeypointColor(), let defaultPathColor = delegate?.getPathColor(), let showPath = delegate?.getShowPath() else {
            return
        }
        if let nextKeypoint = RouteManager.shared.nextKeypoint, let cameraTransform = currentFrame?.camera.transform {
            let previousKeypointLocation = RouteManager.shared.getPreviousKeypoint(to: nextKeypoint)?.location ?? LocationInfo(transform: cameraTransform)
            renderKeypoint(nextKeypoint.location, defaultColor: defaultColor)
            if showPath {
                renderPath(nextKeypoint.location, previousKeypointLocation, defaultPathColor: defaultPathColor)
            }
        }
        for intermediateAnchorPoint in RouteManager.shared.intermediateAnchorPoints {
            render(intermediateAnchorPoints: [intermediateAnchorPoint])
        }
    }
}


extension ARSessionManager: ARSCNViewDelegate {
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        handleAnchorUpdate(anchor: anchor)
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
       handleAnchorUpdate(anchor: anchor)
    }
    
    func handleAnchorUpdate(anchor: ARAnchor) {
        if anchor.name == "origin", relocalizationStrategy == .useOriginAnchorForAlignment {
            manualAlignment = anchor.transform
            legacyHandleRelocalization()
            return
        }
        guard let defaultColor = delegate?.getKeypointColor(), let defaultPathColor = delegate?.getPathColor(), relocalizationStrategy == .useCrumbAnchorsForAlignment, let showPath = delegate?.getShowPath() else {
            return
        }
        if let nextKeypoint = RouteManager.shared.nextKeypoint, let cameraTransform = currentFrame?.camera.transform {
            let previousKeypointLocation = RouteManager.shared.getPreviousKeypoint(to: nextKeypoint)?.location ?? LocationInfo(transform: cameraTransform)
            if nextKeypoint.location.identifier == anchor.identifier {
                renderKeypoint(nextKeypoint.location, defaultColor: defaultColor)
            }
            if nextKeypoint.location.identifier == anchor.identifier || previousKeypointLocation.identifier == anchor.identifier, showPath {
                renderPath(nextKeypoint.location, previousKeypointLocation, defaultPathColor: defaultPathColor)
            }
        }
        for intermediateAnchorPoint in RouteManager.shared.intermediateAnchorPoints {
            if let arAnchor = intermediateAnchorPoint.anchor, arAnchor.identifier == anchor.identifier {
                render(intermediateAnchorPoints: [intermediateAnchorPoint])
            }
        }
    }
}

extension ARSessionManager: GARSessionDelegate {
    func session(_ session: GARSession, didResolve anchor:GARAnchor) {
        if localization == .withARWorldMap {
            // defer to the ARWorldMap
            return
        }
        if localization == .none {
            delegate?.sessionDidRelocalize()
        }
        localization = .withCloudAnchors
        if let cloudIdentifier = anchor.cloudIdentifier, anchor.hasValidTransform, let alignTransform = cloudAnchorsForAlignment[NSString(string: cloudIdentifier)]?.transform {
            lastResolvedCloudAnchorID = cloudIdentifier
            self.manualAlignment = anchor.transform.alignY() * alignTransform.inverse.alignY()
            let announceResolution = "Cloud Anchor Resolved"
            PathLogger.shared.logSpeech(utterance: announceResolution)
            AnnouncementManager.shared.announce(announcement: announceResolution)
        }
    }
    
    func session(_ session: GARSession, didHost garAnchor:GARAnchor) {
        if let cloudIdentifier = garAnchor.cloudIdentifier {
            delegate?.didHostCloudAnchor(cloudIdentifier: cloudIdentifier, withTransform: garAnchor.transform)
            // createSCNNodeFor(identifier: cloudIdentifier, at: garAnchor.transform)
        }
    }
    
    func session(_ session: GARSession, didFailToResolve didFailToResolveAnchor: GARAnchor) {
        print("FAILURE")
    }
}
