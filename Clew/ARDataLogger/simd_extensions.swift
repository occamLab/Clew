//
//  simd_extensions.swift
//  LidarCane
//
//  Created by Paul Ruvolo on 1/26/21.
//

import Foundation
import ARKit

extension simd_float4x4 {
    var xAxis: simd_float3 {
        return simd_float3(self.columns.0.x, self.columns.0.y, self.columns.0.z)
    }
    var yAxis: simd_float3 {
        return simd_float3(self.columns.1.x, self.columns.1.y, self.columns.1.z)
    }
    var zAxis: simd_float3 {
        return simd_float3(self.columns.2.x, self.columns.2.y, self.columns.2.z)
    }
    var translation: simd_float3 {
        return simd_float3(self.columns.3.x, self.columns.3.y, self.columns.3.z)
    }
    /// Get the rotation component of the transform.
    func rotation() -> float3x3 {
        return simd_float3x3(simd_float3(self[0, 0], self[0, 1], self[0, 2]),
                             simd_float3(self[1, 0], self[1, 1], self[1, 2]),
                             simd_float3(self[2, 0], self[2, 1], self[2, 2]))
    }
    
    var asColumnMajorArray: [Float] {
        return columns.0.asArray + columns.1.asArray + columns.2.asArray + columns.3.asArray
    }
}

extension simd_float3x3 {
    /// Cast the rotation as a 4x4 matrix encoding the rotation and no translation.
    func toPose()->float4x4 {
        return simd_float4x4(simd_float4(self[0, 0], self[0, 1], self[0, 2], 0),
                             simd_float4(self[1, 0], self[1, 1], self[1, 2], 0),
                             simd_float4(self[2, 0], self[2, 1], self[2, 2], 0),
                             simd_float4(0, 0, 0, 1))
    }
    
    var asColumnMajorArray:[Float] {
        return columns.0.asArray + columns.1.asArray + columns.2.asArray
    }
}

extension simd_float2 {
    init(_ p: CGPoint) {
        self.init(x: Float(p.x), y: Float(p.y))
    }
    func toCGPoint()->CGPoint {
        return CGPoint(x: CGFloat(self.x), y: CGFloat(self.y))
    }
    func twoDCrossProduct(_ other: simd_float2)->Float {
        return self.x*other.y - self.y*other.x
    }
}

extension simd_float3 {
    var homogeneous: simd_float4 {
        return simd_float4(x: self.x, y: self.y, z: self.z, w: 1.0)
    }
    var normalized: simd_float3 {
        return simd_normalize(self)
    }
    func magnitudeOfAngleBetween(_ other: simd_float3)->Float {
        return abs(signedAngleBetween(other))
    }
    func signedAngleBetween(_ other: simd_float3)->Float {
        let crossProd = simd_cross(self.normalized, other.normalized)
        let normal = crossProd.normalized
        return atan2(simd_dot(crossProd, normal), simd_dot(self.normalized, other.normalized))
    }
    
    var xz: simd_float2 {
        return simd_float2(x: x, y: z)
    }
    
    var asArray: [Float] {
        return [x, y, z]
    }
}


extension simd_float4 {
    var inhomogeneous: simd_float3 {
        return simd_float3(x: self.x, y: self.y, z: self.z)
    }
    var asArray: [Float] {
        return [x, y, z, w]
    }
}
