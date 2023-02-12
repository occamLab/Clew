
//  UIViewExtensions.swift
//  Clew
//
//  Created by Dieter Brehm on 6/10/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func imageWithSize(scaledToSize newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
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
}

extension UIView {
    /// Used to identify the mainText UILabel
    static let mainTextTag: Int = 1001
    /// Used to identify the pause button so that it can be enabled or disabled
    static let pauseButtonTag: Int = 1002
    /// Used to identify the read voice note button tag so that it can be enabled or disabled
    static let readVoiceNoteButtonTag: Int = 1003

    /// Custom fade used for direction text UILabel.
    func fadeTransition(_ duration: CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.push
        animation.subtype = CATransitionSubtype.fromTop
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
    
    /// the main text UILabel if it exists for a particular view
    var mainText: UILabel? {
        for subview in subviews {
            if subview.tag == UIView.mainTextTag, let textLabel = subview as? UILabel {
                return textLabel
            } else if let textLabel = subview.mainText {
                return textLabel
            }
        }
        return nil
    }

    /// Search for a button based on the tag.
    // This function is useful in cases where the state of a UI control must be modified dependent on the app's state.
    ///
    /// - Parameter tag: the tag ID
    /// - Returns: the UIButton if it exists (nil otherwise)
    func getButtonByTag(tag: Int) -> UIButton? {
        for subview in subviews {
            if subview.tag == tag, let button = subview as? UIButton {
                return button
            }
        }
        return nil
    }
}
