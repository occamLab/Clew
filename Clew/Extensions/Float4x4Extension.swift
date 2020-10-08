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

extension Array where Element: FloatingPoint {

    func sum() -> Element {
        return self.reduce(0, +)
    }

    func avg() -> Element {
        return self.sum() / Element(self.count)
    }

    func std() -> Element {
        let mean: Element = self.avg()
        var ssd: Element = 0
        for e in self {
            ssd += (e - mean)*(e-mean)
        }
        return sqrt(ssd / (Element(self.count) - 1))
    }

    func mean_abs_dev() -> Element {
        let mean = self.avg()
        let v = self.reduce(0, { $0 + abs($1-mean) })
        return v / Element(self.count)
    }
}

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
