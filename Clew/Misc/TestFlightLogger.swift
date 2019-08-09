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
    static func uploadData(savedRoute: SavedRoute, image: UIImage, intrinsics: simd_float3x3, pose: simd_float4x4) {
        let storageref = Storage.storage().reference().child("testflightdata")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let subdir = "\(dateFormatter.string(from: Date()))-\(UUID().uuidString)"
        let subref = storageref.child(subdir)
        let beginRouteLandmark = savedRoute.beginRouteLandmark
        let endRouteLandmark = savedRoute.endRouteLandmark
        
        if let beginRouteLandmarkImageFileName = beginRouteLandmark.imageFileName {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            subref.child("beginRouteLandmarkImage.jpg").putFile(from: beginRouteLandmarkImageFileName.documentURL, metadata: metadata)
        }
        
        if let beginRouteLandmarkPoseData = beginRouteLandmark.transform?.toString().data(using: .utf8) {
            let metadata = StorageMetadata()
            metadata.contentType = "text/plain"
            subref.child("beginRouteLandmarkPose.txt").putData(beginRouteLandmarkPoseData, metadata: metadata)
        }
        
        if let beginRouteLandmarkIntrinsicsData = beginRouteLandmark.intrinsics?.toString().data(using: .utf8) {
            let metadata = StorageMetadata()
            metadata.contentType = "text/plain"
            subref.child("beginRouteLandmarkIntrinsics.txt").putData(beginRouteLandmarkIntrinsicsData, metadata: metadata)
        }
        
        if let endRouteLandmarkImageFileName = endRouteLandmark.imageFileName {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            subref.child("endRouteLandmarkImage.jpg").putFile(from: endRouteLandmarkImageFileName.documentURL, metadata: metadata)
        }
        
        if let endRouteLandmarkPoseData = endRouteLandmark.transform?.toString().data(using: .utf8) {
            let metadata = StorageMetadata()
            metadata.contentType = "text/plain"
            subref.child("endRouteLandmarkPose.txt").putData(endRouteLandmarkPoseData, metadata: metadata)
        }
        
        if let endRouteLandmarkIntrinsicsData = endRouteLandmark.intrinsics?.toString().data(using: .utf8) {
            let metadata = StorageMetadata()
            metadata.contentType = "text/plain"
            subref.child("endRouteLandmarkIntrinsics.txt").putData(endRouteLandmarkIntrinsicsData, metadata: metadata)
        }
        
        if let imageData = image.jpegData(compressionQuality: 1) {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            subref.child("image.jpg").putData(imageData, metadata: metadata)
        }
        
        if let intrinsicsData = intrinsics.toString().data(using: .utf8) {
            let metadata = StorageMetadata()
            metadata.contentType = "text/plain"
            subref.child("intrinsics.txt").putData(intrinsicsData, metadata: metadata)
        }
        
        if let poseData = pose.toString().data(using: .utf8) {
            let metadata = StorageMetadata()
            metadata.contentType = "text/plain"
            subref.child("poseData.txt").putData(poseData, metadata: metadata)
        }
    }
}
