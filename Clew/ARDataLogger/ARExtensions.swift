//
//  ARAnchorExtensions.swift
//  LidarCane
//
//  Created by Paul Ruvolo on 2/3/21.
//

import Foundation
import ARKit

// - MARK: ARPlaneAnchor
extension ARPlaneAnchor {
    func intersectWith(camera: ARCamera, padding: Float = 0.0)->[CGPoint] {
        return intersectWith(cameraTransform: camera.transform, cameraIntrinsics: camera.intrinsics, padding: padding)
    }
    
    func intersectWith(cameraTransform: simd_float4x4, cameraIntrinsics: simd_float3x3, padding:Float = 0.0)->[CGPoint] {
        let cornerPixels = projectPlaneCoordinate(cameraTransform: cameraTransform, cameraIntrinsics: cameraIntrinsics, planeTransform: self.transform, xBounds: (self.center.x - self.extent.x/2 - padding, self.center.x + self.extent.x/2 + padding), y: self.center.y, zBounds: (self.center.z - self.extent.z/2 - padding, self.center.z + self.extent.z/2 + padding))
        return getCounterClockwisePixels(cornerPixels)
    }
    
    /// Compute the pixel coordinates where the corners of a plane would be imaged by the specified camera.  If a corner point is behind the camera, the point is thrown out?
    /// - Parameters:
    ///   - cameraTransform: the transform from camera coordinates to world coordinates
    ///   - cameraIntrinsics: the camera intrinsics (focal lengths and center pixel location)
    ///   - planeTransform: the transform from plane coordinates to world coordinates
    ///   - xBounds: the x-axis boundaries of the plane defined in its local coordinate system
    ///   - y: the y-axis boundary of the plane defined in its local coordinate system
    ///   - zBounds: the z-axis boundaries of the plane defined in its local coordinate system
    /// - Returns: a list of pixel coordinates where the plane corners would be imaged.  The returned list has at most 4 pixels.
    private func projectPlaneCoordinate(cameraTransform: simd_float4x4, cameraIntrinsics: simd_float3x3, planeTransform: simd_float4x4, xBounds: (Float, Float), y:Float, zBounds: (Float, Float))->[CGPoint] {
        var corners : [simd_float3] = []
        // shrink direction tells us how to shrink the plane to get it appear in front of the camera.  This is not ideal, but it is better than throwing away corners that are behind the plane
        var shrinkDirections : [simd_float3] = []

        corners.append(simd_float3(xBounds.0, y, zBounds.0))
        shrinkDirections.append(simd_normalize(simd_float3(1,0,1)))
        corners.append(simd_float3(xBounds.0, y, zBounds.1))
        shrinkDirections.append(simd_normalize(simd_float3(1,0,-1)))
        corners.append(simd_float3(xBounds.1, y, zBounds.0))
        shrinkDirections.append(simd_normalize(simd_float3(-1,0,1)))
        corners.append(simd_float3(xBounds.1, y, zBounds.1))
        shrinkDirections.append(simd_normalize(simd_float3(-1,0,-1)))
        
        // viewMat goes from homogeneous plane coordinates to homogenous pixel locations
        let viewMat = cameraIntrinsics * simd_float4x3(simd_float3(1, 0, 0), simd_float3(0, -1, 0), simd_float3(0, 0, -1), simd_float3(0, 0, 0))*cameraTransform.inverse * planeTransform
        
        var pixelCoords : [CGPoint] = []
        for (corner, shrinkDirection) in zip(corners, shrinkDirections) {
            var homogeneousPixelCoordinates = viewMat * simd_float4(corner, 1.0)
            // if the homogeneous pixel coordinate's z component is negative, then the corner is behind the camera, we can try to move the corner until it comes in front of the camera
            if homogeneousPixelCoordinates.z < 0 {
                let shiftScalar = shrinkDirection.x*viewMat.columns.0.z + shrinkDirection.z*viewMat.columns.2.z
                if shiftScalar != 0 {
                    let shiftMagnitude = (0.01 - homogeneousPixelCoordinates.z)/shiftScalar
                    let correctedCorner = shiftMagnitude*shrinkDirection + corner
                    // we can only apply the correction if the corrected corner now falls in front of the camera
                    if correctedCorner.x >= xBounds.0 && correctedCorner.x <= xBounds.1 && correctedCorner.z >= zBounds.0 && correctedCorner.z <= zBounds.1 {
                        print("applied correction")
                        homogeneousPixelCoordinates = viewMat * simd_float4(correctedCorner, 1.0)
                    }
                }
            }
            if homogeneousPixelCoordinates.z > 0 {
                let pixelCoord = CGPoint(x: CGFloat(homogeneousPixelCoordinates.x / homogeneousPixelCoordinates.z), y: CGFloat(homogeneousPixelCoordinates.y / homogeneousPixelCoordinates.z))
                pixelCoords.append(pixelCoord)
            }
        }
        return pixelCoords
    }
    
