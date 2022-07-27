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
    
    func update(anchorTransform: simd_float4x4, geoSpatialAlignmentCrumb: LocationInfoGeoSpatial, cameraGeospatialTransform: GARGeospatialTransform)->simd_float4x4? {
        guard let geoAnchorTransform = geoSpatialAlignmentCrumb.geoAnchorTransform else {
            return nil
        }
        
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
        // TODO: this could get slow
        let relativeHeadingAngles = relativeTransforms.map({ existingRelativeTransform in Self.getHeadingAngleOffset(pose1: existingRelativeTransform, pose2: relativeTransform) })
        // TODO: use this somehow
        let relativeOrigins = relativeTransforms.map({ existingRelativeTransform in (relativeTransform.columns.3 - existingRelativeTransform.columns.3).dropw() })
        
        if relativeTransforms.isEmpty {
            return false
        } else if relativeTransforms.count < 5 {
            let averageHeadingOffsetMagnitude = relativeHeadingAngles.map(abs).avg()
            // check for suspiciously high average offset magnitude compared to purported heading accuracy.  The headingAccuracy confidence band should at least trap the average offset magnitude
            return averageHeadingOffsetMagnitude > Float(cameraGeospatialTransform.headingAccuracy * Double.pi/180.0)
        } else {
            // TODO: could also use the reported heading accuracy (i.e., the standard deviation)
            let zScore = relativeHeadingAngles.avg() / relativeHeadingAngles.std()
            return abs(zScore) > 1.0
        }
    }
    
    func reset() {
        relativeTransforms = []
    }
}
