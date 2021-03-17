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
    
    public func sendPlaneData(_ sceneView: ARSCNView) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let timeStamp = df.string(from: Date())

        var body = [String: Any]()
        let routePlaneAnchors = sceneView.session.currentFrame?.anchors ?? []
        for (index, anchor) in routePlaneAnchors.enumerated() {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
            
            print(index, planeAnchor.alignment, planeAnchor.classification)
            body[String(index)] = ["transform": planeAnchor.transform.debugDescription,
                                   "extent": planeAnchor.extent.debugDescription,
                                   "center": planeAnchor.center.debugDescription,
                                   "class": planeAnchor.classification.description,
                                   "align": planeAnchor.alignment.rawValue,
                                   "geometry": planeAnchor.geometry.vertices.debugDescription]
        }

        print(body)
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            // here "jsonData" is the dictionary encoded as a JSON
            let storageRef = storageBaseRef.child("planes_" + "1" + ".json") // TODO
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
                print(metadata)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