    var area: Float {
        return self.extent.x*self.extent.z
    }
    
    var isWall: Bool {
        if case .wall = self.classification {
            return true
        } else {
            return false
        }
    }
    
    func getXZIntersection(other: ARPlaneAnchor)->simd_float2? {
        // We'll use the approach from Wikipedia here: https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line
        let p1Self = simd_float2(self.transform.translation.x, self.transform.translation.z)
        // The xaxis is perpendicular (more or less) to gravity
        let p2Self = simd_float2(self.transform.xAxis.x + self.transform.translation.x, self.transform.xAxis.z + self.transform.translation.z)
        let p1Other = simd_float2(other.transform.translation.x, other.transform.translation.z)
        let p2Other = simd_float2(other.transform.xAxis.x + other.transform.translation.x, other.transform.xAxis.z + other.transform.translation.z)
        // Following the notation in the link above we define the following
        let x1 = p1Self.x
        let y1 = p1Self.y
        let x2 = p2Self.x
        let y2 = p2Self.y
        let x3 = p1Other.x
        let y3 = p1Other.y
        let x4 = p2Other.x
        let y4 = p2Other.y
    
        let D = (x1-x2)*(y3-y4) - (y1-y2)*(x3-x4)
        guard D != 0 else {
            return nil
        }
        let leftSide: Float = ((x1*y2 - y1*x2)*(x3-x4) - (x1-x2)*(x3*y4-y3*x4))/D
        let rightSide: Float = ((x1*y2-y1*x2)*(y3-y4) - (y1-y2)*(x3*y4 - y3*x4))/D
        return simd_float2(leftSide, rightSide)
    }
    
    var worldCenter: simd_float3 {
        return (transform * center.homogeneous).inhomogeneous
    }
}

// - MARK: ARCamera
extension ARCamera.TrackingState {
    // cleans up some of the logic in other places
    var isRelocalizing: Bool {
        if case .limited(reason: .relocalizing) = self {
            return true
        } else {
            return false
        }
    }
    
    var isDegradedOrMissing: Bool {
        return !isNormal || !isRelocalizing
    }
    
    var isNormal: Bool {
        if case .normal = self {
            return true
        } else {
            return false
        }
    }
}

// - MARK: ARFrame
extension ARFrame {
    func contains(_ p: CGPoint)->Bool {
        return ARFrame.contains(imageBounds: capturedImage.size, p)
    }
    
    func isStable(prevTransform: simd_float4x4)->Bool {
        let (deltaTranslation, deltaAngle) = getDeltaFromLastFrame(prevTransform: prevTransform)
        return deltaTranslation < 0.01 && deltaAngle < 0.04
    }
    
    func getDeltaFromLastFrame(prevTransform: simd_float4x4)->(Float, Float) {
        let relPose = camera.transform.inverse*prevTransform
        let q = simd_quatf(relPose)
        let deltaAngle = q.angle
        let deltaTranslation = simd_length(relPose.translation)
        return (deltaTranslation, deltaAngle)
    }

    func isPointedOptimally()->Bool {
        let cameraOptimalAxisAngleToWorldVertical = acos(simd_dot(camera.transform.zAxis, simd_float3(0, 1, 0))) * 180.0/Float.pi
        return abs(cameraOptimalAxisAngleToWorldVertical - 90) < 40
    }
    
