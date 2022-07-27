//
//  GeoSpatialAlignment.swift
//  Clew-More
//
//  Created by Paul Ruvolo on 7/26/22.
//  Copyright © 2022 OccamLab. All rights reserved.
//

import Foundation
import ARCoreGeospatial

class GeoSpatialAlignment {
    var relativeTransforms: [simd_float4x4] = []
    var lastAnchorTransform: simd_float4x4?
    
    func update(anchorTransform: simd_float4x4, geoSpatialAlignmentCrumb: LocationInfoGeoSpatial, cameraGeospatialTransform: GARGeospatialTransform)->simd_float4x4? {
        guard let geoAnchorTransform = geoSpatialAlignmentCrumb.geoAnchorTransform else {
            return nil
        }
        
        if let lastAnchorTransform = lastAnchorTransform {
            let relativeShift = lastAnchorTransform.inverse * anchorTransform
            let angleDiff = simd_quatf(relativeShift)
            let positionDiff = simd_length(relativeShift.columns.3.dropw())
            if angleDiff.angle < 0.01 && positionDiff < 0.1 {
                return nil
            }
        }
        lastAnchorTransform = anchorTransform
        PathLogger.shared.logGeospatialTransform(cameraGeospatialTransform)

        print("something new!")
        
        let relativeTransform = anchorTransform * geoAnchorTransform.inverse
        
        if isOutlier(relativeTransform: relativeTransform, cameraGeospatialTransform: cameraGeospatialTransform) {
            return nil
        }
        // TODO: maybe some averaging?
        relativeTransforms.append(relativeTransform)
        return relativeTransform
    }
    
    private static func getHeadingAngleOffset(pose1: simd_float4x4, pose2: simd_float4x4)->Float {
        // Note: ordering the components as z and then x is consistent with a positive rotation about the y-axis causing an increasing (positive) angle with the z-axis.
        let v = simd_float2(pose1.columns.2.z, pose1.columns.2.x)
        let w = simd_float2(pose2.columns.2.z, pose2.columns.2.x)
        
        // Using formula from here https://wumbo.net/formulas/angle-between-two-vectors-2d/
        return atan2(w[1]*v[0] - w[0]*v[1], w[0]*v[0] + w[1]*v[1])
    }
    
    private func isOutlier(relativeTransform: simd_float4x4, cameraGeospatialTransform: GARGeospatialTransform)->Bool {
        // TODO: this could get slow (currently filtering)
        let relativeHeadingAngles = relativeTransforms.map({ existingRelativeTransform in Self.getHeadingAngleOffset(pose1: existingRelativeTransform, pose2: relativeTransform) })
        // TODO: use this somehow
        let relativeOrigins = relativeTransforms.map({ existingRelativeTransform in (relativeTransform.columns.3 - existingRelativeTransform.columns.3).dropw() })
        
        if relativeTransforms.isEmpty {
            return false
        } else if relativeTransforms.count < 5 {
            let averageHeadingOffsetMagnitude = relativeHeadingAngles.avg()
            // check for suspiciously high average offset magnitude compared to purported heading accuracy.  Twice the headingAccuracy confidence band should at least trap the average offset magnitude
            if averageHeadingOffsetMagnitude > 2.0*Float(cameraGeospatialTransform.headingAccuracy * Double.pi/180.0) {
                //AnnouncementManager.shared.announce(announcement: "outlier 1")
                return true
            }
        } else {
            // check for suspiciously high average offset magnitude compared to purported heading accuracy.  The twice the headingAccuracy confidence band should at least trap the average offset magnitude
            if abs(relativeHeadingAngles.avg()) > 2.0*Float(cameraGeospatialTransform.headingAccuracy * Double.pi/180.0) {
                //AnnouncementManager.shared.announce(announcement: "outlier 1 \(relativeHeadingAngles.count) \(abs(relativeHeadingAngles.avg()))")
                return true
            }
        }
        //AnnouncementManager.shared.announce(announcement: "inlier \(relativeHeadingAngles.count)")
        return false
    }
    
    func reset() {
        relativeTransforms = []
    }
}
