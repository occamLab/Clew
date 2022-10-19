//
//  CGPointUtilities.swift
//  LidarCane
//
//  Created by Paul Ruvolo on 2/4/21.
//

import Foundation
import Accelerate
import ARKit

func getCounterClockwisePixels(_ cornerPixels: [CGPoint])->[CGPoint] {
    let cornerVecs = cornerPixels.map({ simd_float2($0) })
    // compute the centroid to define counterclockwise order.  Since the quadrilateral is guaranteed to be convex, t
    let centroid = cornerVecs.reduce(simd_float2(0.0, 0.0)) {
        return $0 + $1/Float(cornerPixels.count)
    }
    let angles = cornerVecs.map({ atan2($0.y - centroid.y, $0.x - centroid.x) })
    // sort based on the angles (ascending order gives us counterclockwise)
    let combined = zip(angles, cornerPixels).sorted {$0.0 < $1.0}
    // extract just the CGPoints that have now been reordered
    return combined.map({ $0.1 })
}

func getPolyArea(points: [CGPoint])->Float {
    // We use the shoelace formula to compute the area
    var area = Float(0.0)
    guard points.count > 0 else {
        return area
    }
    let ccwPoints = getCounterClockwisePixels(points).map({ simd_float2($0) })
    for (corner, nextCorner) in zip(ccwPoints, ccwPoints[1...] + [ccwPoints[0]]) {
        area += (corner.x*nextCorner.y - nextCorner.x*corner.y)/2.0
    }
    return area
}
