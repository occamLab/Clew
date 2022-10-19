//
//  FloatVectorExtension.swift
//  Clew
//
//  Created by Ayush Chakraborty on 6/6/22.
//  Copyright © 2022 OccamLab. All rights reserved.
//

import Foundation
import VectorMath
import ARKit
import LASwift

extension float4x4 {
    /// Returns the Frobenius norm of the matrix
    ///
    /// - Returns: the frobenius norm
    func frobenius()->Float {
        return sqrt(simd_length_squared(columns.0) + simd_length_squared(columns.1) + simd_length_squared(columns.2) + simd_length_squared(columns.3))
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
