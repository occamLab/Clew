//
//  ARSessionManager.swift
//  Clew
//
//  Created by Paul Ruvolo on 10/14/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import Foundation
import ARKit

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
}

class ARSessionManager: NSObject {
    static var shared = ARSessionManager()
    var delegate: ARSessionManagerDelegate?
    
    private override init() {
        super.init()
        sceneView.session.delegate = self
        sceneView.delegate = self
        sceneView.accessibilityIgnoresInvertColors = true
        createARSessionConfiguration()
        loadAssets()
        sceneView.backgroundColor = .systemBackground
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
    
    /// Create a new ARSession.
    func createARSessionConfiguration() {
        configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isAutoFocusEnabled = false
    }
    
    func startSession() {
        manualAlignment = nil
        removeNavigationNodes()
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    /// This seems to interfere with placement of ARAnchors in the scene when reloading maps
    func pauseSession() {
        sceneView.session.pause()
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
        keypointNode?.removeFromParentNode()
        keypointNode = SCNNode(mdlObject: keypointObject)
        keypointNode!.scale = SCNVector3(0.0004, 0.0004, 0.0004)
        // configure node attributes
        keypointNode!.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        
        // determine if the node is already in the scene
        let priorNode = sceneView.node(for: location)
        if priorNode != nil {
            keypointNode!.position = SCNVector3(0, -0.2, 0.0)
        } else {
            if let manualAlignment = manualAlignment {
                let alignedLocation = manualAlignment*location.transform
                keypointNode!.position = SCNVector3(alignedLocation.x, alignedLocation.y - 0.2, alignedLocation.z)
            } else {
                keypointNode!.position = SCNVector3(location.x, location.y - 0.2, location.z)
            }
            keypointNode!.rotation = SCNVector4(0, 1, 0, (location.yaw - Float.pi/2))
        }
        
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
        keypointNode!.runAction(changeColor)
        if let priorNode = priorNode {
            // TODO: we are having a really hard time here
            // If we recreate the node every time it moves, then it will track
            keypointNode!.position = priorNode.position
            //priorNode.addChildNode(keypointNode!)
        }// else {
        sceneView.scene.rootNode.addChildNode(keypointNode!)
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
        if let anchorPointNode = anchorPointNodes[intermediateAnchorPoint] {
            anchorPointNode.removeFromParentNode()
            anchorPointNodes[intermediateAnchorPoint] = nil
        }
        
        guard let intermediateARAnchor = intermediateAnchorPoint.anchor else {
            return
        }
        let anchorPointNode = SCNNode(mdlObject: speakerObject)
        
        let priorNode = sceneView.node(for: intermediateARAnchor)
        if priorNode != nil {
            anchorPointNode.position = SCNVector3(0, -0.2, 0.0)
        } else {
            if let manualAlignment = manualAlignment {
                let alignedLocation = manualAlignment*intermediateARAnchor.transform
                anchorPointNode.position = SCNVector3(alignedLocation.x, alignedLocation.y - 0.2, alignedLocation.z)
            } else {
                anchorPointNode.position = SCNVector3(intermediateARAnchor.transform.x, intermediateARAnchor.transform.y - 0.2, intermediateARAnchor.transform.z)
            }
        }
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
        anchorPointNodes[intermediateAnchorPoint] = anchorPointNode
        if let priorNode = priorNode {
            anchorPointNode.position = priorNode.position
        }
        sceneView.scene.rootNode.addChildNode(anchorPointNode)
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
        pathObj?.removeFromParentNode()
        guard let locationFront = getCurrentLocation(of: locationFront), let locationBack = getCurrentLocation(of: locationBack) else {
            return
        }
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
    
    func set(transform: simd_float4x4) {
        self.transform = transform
        objectWillChange.send()
    }
}

extension ARSessionManager: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        ARData.shared.set(transform: frame.camera.transform)
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
