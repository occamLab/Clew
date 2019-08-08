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
import LASwift

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
    
    
    /// a leveled pose suitable for alignment
    var level: float4x4 {
        let yaw = ViewController.getYawHelper(self)
        var leveledOrientation = simd_float4x4.makeRotate(radians: yaw, 0, 1, 0)
        leveledOrientation.columns.3 = self.columns.3
        return leveledOrientation
    }
    
    /// A transform where the orientation has been rotated about the y-axis by pi radians.  The translation remains static.
    var flipOrientationAboutYAxis: float4x4 {
        var returnValue = matrix_identity_float4x4
        returnValue.columns.0 = columns.0
        returnValue.columns.1 = columns.1
        returnValue.columns.2 = columns.2
        returnValue = simd_float4x4.makeRotate(radians: Float.pi, 0, 1, 0)*returnValue
        returnValue.columns.3 = columns.3
        return returnValue
    }
    
    /// Returns the Frobenius norm of the matrix
    ///
    /// - Returns: the frobenius norm
    func frobenius()->Float {
        return sqrt(simd_length_squared(columns.0) + simd_length_squared(columns.1) + simd_length_squared(columns.2) + simd_length_squared(columns.3))
    }
}

extension float3x3 {
    /// Convert the matrix to csv format.
    func toString()->String {
        return """
        \(self[0, 0]),\(self[1, 0]),\(self[2, 0])
        \(self[0, 1]),\(self[1, 1]),\(self[2, 1])
        \(self[0, 2]),\(self[1, 2]),\(self[2, 2])
        """
    }
    
    /// Cast the rotation as a 4x4 matrix encoding the rotation and no translation.
    func toPose()->float4x4 {
        return simd_float4x4(simd_float4(self[0, 0], self[0, 1], self[0, 2], 0),
                             simd_float4(self[1, 0], self[1, 1], self[1, 2], 0),
                             simd_float4(self[2, 0], self[2, 1], self[2, 2], 0),
                             simd_float4(0, 0, 0, 1))
    }
}

// MARK: - Extensions for 3D floating point vector type

extension float3 {
    /// convert from a 3-element inhomogeneous vector to a 4-element homogeneous one.
    var homogeneous: float4 {
        return float4(x, y, z, 1)
    }
}

// MARK: - Extensions for 4D floating point vector type

extension float4 {
    /// convert from a 4-element homogeneous vector to a 3-element inhomogeneous one.  This attribute only makes sense if the 4-element vector is a homogeneous representation of a 3D point.
    var inhomogeneous: float3 {
        return float3(x/w, y/w, z/w)
    }
}

// MARK: - Extension for the two dimensional floating point vector type

extension float2 {
    /// Computes the outer product between the float2 vector and the passed in float2 vector
    ///
    /// - Parameter other: the other vector to use for the outer product
    /// - Returns: the outer product as a 2x2 matrix
    func outerProduct(_ other: float2)->float2x2 {
        return float2x2(columns: (float2(self.x*other.x, self.y*other.x), float2(self.x*other.y, self.y*other.y)))
    }
}

// MARK: - Extension for the 2x2 dimensional floating point matrix type

extension float2x2 {
    /// Computes the SVD of the 2x2 matrix
    ///
    /// - Returns: U, S, V such that U * S * V.T is the original matrix
    func svd()->(float2x2, float2x2, float2x2) {
        let usv = LASwift.svd(toMatrix())
        return (simd_float2x2.fromMatrix(usv.U), simd_float2x2.fromMatrix(usv.S), simd_float2x2.fromMatrix(usv.V))
    }
    
    /// Create a float2x2 from a LASwift style 2x2 matrix
    ///
    /// - Parameter m: a 2x2 matrix in LASwift format
    /// - Returns: a float2x2 matrix
    static func fromMatrix(_ m : Matrix)->simd_float2x2 {
        return simd_float2x2(columns: (simd_float2(Float(m[0, 0]), Float(m[1,0])), simd_float2(Float(m[0,1]), Float(m[1,1]))))
    }
    
    /// Crete a LASwift style matrix from the float2x2
    ///
    /// - Returns: a LASwift style 2x2 matrix
    func toMatrix()->Matrix {
        return Matrix([[Double(columns.0.x), Double(columns.1.x)], [Double(columns.0.y), Double(columns.1.y)]])
    }
}
