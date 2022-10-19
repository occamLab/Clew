import ARKit
import FirebaseAuth
import FirebaseStorage

protocol ARDataLoggerAdapter {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor])
    func session(_ session: ARSession, didAdd anchors: [ARAnchor])
    func session(_ session: ARSession, didRemove anchors: [ARAnchor])
    func session(_ session: ARSession, didUpdate frame: ARFrame)
}

public enum MeshLoggingBehavior {
    case none
    case all
    case updated
}

public class ARLogger: ARDataLoggerAdapter {
    public static var shared = ARLogger()
    let uploadManager = UploadManager.shared
    var voiceFeedback: URL?
    var trialID: String?
    var poseLog: [(Double, simd_float4x4)] = []
    var trialLog: [(Double, Any)] = []
    var attributes: [String: Any] = [:]
    var configLog: [String: Bool]?
    var finalizedSet: Set<String> = []
    var lastBodyDetectionTime = Date()
    var baseTrialPath: String = ""
    public var dataDir: String?
    public var enabled = true
    var frameSequenceNumber: Int = 0
    var lastTimeStamp:Double = -1
    public var doAynchronousUploads: Bool {
        get {
            return uploadManager.writeDataToDisk
        }
        set {
            uploadManager.writeDataToDisk = newValue
        }
    }
    
    private init() {
    }
    
    
    func addAudioFeedback(audioFileURL: URL) {
        guard enabled else {
            return
        }
        voiceFeedback = audioFileURL
    }
    
    func addFrame(frame: ARFrameDataLog) {
        guard enabled else {
            return
        }
        // if we saw a body recently, we can't log the data
        if -lastBodyDetectionTime.timeIntervalSinceNow > 1.0 {
            frameSequenceNumber += 1
            DispatchQueue.global(qos: .background).async { [frameSequenceNumber = self.frameSequenceNumber] in
                self.uploadAFrame(frameSequenceNumber: frameSequenceNumber, frame: frame)
            }
        }
    }
    
    public func logString(logMessage: String) {
        guard enabled else {
            return
        }
        trialLog.append((lastTimeStamp, logMessage))
    }
    
    public func logDictionary(logDictionary: [String : Any]) {
        guard enabled else {
            return
        }
        guard JSONSerialization.isValidJSONObject(logDictionary) else {
            return
        }
        trialLog.append((lastTimeStamp, logDictionary))
    }
    
    public func logPose(pose: simd_float4x4, at time: Double) {
        guard enabled else {
            return
        }
        poseLog.append((time, pose))
    }
    
    public func hasLocalDataToUploadToCloud()->Bool {
        guard enabled else {
            return false
        }
        return uploadManager.hasLocalDataToUploadToCloud()
    }
    
    public func uploadLocalDataToCloud(completion: ((StorageMetadata?, Error?) -> Void)? = nil) {
        guard enabled else {
            return
        }
        uploadManager.uploadLocalDataToCloud(completion: completion)
    }
    
    public func isConnectedToNetwork()->Bool {
        return InternetConnectionUtil.isConnectedToNetwork()
    }
    
    public func uploadLocalDataToCloud(completion: @escaping ((Bool) -> Void)) {
        guard enabled else {
            return
        }
        uploadManager.uploadLocalDataToCloud() { (metdata, error) in
            completion(error == nil)
        }
    }
    
    private func uploadLog() {
        guard enabled else {
            return
        }
        guard let logJSON = try? JSONSerialization.data(withJSONObject: trialLog.map({["timestamp": $0.0, "message": $0.1]}), options: .prettyPrinted) else {
            return
        }
        let logPath = "\(baseTrialPath)/log.json"
        UploadManager.shared.putData(logJSON, contentType: "application/json", fullPath: logPath)
    }
    
    private func uploadPoses() {
        guard enabled else {
            return
        }
        guard let poseJSON = try? JSONSerialization.data(withJSONObject: poseLog.map({["timestamp": $0.0, "pose": $0.1.asColumnMajorArray]}), options: .prettyPrinted) else {
            return
        }
        let posesPath = "\(baseTrialPath)/poses.json"
        UploadManager.shared.putData(poseJSON, contentType: "application/json", fullPath: posesPath)
        print("Uploading poses")
    }
    
    private func uploadConfig() {
        guard enabled else {
            return
        }
        guard let configLog = configLog else {
            return
        }
        guard let configJSON = try? JSONSerialization.data(withJSONObject: configLog, options: .prettyPrinted) else {
            return
        }
        let configPath = "\(baseTrialPath)/config.json"
        UploadManager.shared.putData(configJSON, contentType: "application/json", fullPath: configPath)
        guard let attributeJSON = try? JSONSerialization.data(withJSONObject: attributes, options: .prettyPrinted) else {
            return
        }
        let attributesPath = "\(baseTrialPath)/attributes.json"
        UploadManager.shared.putData(attributeJSON, contentType: "application/json", fullPath: attributesPath)
        print("Uploading configuration log")
    }
    
