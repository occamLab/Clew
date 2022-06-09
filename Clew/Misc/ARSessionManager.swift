//
//  ARSessionManager.swift
//  Clew
//
//  Created by Paul Ruvolo on 10/14/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import Foundation
import ARKit
import Firebase
#if !APPCLIP
import ARDataLogger
#endif

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
    func receivedImageAnchors(imageAnchors: [ARImageAnchor])
    func shouldLogRichData()->Bool
    func getLoggingTag()->String
    func geoAnchorsReadyForPathCreation(geoAnchors: [ARGeoAnchor])
}

class ARSessionManager: NSObject {
    var counter = 0
    var localized = false
    var cameraPoses: [Any] = []
    var visualKeypoints: [KeypointInfo] = []
    var cameraLocationInfos: [LocationInfo] = []
    let storageBaseRef = Storage.storage().reference()
    static var shared = ARSessionManager()
    var delegate: ARSessionManagerDelegate?
    var lastTimeOutputtedGeoAnchors = Date()
    
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
    
    let snapToRouteStatus: Bool = true
    
    /// Keep track of when to log a frame
    var lastFrameLogTime = Date()
    /// Keep track of when to log a pose
    var lastPoseLogTime = Date()
    
    /// Use these variables to keep track of rendering work that has to be done.  This allows us to do all of the rendering from one thread
    private var keypointRenderJob: (()->())?
    private var pathRenderJob: (()->())?
    private var intermediateAnchorRenderJobs: [RouteAnchorPoint : (()->())?] = [:]
    
    /// the strategy to employ with respect to the worldmap
    var relocalizationStrategy: RelocalizationStrategy = .none
    
    var initialWorldMap: ARWorldMap? {
        set {
            print("SORRY!! \(newValue)")
            //configuration.initialWorldMap = newValue
        }
        get {
            return nil //configuration.initialWorldMap
        }
    }
    
    /// AR Session Configuration
    private var configuration: ARGeoTrackingConfiguration!
    
    /// SCNNode of the next keypoint
    private var keypointNode: SCNNode?
    
    /// SCNNode of the bar path
    private var pathObj: SCNNode?
    
