//
//  PathMatcher.swift
//  Clew
//
//  Created by Paul Ruvolo on 7/3/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import ARKit

/// This class manages the path matching process between a set of keypoints, which typically represent the piecewise linear route being traveled, and a user's path, which typically represent the user's actual position as they navigate that path.
class PathMatcher {
    /// Match a set of points to the specified route and return the optimal rigid body transform that aligns them.  We restrict ourselves to transforms that combine an arbitrary 3D translation with a rotation about the y-axis of the world.  The y-axis is aligned with gravity.
    ///
    /// - Parameters:
    ///   - points: the points to match
    ///   - keypoints: the route keypoints, which are assumed to represent a piecewise linear path.  These should be in the order in which the user is traversing the path.
    /// - Returns: an optimal rigid body transform represented as a 4x4 matrix
    func match(points: [LocationInfo], toPath keypoints: [KeypointInfo])->simd_float4x4 {
        var optimalTransform = matrix_identity_float4x4
        var lastIterationCost = Float.infinity

        while true {    // convergence is determined in the loop
            let transformedFollowCrumbs = transformLocationInfo(locations: points, transform: optimalTransform)

            let closestMatchToRoute = getClosestRouteMatch(points: transformedFollowCrumbs, routeKeypoints: keypoints)

            let currentCost = zip(transformedFollowCrumbs, closestMatchToRoute).reduce(0) {
                $0 + simd_length_squared($1.0 - $1.1)
            }
            
            if lastIterationCost - currentCost < 10e-4 {
                break
            }
            lastIterationCost = currentCost

            var additionalTransform = matrix_identity_float4x4
            
            let meanOfFollowCrumbs = transformedFollowCrumbs.reduce(simd_float4(0, 0, 0, 0)) {
                $0 + $1 / (Float(transformedFollowCrumbs.count))
            }
            let meanOfClosestMatches = closestMatchToRoute.reduce(simd_float4(0, 0, 0, 0)) {
                $0 + $1 / (Float(closestMatchToRoute.count))
            }
            
            let meanSubtractedFollowCrumbs = transformedFollowCrumbs.map({$0 - meanOfFollowCrumbs})
            let meanSubtractedClosestMatches = closestMatchToRoute.map({$0 - meanOfClosestMatches})
            let outerProductMatrix = zip(meanSubtractedClosestMatches, meanSubtractedFollowCrumbs).reduce(simd_float2x2()) {
                $0 + simd_float2($1.0.x, $1.0.z).outerProduct(simd_float2($1.1.x, $1.1.z))
            }
            
            var (U, S, V) = outerProductMatrix.svd()
            
            if S.columns.0.x.isNaN {
                S.columns.0.x = 0
            }
            if S.columns.1.y.isNaN {
                S.columns.1.y = 0
            }
            let R: simd_float2x2
            if max(S.columns.0.x, S.columns.1.y) < 10e-5 {
                // apply no rotation
                R = matrix_identity_float2x2
            } else {
                // Note that this is inverted from what we see in various resources on ICP since we are implicitly rotating about the negative y-axis and would really like rotate about the positive y-axis.  By nature of projecting into the x-z plane and computing the orientation there, we are implicitly rotating about the negative y-axis.
                R = V * simd_float2x2(diagonal: simd_float2(1, (V*U.transpose).determinant)) * U.transpose
            }
            
            // Calculate optimal transform difference by applying the appropriate formula from http://ais.informatik.uni-freiburg.de/teaching/ss11/robotics/slides/17-icp.pdf
            
            additionalTransform.columns.0.x = R.columns.0.x
            additionalTransform.columns.2.z = R.columns.1.y
            additionalTransform.columns.0.z = R.columns.1.x
            additionalTransform.columns.2.x = R.columns.0.y
            
            // this sets the translation based on the appropriate formula
            additionalTransform.columns.3 = meanOfClosestMatches - additionalTransform*meanOfFollowCrumbs
            
            
            // this will accidentally change element (4, 4) to 0
            additionalTransform.columns.3.w = 1

            optimalTransform = additionalTransform * optimalTransform

            // convergence is achieved if the additional transform is close to the identity
            if (additionalTransform - matrix_identity_float4x4).frobenius() < 10e-4 {
                break
            }
        }
        return optimalTransform
    }

    /// Transform location info by applying the specified transform.
    ///
    /// - Parameters:
    ///   - locations: the array of locations
    ///   - transform: the transform to apply (multiplied on the left)
    /// - Returns: the transformed locations represented as an array of homogeneous 3D coordinates.
    func transformLocationInfo(locations: [LocationInfo], transform: simd_float4x4)->[simd_float4] {
        return locations.map {
            transform * simd_float4($0.x, $0.y, $0.z, 1)
        }
    }
    
    /// Determines the closet point to each of `points` on the piecewise linear route defined by `routeKeypoints`.  The definition of closest is given by the L2 norm.
    ///
    /// - Parameters:
    ///   - points: the points to match to the route
    ///   - routeKeypoints: the route keypoints
    /// - Returns: an array of homogenous 3D vectors representing the closet matched point.
    func getClosestRouteMatch(points: [simd_float4], routeKeypoints: [KeypointInfo])->[simd_float4] {
        var closestPoints: [simd_float4] = []
        
        for p in points {
            var closestPoint = simd_float3()
            var closestDistance = Float.infinity
            
            for i in 0..<routeKeypoints.count-1 {
                let startOfSegment = simd_float3(routeKeypoints[i].location.x, routeKeypoints[i].location.y, routeKeypoints[i].location.z)
                let endOfSegment = simd_float3(routeKeypoints[i+1].location.x, routeKeypoints[i+1].location.y, routeKeypoints[i+1].location.z)
                let closestOnSegment = closestPointOnSegment(p.inhomogeneous, start: startOfSegment, end: endOfSegment)
                let d = simd_length(closestOnSegment - p.inhomogeneous)
                if d < closestDistance {
                    closestDistance = d
                    closestPoint = closestOnSegment
                }
            }
            closestPoints.append(closestPoint.homogeneous)
        }
        
        return closestPoints
    }
    
    /// Compute the closet point on a line segment to the specified input point.
    ///
    /// - Parameters:
    ///   - p: the point to match to the line segment
    ///   - start: the starting point of the line segment
    ///   - end: the ending point of the line segment
    /// - Returns: the closet point (in the L2 sense) to `p` on the line segment connecting `start` and `end`.
    func closestPointOnSegment(_ p: simd_float3, start: simd_float3, end: simd_float3)->simd_float3 {
        let startToEnd = end - start
        let vToP = p - start
        let proj = simd_dot(vToP, simd_normalize(startToEnd))
        // clamp proj so it doesn't go past either end of the line segment
        let projClamped = min(max(0, proj), simd_length(startToEnd))
        return start + projClamped*simd_normalize(startToEnd)
    }
}
