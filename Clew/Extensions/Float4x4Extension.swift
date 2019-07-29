//
//  Float4x4Extension.swift
//  Clew
//
//  Created by Dieter Brehm on 6/4/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//
// extension of apple's float4x4 matrix type

import Foundation
import VectorMath
import ARKit

extension float4x4 {
    /// Create a rotation matrix based on the angle and axis.
    ///
    /// - Parameters:
    ///   - radians: the angle to rotate through
    ///   - x: the x-component of the axis to rotate about
    ///   - y: the y-component of the axis to rotate about
    ///   - z: the z-component of the axis to rotate about
    /// - Returns: a 4x4 transformation matrix that performs this rotation
    static func makeRotate(radians: Float, _ x: Float, _ y: Float, _ z: Float) -> float4x4 {
        return unsafeBitCast(GLKMatrix4MakeRotation(radians, x, y, z), to: float4x4.self)
    }

    /// Create a translation matrix based on the translation vector.
    ///
    /// - Parameters:
    ///   - x: the x-component of the translation vector
    ///   - y: the y-component of the translation vector
    ///   - z: the z-component of the translation vector
    /// - Returns: a 4x4 transformation matrix that performs this translation
    static func makeTranslation(_ x: Float, _ y: Float, _ z: Float) -> float4x4 {
        return unsafeBitCast(GLKMatrix4MakeTranslation(x, y, z), to: float4x4.self)
    }

    /// Perform the specified rotation (right multiply) on the 4x4 matrix
    ///
    /// - Parameters:
    ///   - radians: the angle to rotate through
    ///   - x: the x-component of the axis to rotate about
    ///   - y: the y-component of the axis to rotate about
    ///   - z: the z-component of the axis to rotate about
    /// - Returns: the result of applying the transformation as 4x4 matrix
    func rotate(radians: Float, _ x: Float, _ y: Float, _ z: Float) -> float4x4 {
        return self * float4x4.makeRotate(radians: radians, x, y, z)
    }

    /// Perform the specified translation (right multiply) on the 4x4 matrix
    ///
    /// - Parameters:
    ///   - x: the x-component of the translation vector
    ///   - y: the y-component of the translation vector
    ///   - z: the z-component of the translation vector
    /// - Returns: the result of applying the transformation as 4x4 matrix
    func translate(x: Float, _ y: Float, _ z: Float) -> float4x4 {
        return self * float4x4.makeTranslation(x, y, z)
    }
    
    func toString() -> String {
        return """
        \(self[0, 0]),\(self[1, 0]),\(self[2, 0]),\(self[3, 0])
        \(self[0, 1]),\(self[1, 1]),\(self[2, 1]),\(self[3, 1])
        \(self[0, 2]),\(self[1, 2]),\(self[2, 2]),\(self[3, 2])
        \(self[0, 3]),\(self[1, 3]),\(self[2, 3]),\(self[3, 3])
        """
    }
    
    /// Get the rotation component of the transform.
    func rotation() -> float3x3 {
        return simd_float3x3(simd_float3(self[0, 0], self[0, 1], self[0, 2]),
                             simd_float3(self[1, 0], self[1, 1], self[1, 2]),
                             simd_float3(self[2, 0], self[2, 1], self[2, 2]))
    }

    /// The x translation specified by the transform
    var x: Float {
        return columns.3.x
    }

    /// The y translation specified by the transform
    var y: Float {
        return columns.3.y
    }

    /// The z translation specified by the transform
    var z: Float {
        return columns.3.z
    }

    /// The yaw specified by the transforms
    var yaw: Float {
        return LocationInfo(anchor: ARAnchor(transform: self)).yaw
    }
}