    private func uploadAFrame(frameSequenceNumber: Int, frame: ARFrameDataLog) {
        guard enabled else {
            return
        }
        let imagePath = "\(baseTrialPath)/\(String(format:"%04d", frameSequenceNumber))/frame.jpg"
        UploadManager.shared.putData(frame.jpegData, contentType: "image/jpeg", fullPath: imagePath)
        guard let frameMetaData = frame.metaDataAsJSON() else {
            //NavigationController.shared.logString("Error: failed to get frame metadata")
            return
        }
        let metaDataPath = "\(baseTrialPath)/\(String(format:"%04d", frameSequenceNumber))/framemetadata.json"
        UploadManager.shared.putData(frameMetaData, contentType: "application/json", fullPath: metaDataPath)
        if let meshData = frame.meshesToProtoBuf() {
            let meshDataPath = "\(baseTrialPath)/\(String(format:"%04d", frameSequenceNumber))/meshes.pb"
            // TODO: gzipping gives a 30-40% reduction.  let compressedData: Data = try! meshData.gzipped()
            UploadManager.shared.putData(meshData, contentType: "application/x-protobuf", fullPath: meshDataPath)
        }
        if let pointCloud = frame.pointCloudToProtoBuf() {
            let pointCloudDataPath = "\(baseTrialPath)/\(String(format:"%04d", frameSequenceNumber))/pointcloud.pb"
            // TODO: gzipping gives a 30-40% reduction.  let compressedData: Data = try! meshData.gzipped()
            UploadManager.shared.putData(pointCloud, contentType: "application/x-protobuf", fullPath: pointCloudDataPath)
        }
        print("Uploading a frame?")
    }
    
    public func finalizeTrial() {
        guard enabled else {
            return
        }
        guard let trialID = self.trialID else {
            return
        }
        guard !self.finalizedSet.contains(trialID) else {
            // can't finalize the trial more than once
            return
        }
        finalizedSet.insert(trialID)
        // Upload audio to Firebase
        if let voiceFeedback = voiceFeedback, let data = try? Data(contentsOf: voiceFeedback) {
            let audioFeedbackPath = "\(baseTrialPath)/voiceFeedback.wav"
            UploadManager.shared.putData(data, contentType: "audio/wav", fullPath: audioFeedbackPath)
        }
        print("tpath", baseTrialPath)
        uploadLog()
        uploadPoses()
        uploadConfig()
        // Might want to tell the user to upload the data occasionally
    }
    
    public func startTrial() {
        guard enabled else {
            return
        }
        resetInternalState()
        // Easier to navigate older vs newer data uploads
        trialID = "\(UUID())"
        logConfig()

        guard let user = Auth.auth().currentUser, let trialID = self.trialID else {
            print("User is not logged in")
            return
        }
        if let dataDir = dataDir {
            baseTrialPath = "\(dataDir)/\(user.uid)/\(trialID)"
        } else {
            baseTrialPath = "\(user.uid)/\(trialID)"
        }
        print("Starting trial", baseTrialPath)
    }
    
    func logConfig() {
        //configLog = CodesignConfiguration.shared.configAsDict()
    }
    
    func logAttribute(key: String, value: Any) {
        guard enabled else {
            return
        }
        if JSONSerialization.isValidJSONObject([key: value]) {
            attributes[key] = value
        } else {
            //NavigationController.shared.logString("Unable to log \(key) as its value cannot be serialized to JSON")
        }
    }
    
    private func resetInternalState() {
        voiceFeedback = nil
        trialID = nil
        trialLog = []
        poseLog = []
        attributes = [:]
        configLog = nil
        frameSequenceNumber = 0
    }
    
    func processNewBodyDetectionStatus(bodyDetected: Bool) {
        guard enabled else {
            return
        }
        if bodyDetected {
            lastBodyDetectionTime = Date()
        }
    }
    
    
    var meshNeedsUploading: [UUID: Bool] = [:]
    var meshRemovalFlag: [UUID: Bool] = [:]
    var meshesAreChanging: Bool = false
    
