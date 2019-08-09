//
//  TestFlightLogger.swift
//  Clew
//
//  Created by Kawin Nikomborirak on 8/8/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import Firebase

class TestFlightLogger {
    
    public struct TestFlightJSON: Codable {
        var beginRouteLandmarkIntrinsics: String?
        var beginRouteLandmarkPose: String?
        var endRouteLandmarkIntrinsics: String?
        var endRouteLandmarkPose: String?
        var intrinsics: String?
        var pose: String?
    }
    
    /// Log landmark alignment info and return the filename of the logged folder.
    static func uploadData(savedRoute: SavedRoute, image: UIImage, intrinsics: simd_float3x3, pose: simd_float4x4) -> String {
        let storageref = Storage.storage().reference().child("testflightdata")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd:hh:mm:ss"
        let subdir = "\(dateFormatter.string(from: Date()))-\(UUID().uuidString)"
        let subref = storageref.child(subdir)
        let beginRouteLandmark = savedRoute.beginRouteLandmark
        let endRouteLandmark = savedRoute.endRouteLandmark
        var testFlightJSON = TestFlightJSON()
        
        if let beginRouteLandmarkImageFileName = beginRouteLandmark.imageFileName {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            subref.child("beginRouteLandmarkImage.jpg").putFile(from: beginRouteLandmarkImageFileName.documentURL, metadata: metadata)
        }

        if let endRouteLandmarkImageFileName = endRouteLandmark.imageFileName {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            subref.child("endRouteLandmarkImage.jpg").putFile(from: endRouteLandmarkImageFileName.documentURL, metadata: metadata)
        }
        
        if let imageData = image.jpegData(compressionQuality: 1) {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            subref.child("image.jpg").putData(imageData, metadata: metadata)
        }
        
        testFlightJSON.beginRouteLandmarkIntrinsics = beginRouteLandmark.intrinsics?.toString()
        testFlightJSON.beginRouteLandmarkPose = beginRouteLandmark.transform?.toString()
        testFlightJSON.endRouteLandmarkIntrinsics = endRouteLandmark.intrinsics?.toString()
        testFlightJSON.endRouteLandmarkPose = endRouteLandmark.transform?.toString()
        testFlightJSON.intrinsics = intrinsics.toString()
        testFlightJSON.pose = pose.toString()
        
        if let data = try? JSONEncoder().encode(testFlightJSON) {
            let metadata = StorageMetadata()
            metadata.contentType = "application/json"
            subref.child("matrices.json").putData(data, metadata: metadata)
        }
        
        return subdir
    }
}
