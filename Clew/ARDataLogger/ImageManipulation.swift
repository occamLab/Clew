//
//  ImageManipulation.swift
//  LidarCane
//
//  Created by Paul Ruvolo on 2/10/21.
//

import Foundation
import VideoToolbox
import UIKit
import ARKit

extension UIImage {
    func cropToSquareCenteredAt(x: CGFloat, y: CGFloat, cropSize: CGFloat) -> UIImage {
        let cropRect = CGRect(x: x - cropSize/2, y: y - cropSize/2, width: cropSize, height: cropSize)
        let imageRef = self.cgImage?.cropping(to: cropRect)
        let cropped = UIImage(cgImage: imageRef!, scale: 0.0, orientation: self.imageOrientation)
        
        return cropped
    }

    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

    func resize(targetSize: CGSize) -> UIImage? {
        let widthRatio  = targetSize.width  / self.size.width
        let heightRatio = targetSize.height / self.size.height
        
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    static func pixelBufferToUIImage(pixelBuffer: CVPixelBuffer) -> UIImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        return cgImage.map{UIImage(cgImage: $0)}
    }
    
    static func getIdealizedCoordinates(planarPositions: [simd_float2])->[CGPoint] {
        if planarPositions.isEmpty {
            return []
        }
        let pixelsPerMeter = Float(400)
        let minCoord = simd_float2(x: planarPositions.map({$0.x}).min()!, y: planarPositions.map({$0.y}).min()!)
        let shifted = planarPositions.map({$0 - minCoord})
        return shifted.map({ CGPoint(x: Int($0.x*pixelsPerMeter), y: Int($0.y*pixelsPerMeter))})
    }
}

extension CVPixelBuffer {
    var size: (Int, Int) {
        return (CVPixelBufferGetWidth(self), CVPixelBufferGetHeight(self))
    }
}


extension Array where Element == CGPoint {
    func containsPoint(_ p: CGPoint) -> Bool {
        if count < 1 {
            // degenerate polygon
            return false
        }
        for (vi, viPlus1) in zip(self, self[1...] + [self[0]]) {
            let viShifted = simd_float2(Float(vi.x - p.x), Float(vi.y - p.y))
            let viPlus1Shifted = simd_float2(Float(viPlus1.x - p.x), Float(viPlus1.y - p.y))
            if viShifted.x*viPlus1Shifted.y - viPlus1Shifted.x*viShifted.y <= 0 {
                return false
            }
        }
        return true
    }
}

// - MARK: Creating point cloud
func saveSceneDepth(depthMapBuffer: CVPixelBuffer, confMapBuffer: CVPixelBuffer) -> PointCloud {
    let width = CVPixelBufferGetWidth(depthMapBuffer)
    let height = CVPixelBufferGetHeight(depthMapBuffer)
    CVPixelBufferLockBaseAddress(depthMapBuffer, CVPixelBufferLockFlags(rawValue: 0))
    let depthBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthMapBuffer), to: UnsafeMutablePointer<Float32>.self)
    var depthCopy = [Float32](repeating: 0.0, count: width*height)
    memcpy(&depthCopy, depthBuffer, width*height*MemoryLayout<Float32>.size)
    CVPixelBufferUnlockBaseAddress(depthMapBuffer, CVPixelBufferLockFlags(rawValue: 0))
    var confCopy = [ARConfidenceLevel](repeating: .high, count: width*height)
    // TODO: speed this up using some unsafe C-like operations. Currently we just allow it to be turned off to save time
    CVPixelBufferLockBaseAddress(confMapBuffer, CVPixelBufferLockFlags(rawValue: 0))
    let confBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(confMapBuffer), to: UnsafeMutablePointer<UInt8>.self)
    for i in 0..<width*height {
        confCopy[i] = ARConfidenceLevel(rawValue: Int(confBuffer[i])) ?? .low
    }
    CVPixelBufferUnlockBaseAddress(confMapBuffer, CVPixelBufferLockFlags(rawValue: 0))
    return PointCloud(width: width, height: height, depthData: depthCopy, confData: confCopy)
}

extension CVPixelBuffer {
    func toUIImage() -> UIImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(self, options: nil, imageOut: &cgImage)
        return cgImage.map{UIImage(cgImage: $0)}
    }
}
