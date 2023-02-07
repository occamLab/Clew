//
//  AlignmentFilter.swift
//  Clew
//
//  Created by Paul Ruvolo on 2/7/23.
//  Copyright © 2022 OccamLab. All rights reserved.
//

import Foundation
import ARKit

class AlignmentFilter {
    var manualAlignments: [simd_float4x4] = []
    
    func update(proposed: simd_float4x4, old: simd_float4x4)->simd_float4x4? {
        let relativeShift = old.inverse * proposed
        let angleDiff = simd_quatf(relativeShift)
        let positionDiff = simd_length(relativeShift.columns.3.dropw())
        if angleDiff.angle < 0.005 && positionDiff < 0.05 {
            // not worth updating
            return nil
        }
        if angleDiff.angle > 0.5 || positionDiff > 5.0 {
            // probably an outlier
            return nil
        }

        // TODO: maybe some averaging?
        manualAlignments.append(proposed)
        return proposed
    }

    func reset() {
        manualAlignments = []
    }
}
