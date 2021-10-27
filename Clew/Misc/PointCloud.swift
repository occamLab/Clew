//
//  PointCloud.swift
//  LidarCane
//
//  Created by Paul Ruvolo on 3/2/21.
//

import Foundation
import ARKit

class PointCloud: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    
    let width: Int
    let height: Int
    let depthData: [Float32]
    var debugImages: [UIImage] = []
    
    init(width: Int, height: Int, depthData: [Float32]) {
        self.width = width
        self.height = height
        self.depthData = depthData
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(NSNumber(value: width), forKey: "width")
        coder.encode(NSNumber(value: height), forKey: "height")
        coder.encode(depthData, forKey: "depthData")
    }
    
    required convenience init?(coder: NSCoder) {
        guard let depthData = coder.decodeObject(forKey: "depthData") as? [Float32], let width = coder.decodeObject(forKey: "width") as? NSNumber, let height = coder.decodeObject(forKey: "height") as? NSNumber else {
            return nil
        }
        self.init(width: Int(truncating: width), height: Int(truncating: height), depthData: depthData)
    }
    
    func normalizedCoordinateToDepth(coord: (Float, Float))->Float {
        let (depthX, depthY) = (coord.0*Float(width-1), coord.1*Float(height-1))

        // do bilinear interpolation
        var validX:[Float] = []
        var validY:[Float] = []
        
        let isDepthXAnInteger = depthX.truncatingRemainder(dividingBy: 1) == 0.0
        let isDepthYAnInteger = depthY.truncatingRemainder(dividingBy: 1) == 0.0

        if Int(floor(depthX)) >= 0 {
            validX.append(floor(depthX))
        }
        // the check for an integer value prevents the same value from being inserted twice into validX.  If the same value appears twice, the formulas for interpolation won't work properly
        if !isDepthXAnInteger && Int(ceil(depthX)) < width {
            validX.append(ceil(depthX))
        }
        if Int(floor(depthY)) >= 0 {
            validY.append(floor(depthY))
        }
        if !isDepthYAnInteger && Int(ceil(depthY)) < height {
            validY.append(ceil(depthY))
        }
        if validX.count == 0 || validY.count == 0 {
            return Float.nan
        } else if validX.count == 1 && validY.count == 1 {
            return depthData[Int(validY[0])*width + Int(validX[0])]
        } else if validX.count == 1 {
            // linear interpolation on y (x is fixed)
            let f0 = depthData[Int(validY[0])*width + Int(validX[0])]
            let f1 = depthData[Int(validY[1])*width + Int(validX[0])]
            return f0*(Float(validY[1]) - depthY) + f1*(depthY - Float(validY[0]))
        } else if validY.count == 1 {
            // linear interpolation on x (y is fixed)
            let f0 = depthData[Int(validY[0])*width + Int(validX[0])]
            let f1 = depthData[Int(validY[0])*width + Int(validX[1])]
            return f0*(Float(validX[1]) - depthX) + f1*(depthX - Float(validX[0]))
        } else {
            // bilinear interpolation
            let f00 = depthData[Int(validY[0])*width + Int(validX[0])]
            let f01 = depthData[Int(validY[1])*width + Int(validX[0])]
            let f10 = depthData[Int(validY[0])*width + Int(validX[1])]
            let f11 = depthData[Int(validY[1])*width + Int(validX[1])]
            let F = simd_float2x2(columns: (simd_float2(f00, f10), simd_float2(f01, f11)))
            let rhsVec = simd_float2(validY[1] - depthY, depthY - validY[0])
            let lhsVec = simd_float2(validX[1] - depthX, depthX - validX[0])
            return simd_dot(lhsVec, F*rhsVec)
        }
    }
    
    func getFastCloud(intrinsics: simd_float3x3, strideStep: Int, maxDepth: Float, throwAwayPadding: Int, rgbWidth: Int, rgbHeight: Int, useMaxPooling: Bool = false)->[(simd_float3, (Float, Float))] {
        // TODO: could precompute the rays to save time (the intrinsics matrix is mostly constant over time)
        var pointCloud: [(simd_float3, (Float, Float))] = []
        let intrinsicsInverse = intrinsics.inverse
        for i: Int in stride(from: throwAwayPadding, to: width - throwAwayPadding, by: strideStep) {
            for j: Int in stride(from: throwAwayPadding, to: height - throwAwayPadding, by: strideStep) {
                var cameraPixelIJ: (Float, Float)?
                var pointInCameraFrameTransformedIJ: simd_float3?
                
                var localCloud: [simd_float3] = []
                for k in stride(from: i, to: i + (useMaxPooling ? strideStep : 1), by: 1) {
                    for l in stride(from: j, to: j + (useMaxPooling ? strideStep : 1), by:1) {
                        let normalizedCoordKL = (Float(k)/Float(width-1), Float(l)/Float(height-1))
                        let cameraPixelKL = (normalizedCoordKL.0*Float(rgbWidth-1), normalizedCoordKL.1*Float(rgbHeight-1))
                        let pointDepth = depthData[l*width + k]
                        //let pointConfidence = confData[l*width + k]

                        if pointDepth > 0 && pointDepth < maxDepth {// && pointConfidence == .high {
                            let ray = intrinsicsInverse * simd_float3(x: cameraPixelKL.0, y: cameraPixelKL.1, z: 1.0)
                            // the depth is the distance to the camera's image plane
                            let pointInCameraFrame = pointDepth*ray
                            // the ray needs to be converted to the appropriate convention for the camera transform
                            let pointInCameraFrameTransformed = simd_float3(pointInCameraFrame.x, -pointInCameraFrame.y, -pointInCameraFrame.z)
                            localCloud.append(pointInCameraFrameTransformed)
                            if k == i && j == l {
                                pointInCameraFrameTransformedIJ = pointInCameraFrameTransformed
                                cameraPixelIJ = cameraPixelKL
                            }
                        }
                    }
                }
                if let pointInCameraFrameTransformedIJ = pointInCameraFrameTransformedIJ, let cameraPixelIJ = cameraPixelIJ {
                    pointCloud.append((simd_float3(pointInCameraFrameTransformedIJ.x, localCloud.max(by: { $0.y < $1.y })!.y, pointInCameraFrameTransformedIJ.z), cameraPixelIJ))
                }
            }
        }
        return pointCloud
    }
    
    func toCSV(points: [simd_float3]) {
        for p in points {
            print("\(p.x), \(p.y), \(p.z)")
        }
    }
    
}