    static func contains(imageBounds: (Int, Int), _ p: CGPoint)->Bool {
        return Int(p.x) >= 0 && Int(p.x) < imageBounds.0 && Int(p.y) >= 0 && Int(p.y) < imageBounds.1
    }
    
    static func intersectionWith(imageBounds: (Int, Int), lineSegment: (CGPoint, CGPoint))->[CGPoint] {
        let width = imageBounds.0
        let height = imageBounds.1
        var intersections: [CGPoint] = []
        
        // check each of the sides of the bounding box
        if let leftIntersection = intersect(lineSegment1: lineSegment, withLineSegment: (CGPoint(x: 0, y: 0), CGPoint(x:0, y: height-1))) {
            intersections.append(leftIntersection)
        }
        if let rightIntersection = intersect(lineSegment1: lineSegment, withLineSegment: (CGPoint(x: width-1, y: 0), CGPoint(x:width-1, y: height-1))) {
            intersections.append(rightIntersection)
        }
        if let topIntersection = intersect(lineSegment1: lineSegment, withLineSegment: (CGPoint(x: 0, y: 0), CGPoint(x:width-1, y: 0))) {
            intersections.append(topIntersection)
        }
        if let bottomIntersection = intersect(lineSegment1: lineSegment, withLineSegment: (CGPoint(x: 0, y: height-1), CGPoint(x:width-1, y: height-1))) {
            intersections.append(bottomIntersection)
        }
        return intersections
    }
    
    func intersectionWith(lineSegment: (CGPoint, CGPoint))->[CGPoint] {
        return ARFrame.intersectionWith(imageBounds: capturedImage.size, lineSegment: lineSegment)
    }

    private static func intersect(lineSegment1: (CGPoint, CGPoint), withLineSegment lineSegment2: (CGPoint, CGPoint))->CGPoint? {
        // Using this approach: https://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect
        let p = simd_float2(lineSegment1.0)
        let q = simd_float2(lineSegment2.0)
        let r = simd_float2(lineSegment1.1) - p
        let s = simd_float2(lineSegment2.1) - q
        
        guard r.twoDCrossProduct(s) != 0 else {
            // TODO: this doesn't handle the case where the segments are colinear, but this shouldn't happen in practice
            return nil
        }

        let t = (q - p).twoDCrossProduct(s) / r.twoDCrossProduct(s)
        let u = (q - p).twoDCrossProduct(r) / r.twoDCrossProduct(s)
        
        guard t >= 0 && t <= 1 && u >= 0 && u <= 1 else {
            return nil
        }
        
        return (p + t*r).toCGPoint()
    }
    
    var numPixels:Int {
        return CVPixelBufferGetWidth(self.capturedImage)*CVPixelBufferGetHeight(self.capturedImage)
    }
    
    func getRay(forPixel pixel: CGPoint)->(simd_float3, simd_float3){
        return getRayHelper(forPixel: pixel, withIntrinsics: self.camera.intrinsics, withCameraTransform: self.camera.transform)
    }
    
    func getIntersectionPolygons(planes: [ARPlaneAnchor], padding: Float = 0.0)->[[CGPoint]] {
        return ARFrame.getIntersectionPolygons(imageBounds: capturedImage.size, cameraTransform: camera.transform, cameraIntrinsics: camera.intrinsics, planes: planes, padding: padding)
    }
    
