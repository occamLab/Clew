
//  UIViewExtensions.swift
//  Clew
//
//  Created by Dieter Brehm on 6/10/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import UIKit

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