    /// SCNNode of the spherical pathpoints
    private var pathpointObjs: [SCNNode] = []
    
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
        configuration = ARGeoTrackingConfiguration()
        //configuration.planeDetection = [.horizontal, .vertical]
        if #available(iOS 14.3, *) {
            //configuration.appClipCodeTrackingEnabled = true
        }
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        //configuration.detectionImages = referenceImages
    }
    
    func startSession() {
        print("WORLD MAP STARTING SESSION!")
        manualAlignment = nil
        keypointRenderJob = nil
        pathRenderJob = nil
        intermediateAnchorRenderJobs = [:]
        removeNavigationNodes()
        sceneView.session.run(configuration, options: [.removeExistingAnchors])
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.sceneView.session.run(self.configuration, options: [])
        }
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
    
    private func renderKeypointHelper(_ location: LocationInfo, defaultColor: Int) {
        keypointNode?.removeFromParentNode()
        keypointNode = SCNNode(mdlObject: keypointObject)
        keypointNode!.scale = SCNVector3(0.0004, 0.0004, 0.0004)
        // configure node attributes
        keypointNode!.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        print("in render keypoint")
        // determine if the node is already in the scene
        let priorNode = sceneView.node(for: location)
        if priorNode != nil && !snapToRouteStatus {
            print("position keypoint relative to anchor \(location.transform.columns.3)")
            keypointNode!.position = SCNVector3(0, -0.2, 0.0)
        } else {
            if let updatedLocation = getCurrentLocation(of: location) {
                keypointNode!.position = SCNVector3(updatedLocation.x, updatedLocation.y - 0.2, updatedLocation.z)
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
        if let priorNode = priorNode, !snapToRouteStatus {
            // TODO: we are having a really hard time here
            // If we recreate the node every time it moves, then it will track
//            keypointNode!.position = priorNode.position
            priorNode.addChildNode(keypointNode!)
        } else {
        sceneView.scene.rootNode.addChildNode(keypointNode!)
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
    
    func getCurrentLocation(of anchor: ARAnchor, debug: Bool = false)->LocationInfo? {
        if let manualAlignment = manualAlignment {
            if debug {
                print("using manual alignment")
            }
            return LocationInfo(anchor: ARAnchor(transform: manualAlignment*anchor.transform))
        } else if let node = sceneView.node(for: anchor), let anchor = sceneView.anchor(for: node) {
            if debug {
                print("found an anchor when getting current location \(anchor.transform.columns.3)")
                print("")
            }
            return LocationInfo(anchor: anchor)
        } else {
            if debug {
                print("nil")
            }
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
//        let locationFrontSnapped = getCurrentLocation(of: locationFront)
//        let locationBack = LocationInfo(transform: frame.camera.transform)
        pathRenderJob = {
            self.renderPathHelper(locationFront, locationBack, defaultPathColor: defaultPathColor)
        }
    }
    
    private func renderPathHelper(_ locationFront: LocationInfo, _ locationBack: LocationInfo, defaultPathColor: Int) {
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
    func session(_ session: ARSession, didFailWithError error: Error) {
        // When loading ARWorldMaps recorded under iOS15, they will cause an error when loaded under previous iOS vedrrsions.  If this happens, we can retry without the ARWorldMap
       /* if (error as? NSError)?.code == 200, configuration.initialWorldMap != nil {
            // try again without the world map
            configuration.initialWorldMap = nil
            relocalizationStrategy = .none
            startSession()
        }*/
        print("failure")
    }
    
    /// - Tag: GeoTrackingStatus
    func session(_ session: ARSession, didChange geoTrackingStatus: ARGeoTrackingStatus) {
        print("rawaccuracy value", geoTrackingStatus.accuracy)
        if geoTrackingStatus.accuracy == ARGeoTrackingStatus.Accuracy.high, let allGeoAnchors = session.currentFrame?.anchors.compactMap({$0 as? ARGeoAnchor}) {
            print("we have high accuracy")
            //delegate?.geoAnchorsReadyForPathCreation(geoAnchors: allGeoAnchors)
        } else if geoTrackingStatus.accuracy == ARGeoTrackingStatus.Accuracy.medium {
            print("we have medium accuracy")
        } else if geoTrackingStatus.accuracy == ARGeoTrackingStatus.Accuracy.low {
            print("we have low accuracy")
        }
    }
    
    func sendPathKeypoints(_ id: String, _ allKeypoints: [KeypointInfo], _ cameraPositions: [Any]) -> String? {
        
        var waypointCoords: [Any] = []
        
        for anchor in allKeypoints
        {
            waypointCoords.append([anchor.location.transform.columns.3[0], anchor.location.transform.columns.3[2]])
        }
        
        let dataDictionary: [String : Any] = ["ID": id, "GeoAnchors": waypointCoords, "CameraPositions": cameraPositions]
        
        do {
            let jsonData = try
            JSONSerialization.data(withJSONObject:dataDictionary, options:.prettyPrinted)
            let storageRef =
            storageBaseRef.child("GeoAnchorTest3").child(id + ".json")
            let fileType = StorageMetadata()
            fileType.contentType = "application/json"
            storageRef.putData(jsonData, metadata: fileType) { (metadata, error) in
                guard metadata != nil else {
                    // Uh-oh, an error occurred!
                    print("could not upload meta data to firebase", error!.localizedDescription)
                    return
                }
                print("Successfully uploaded log!", storageRef.fullPath)
            }
         
            // How to specify where these get uploaded (Create folder for data so it doesn't clog up central bucket)
            // How often can we upload this stuff/how big are these uploads? Don't want to overflow data limitations
            return storageRef.fullPath
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func sendPathData(_ id: String,_ allGeoAnchors: [ARGeoAnchor], _ cameraPositions: [Any])->String? {
            
        var anchorCoords: [Any] = []
        
        for anchor in allGeoAnchors
        {
            anchorCoords.append([anchor.transform.columns.3[0], anchor.transform.columns.3[2]])
        }
        
        let dataDictionary: [String : Any] = ["ID": id, "GeoAnchors": anchorCoords, "CameraPositions": cameraPositions]
        
        do {
            let jsonData = try
            JSONSerialization.data(withJSONObject:dataDictionary, options:.prettyPrinted)
            let storageRef =
            storageBaseRef.child("GeoAnchorTest").child(id + ".json")
            let fileType = StorageMetadata()
            fileType.contentType = "application/json"
            storageRef.putData(jsonData, metadata: fileType) { (metadata, error) in
                guard metadata != nil else {
                    // Uh-oh, an error occurred!
                    print("could not upload meta data to firebase", error!.localizedDescription)
                    return
                }
                print("Successfully uploaded log!", storageRef.fullPath)
            }
         
            // How to specify where these get uploaded (Create folder for data so it doesn't clog up central bucket)
            // How often can we upload this stuff/how big are these uploads? Don't want to overflow data limitations
            return storageRef.fullPath
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        // variable that determines whether current run should be logged to firebase or not. If set to true, change id to desired file name
        let logPath = true
        let id = "snapTestEight"
        
        cameraPoses.append([frame.camera.transform.columns.3[0], frame.camera.transform.columns.3[2]])
        
        let allGeoAnchors = frame.anchors.compactMap({$0 as? ARGeoAnchor})
//        print("nGeoAnchors \(allGeoAnchors.count)")
        var nCount = 0
        for geoAnchor in allGeoAnchors {
            if !simd_almost_equal_elements(geoAnchor.transform, matrix_identity_float4x4, 0.01) {
                nCount += 1
            }
        }

        if snapToRouteStatus {
            visualKeypoints = ViewController.routeKeypoints
            var transformedKeypoints: [KeypointInfo]  = []
            if let manualAlignment = manualAlignment {
                for keypoint in visualKeypoints{
                    transformedKeypoints.append(KeypointInfo(location: LocationInfo(transform: manualAlignment*keypoint.location.transform)))
                }
            } else {
                transformedKeypoints = visualKeypoints
            }
            if counter % 200 == 0 {
                cameraLocationInfos.append(LocationInfo(transform: frame.camera.transform))
            }
            if counter % 500 == 0 && localized && counter > 1800 {
                manualAlignment = PathMatcher().match(points: cameraLocationInfos, toPath: transformedKeypoints).inverse * (manualAlignment ?? matrix_identity_float4x4)
                renderKeypoint(RouteManager.shared.nextKeypoint!.location, defaultColor: 0)
//                renderPath(RouteManager.shared.nextKeypoint!.location, ViewController().getRealCoordinates(record: true)!.location, defaultPathColor: 0)
                let quat = simd_quatf(manualAlignment!.inverse)
                print("optimal transform", manualAlignment!.columns.3)
                print("axis and angle change", quat.axis, quat.angle)
//                sceneView.session.setWorldOrigin(relativeTransform: optimalTransform.inverse)
                print("Snapping my fingers")
            }
        }
        
        
        
        if logPath {
            counter += 1
            if counter % 400 == 0
            {
                print("sending data to firebase")
                var uploadToFirebase: [KeypointInfo] = []
                for keypoint in ViewController.routeKeypoints {
                    uploadToFirebase.append(KeypointInfo(location: LocationInfo(transform: (manualAlignment ?? matrix_identity_float4x4) * keypoint.location.transform)))
                }
                sendPathKeypoints("\(id)", uploadToFirebase, cameraPoses)
            }
        }
        if nCount == allGeoAnchors.count && nCount > 0, frame.geoTrackingStatus?.accuracy == ARGeoTrackingStatus.Accuracy.high {
            delegate?.geoAnchorsReadyForPathCreation(geoAnchors: allGeoAnchors)
            localized = true
        }
        if -lastTimeOutputtedGeoAnchors.timeIntervalSinceNow > 1 {
            lastTimeOutputtedGeoAnchors = Date()
            print("nGeoAnchors \(allGeoAnchors.count) non identity \(nCount)")
        }

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
        #if !APPCLIP
        ARLogger.shared.session(session, didUpdate: frame)
        guard delegate?.shouldLogRichData() == true else {
            return
        }
        
        if -lastFrameLogTime.timeIntervalSinceNow > 1.0 {
            ARLogger.shared.log(frame: frame, withType: delegate?.getLoggingTag() ?? "none", withMeshLoggingBehavior: .none)
            lastFrameLogTime = Date()
        }
        if -lastPoseLogTime.timeIntervalSinceNow > 0.1 {
            ARLogger.shared.logPose(pose: frame.camera.transform, at: frame.timestamp)
            lastPoseLogTime = Date()
        }
        #endif
        let imageAnchors = frame.anchors.compactMap({$0 as? ARImageAnchor})
        if !imageAnchors.isEmpty {
            delegate?.receivedImageAnchors(imageAnchors: imageAnchors)
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        #if !APPCLIP
        ARLogger.shared.session(session, didUpdate: anchors)
        #endif
        //print("update geoanchors", anchors.compactMap({$0 as? ARGeoAnchor}).count)
    }
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        #if !APPCLIP
        ARLogger.shared.session(session, didRemove: anchors)
        #endif
    }
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let geoAnchors = anchors.compactMap({$0 as? ARGeoAnchor})

        #if !APPCLIP
        ARLogger.shared.session(session, didAdd: anchors)
        #endif
        for geoAnchor in geoAnchors {
            if let nodeForAnchor = sceneView.node(for: geoAnchor), nodeForAnchor.childNodes.count == 0 {
                let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
                let node = SCNNode(geometry: box)
                node.position = SCNVector3(0,0,0)
                nodeForAnchor.addChildNode(node)
                print("creating node for geoanchor")
            }
        }
        print("nGeoAnchors \(geoAnchors.count)")
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
        if let nextKeypoint = RouteManager.shared.nextKeypoint, let cameraTransform = ARSessionManager.shared.currentFrame?.camera.transform {
            let previousKeypointLocation = RouteManager.shared.getPreviousKeypoint(to: nextKeypoint)?.location ?? LocationInfo(transform: cameraTransform)
            renderKeypoint(nextKeypoint.location, defaultColor: defaultColor)
            if showPath {
                renderPath(nextKeypoint.location, previousKeypointLocation, defaultPathColor: defaultPathColor)
            }
        }
        for intermediateAnchorPoint in RouteManager.shared.intermediateAnchorPoints {
            ARSessionManager.shared.render(intermediateAnchorPoints: [intermediateAnchorPoint])
        }
    }
}


extension ARSessionManager: ARSCNViewDelegate {
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("handling anchor add from renderer")
        handleAnchorUpdate(anchor: anchor)
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        //print("handling anchor update from renderer")
       //handleAnchorUpdate(anchor: anchor)
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
        if let nextKeypoint = RouteManager.shared.nextKeypoint, let cameraTransform = ARSessionManager.shared.currentFrame?.camera.transform {
            let previousKeypointLocation = RouteManager.shared.getPreviousKeypoint(to: nextKeypoint)?.location ?? LocationInfo(transform: cameraTransform)
            if nextKeypoint.location.identifier == anchor.identifier {
                 ARSessionManager.shared.renderKeypoint(nextKeypoint.location, defaultColor: defaultColor)
            }
            if nextKeypoint.location.identifier == anchor.identifier || previousKeypointLocation.identifier == anchor.identifier, showPath {
                renderPath(nextKeypoint.location, previousKeypointLocation, defaultPathColor: defaultPathColor)
            }
        }
        for intermediateAnchorPoint in RouteManager.shared.intermediateAnchorPoints {
            if let arAnchor = intermediateAnchorPoint.anchor, arAnchor.identifier == anchor.identifier {
                ARSessionManager.shared.render(intermediateAnchorPoints: [intermediateAnchorPoint])
            }
        }
    }
}

extension ARGeoTrackingStatus.Accuracy {
    var description: String {
        switch self {
        case .undetermined: return "Undetermined"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        @unknown default: return "Unknown"
        }
    }
}

func getLocalizationAccuracy(geoTrackingStatus: ARGeoTrackingStatus) {
    if geoTrackingStatus.state == .localized {
        print("Accuracy: \(geoTrackingStatus.accuracy.description)")
    }
}
