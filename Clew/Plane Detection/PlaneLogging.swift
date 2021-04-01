//
//  PlaneLogging.swift
//  Clew
//
//  Created by occamlab on 3/1/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage
import ARKit

class PlaneLogging {
    /// A handle to the Firebase storage
    let storageBaseRef = Storage.storage().reference()
    
    public func sendPlaneData(_ sceneView: ARSCNView, _ route: [KeypointInfo], _ idealizedDirections: [String]) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let timeStamp = df.string(from: Date())

        var body = [String: Any]()
        print("printing plane anchor classifications from logging")
        let routePlaneAnchors = sceneView.session.currentFrame?.anchors ?? []
        let keypointLocations = route.map({$0.location.translation.toArray()})
        for (index, anchor) in routePlaneAnchors.enumerated() {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
            print(index, planeAnchor.alignment, planeAnchor.classification.description)
            body[String(index)] = ["transform": planeAnchor.transform.debugDescription,
                                   "extent": planeAnchor.extent.debugDescription,
                                   "center": planeAnchor.center.debugDescription,
                                   "class": planeAnchor.classification.description,
                                   "keypoints": keypointLocations,
                                   "idealizedDirections": idealizedDirections,
                                   "align": planeAnchor.alignment.rawValue,
                                   "geometry": planeAnchor.geometry.vertices.debugDescription]
        }
        
        let fileName = "planes_2_with_directions.json" // TODO
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            self.uploadToFirebase(jsonData, fileName)
        } catch {
            print(error.localizedDescription)
        }

    }
    
    public func sendMeshData(_ sceneView: ARSCNView) {
        guard let frame = sceneView.session.currentFrame else {
            return
        }
        DispatchQueue.global().async {
            let start_time = Date()
            var body = [String: Any]()
            for (index, anchor) in frame.anchors.enumerated() {
                guard let meshAnchor = anchor as? ARMeshAnchor else { continue }
                body[String(index)] = [[String:Any]]()
                guard var array = body[String(index)] as? [[String:Any]] else {continue}
                print(meshAnchor.geometry.verticesOf(faceWithIndex: 0).debugDescription)
                for i in 0..<meshAnchor.geometry.faces.count {
                    //center point of each face needs to be converted to global coord system
                    let centerOfFace = meshAnchor.geometry.centerOf(faceWithIndex: i)
                    // Convert the face's center to world coordinates.
                    var centerLocalTransform = matrix_identity_float4x4
                    centerLocalTransform.columns.3 = SIMD4<Float>(centerOfFace.0, centerOfFace.1, centerOfFace.2, 1)
                    let center = (anchor.transform * centerLocalTransform)

                    array.append(["classification": meshAnchor.geometry.classificationOf(faceWithIndex: i).rawValue,
                                  "center": center.debugDescription,
                                "faceWithIndex": i,
                                "vertices": meshAnchor.geometry.verticesOf(faceWithIndex: i).debugDescription,
                                "transform": anchor.transform.debugDescription])
                }
                print(array.count)
                body[String(index)] = array
            }
            let fileName = "meshes_2.json" // TODO
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
                self.uploadToFirebase(jsonData, fileName)
            } catch {
                print(error.localizedDescription)
            }
            print("finished uploading mesh data in ", -start_time.timeIntervalSinceNow)
        }
    }
    
    private func uploadToFirebase(_ jsonData:Data, _ fileName: String) {
        // here "jsonData" is the dictionary encoded as a JSON
        let storageRef = storageBaseRef.child(fileName)
        print(jsonData)
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
    }
}