    static func getIntersectionPolygons(imageBounds: (Int, Int), cameraTransform: simd_float4x4, cameraIntrinsics: simd_float3x3, planes: [ARPlaneAnchor], padding: Float = 0.0)->[[CGPoint]] {
        var intersectionPolygons : [[CGPoint]] = []

        for anchor in planes {
            let cornerPixelsCCW = anchor.intersectWith(cameraTransform: cameraTransform, cameraIntrinsics: cameraIntrinsics, padding: padding)
            var intersectionPolygon : [CGPoint] = []
            if cornerPixelsCCW.isEmpty {
                intersectionPolygons.append(intersectionPolygon)
                continue
            }
            for (corner, nextCorner) in zip(cornerPixelsCCW, cornerPixelsCCW[1...] + [cornerPixelsCCW[0]]) {
                if ARFrame.contains(imageBounds: imageBounds, corner) {
                    intersectionPolygon.append(corner)
                }
                if !ARFrame.contains(imageBounds: imageBounds, corner) || !ARFrame.contains(imageBounds: imageBounds, nextCorner) {
                    let newIntersections = ARFrame.intersectionWith(imageBounds: imageBounds, lineSegment: (corner, nextCorner))
                    intersectionPolygon = intersectionPolygon + newIntersections
                }
            }
            // see if we need to add the corners
            for x in [0, imageBounds.0-1] {
                for y in [0, imageBounds.1-1] {
                    let cornerPixel = CGPoint(x: x, y: y)
                    if cornerPixelsCCW.containsPoint(cornerPixel) {
                        intersectionPolygon.append(cornerPixel)
                    }
                }
            }
            if intersectionPolygon.count == 3 {
                // This happens if a side of the plane cuts through the camera image, forming a triangle.  To work better with OpenCV, we need to define another intersection point with the plane.  To do this we can just take the midpoint of any two of the intersection vertices
                intersectionPolygon.append(CGPoint(x: (intersectionPolygon[0].x + intersectionPolygon[1].x)/2, y: (intersectionPolygon[0].y + intersectionPolygon[1].y)/2))
            } else if intersectionPolygon.count == 1 || intersectionPolygon.count == 2 {
                print("these could be legit if they intersect at a single point or on a line, but also show up when one or more of the pixels of the plane is behind the camera")
            }
            intersectionPolygons.append(getCounterClockwisePixels(intersectionPolygon))
        }

        
        return intersectionPolygons
    }
    
    static func getPlaneCoordinates(transform: simd_float4x4, intrinsics: simd_float3x3, pixelCoordinates: [CGPoint], plane: ARPlaneAnchor)->[simd_float2]? {
        var planeIntersections: [simd_float2] = []
        for pixelCoordinate in pixelCoordinates {
            let (castOrigin, castDirection) = getRayHelper(forPixel: pixelCoordinate, withIntrinsics: intrinsics, withCameraTransform: transform)
            let castOriginInPlaneCoordinates = plane.transform.inverse * castOrigin.homogeneous
            let castDirectionInPlaneCoordinates = plane.transform.inverse.rotation() * castDirection
            guard castDirectionInPlaneCoordinates.y != 0 else {
                return nil
            }
            let rayScalar = (plane.center.y-castOriginInPlaneCoordinates.y)/castDirectionInPlaneCoordinates.y
            guard rayScalar > 0 else {
                return nil
            }
            let intersectionPointInPlaneCoordinates = rayScalar * castDirectionInPlaneCoordinates + castOriginInPlaneCoordinates.inhomogeneous
            planeIntersections.append(simd_float2(intersectionPointInPlaneCoordinates.x, intersectionPointInPlaneCoordinates.z))
            
        }
        return planeIntersections
    }
    
    func getPlaneCoordinates(pixelCoordinates: [CGPoint], plane: ARPlaneAnchor)->[simd_float2]? {
        return ARFrame.getPlaneCoordinates(transform: camera.transform, intrinsics: camera.intrinsics, pixelCoordinates: pixelCoordinates, plane: plane)
    }
}

// - MARK: getRayHelper func
func getRayHelper(forPixel: CGPoint, withIntrinsics intrinsics: simd_float3x3, withCameraTransform transform: simd_float4x4)->(simd_float3, simd_float3) {
    let rayDirection = intrinsics.inverse * simd_float3(Float(forPixel.x), Float(forPixel.y), 1.0)
    
    // The camera coordinates for ARKit have x going across the image, positive y going up and negative z going away from the camera (see https://developer.apple.com/documentation/arkit/arworldalignment/arworldalignmentcamera?language=objc)
    let rayDirectionTransformed = simd_float3(rayDirection.x, -rayDirection.y, -rayDirection.z)

    let castOrigin = transform.translation
    let castDirection = transform.rotation() * rayDirectionTransformed
    return (castOrigin, castDirection)
}