    func getMeshArrays(frame: ARFrame, meshLoggingBehavior: MeshLoggingBehavior)->[(String, [String: [[Float]]])]? {
        guard enabled else {
            return nil
        }
        // TODO: could maybe speed this up using unsafe C operations and the like.  Probably this is not needed though
        var meshUpdateCount = 0
        // Boolean flag, when true, sessions do not collect data on added and updated meshes until flag is turned back off at end of function
        meshesAreChanging = true
        if meshLoggingBehavior == .none {
            return nil
        }
        var meshArrays: [(String,[String: [[Float]]])] = []
        for (key, value) in meshRemovalFlag {
            if value {
                meshArrays.append((key.uuidString, ["transform": [matrix_identity_float4x4.columns.0.asArray, matrix_identity_float4x4.columns.1.asArray, matrix_identity_float4x4.columns.2.asArray, matrix_identity_float4x4.columns.3.asArray], "vertices": [], "normals": []]))
                meshRemovalFlag[key] = false
            }
        }
        for mesh in frame.anchors.compactMap({$0 as? ARMeshAnchor }) {
            if meshLoggingBehavior == .all || meshNeedsUploading[mesh.identifier] == true {
                meshUpdateCount += 1
                meshNeedsUploading[mesh.identifier] = false
                var vertices: [[Float]] = []
                var normals: [[Float]] = []
                var vertexPointer = mesh.geometry.vertices.buffer.contents().advanced(by: mesh.geometry.vertices.offset)
                var normalsPointer = mesh.geometry.normals.buffer.contents().advanced(by: mesh.geometry.normals.offset)
                for _ in 0..<mesh.geometry.vertices.count {
                    let normal = normalsPointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
                    let vertex = vertexPointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
                    normals.append([normal.0, normal.1, normal.2])
                    vertices.append([vertex.0, vertex.1, vertex.2])
                    normalsPointer = normalsPointer.advanced(by: mesh.geometry.normals.stride)
                    vertexPointer = vertexPointer.advanced(by: mesh.geometry.vertices.stride)
                }
                
                meshArrays.append((mesh.identifier.uuidString, ["transform": [mesh.transform.columns.0.asArray, mesh.transform.columns.1.asArray, mesh.transform.columns.2.asArray, mesh.transform.columns.3.asArray], "vertices": vertices, "normals": normals]))
            }
        }
        print("updated \(meshUpdateCount)")
        meshesAreChanging = false
        return meshArrays
    }
    
    public func log(frame: ARFrame, withType type: String, withMeshLoggingBehavior meshLoggingBehavior: MeshLoggingBehavior) {
        guard enabled else {
            return
        }
        guard let dataLogFrame = toLogFrame(frame: frame, type: type, meshLoggingBehavior: meshLoggingBehavior) else {
            print("could not create ARFrameDataLog")
            return
        }
        addFrame(frame: dataLogFrame)
    }
    
    public func toLogFrame(frame: ARFrame, type: String, meshLoggingBehavior: MeshLoggingBehavior)->ARFrameDataLog? {
        guard enabled else {
            return nil
        }
        guard let uiImage = frame.capturedImage.toUIImage(), let jpegData = uiImage.jpegData(compressionQuality: 0.5) else {
            return nil
        }
        // Pointclouds for LiDAR phones
        var transformedCloud: [simd_float4] = []
        var confData: [ARConfidenceLevel] = []
        if let depthMap = frame.sceneDepth?.depthMap, let confMap = frame.sceneDepth?.confidenceMap {
            let pointCloud = saveSceneDepth(depthMapBuffer: depthMap, confMapBuffer: confMap)
            confData = pointCloud.confData
            let xyz = pointCloud.getFastCloud(intrinsics: frame.camera.intrinsics, strideStep: 1, maxDepth: 1000, throwAwayPadding: 0, rgbWidth: CVPixelBufferGetWidth(frame.capturedImage), rgbHeight: CVPixelBufferGetHeight(frame.capturedImage))
            // Come back to this
            for p in xyz {
                transformedCloud.append(simd_float4(simd_normalize(p.0), simd_length(p.0)))
            }
        }
        
        let meshes = getMeshArrays(frame: frame, meshLoggingBehavior: meshLoggingBehavior)
        // Mesh length should not increase and remain around stable or fluttering within a certain range
        if let meshes = meshes {
            print("Mesh count: \(String(describing: meshes.count))")
        }
        
        return ARFrameDataLog(timestamp: frame.timestamp, type: type, jpegData: jpegData,  rawFeaturePoints: frame.rawFeaturePoints?.points, projectedFeaturePoints: frame.rawFeaturePoints?.points.map({feature in frame.camera.projectPoint(feature, orientation: .landscapeRight, viewportSize: frame.camera.imageResolution)}), confData: confData, depthData: transformedCloud, intrinsics: frame.camera.intrinsics, planes: frame.anchors.compactMap({$0 as? ARPlaneAnchor}), pose: frame.camera.transform, meshes: meshes)
    }
    
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        var allUpdatedMeshes: [UUID] = []
        for id in anchors.compactMap({$0 as? ARMeshAnchor}).map({$0.identifier}) {
            if !meshesAreChanging {
                meshNeedsUploading[id] = true
                allUpdatedMeshes.append(id)
            }
        }
    }
    
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for id in anchors.compactMap({$0 as? ARMeshAnchor}).map({$0.identifier}) {
            if !meshesAreChanging {
                meshNeedsUploading[id] = true
                meshRemovalFlag[id] = false
            }
        }
    }
    
    public func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for id in anchors.compactMap({$0 as? ARMeshAnchor}).map({$0.identifier}) {
            meshRemovalFlag[id] = true
        }
    }
    
    // - MARK: Running app session
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        lastTimeStamp = frame.timestamp
    }
    
}
