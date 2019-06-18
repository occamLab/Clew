//
//  UIButtonExtensions.swift
//  Clew
//
//  Created by Dieter Brehm on 6/10/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    
    /// Factory to make an image button.
    ///
    /// Used for start and stop recording and navigation buttons.
    ///
    /// - Parameters:
    ///   - containerView: button container, configured with `UIView.setupButtonContainer(withButton:)`
    ///   - buttonViewParts: holds information about the button (image, label, and target)
    /// - Returns: A formatted button
    ///
    /// - SeeAlso: `UIView.setupButtonContainer(withButton:)`
    ///
    /// - TODO:
    ///   - Implement AutoLayout
    static func makeImageButton(_ containerView: UIView, _ buttonViewParts: ActionButtonComponents) -> UIButton {
        let buttonWidth = containerView.bounds.size.width / 3.75
        
        let button = UIButton(type: .custom)
        button.tag = buttonViewParts.tag
        button.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: buttonWidth)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        switch buttonViewParts.alignment {
        case .center:
            button.center.x = containerView.center.x
        case .right:
            button.center.x = containerView.center.x + UIScreen.main.bounds.size.width/3
        case .rightcenter:
            button.center.x = containerView.center.x + UIScreen.main.bounds.size.width/4.5
        case .left:
            button.center.x = containerView.center.x - UIScreen.main.bounds.size.width/3
        case .leftcenter:
            button.center.x = containerView.center.x - UIScreen.main.bounds.size.width/4.5
        }
        if containerView.mainText != nil {
            button.center.y = containerView.bounds.size.height * (8/10)
        } else {
            button.center.y = containerView.bounds.size.height * (6/10)
        }
        
        switch buttonViewParts.appearance {
        case .imageButton(let image):
            button.setImage(image, for: .normal)
        case .textButton(let label):
            button.setTitle(label, for: .normal)
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.white.cgColor
        }
        
        button.accessibilityLabel = buttonViewParts.label
        button.addTarget(nil, action: buttonViewParts.targetSelector, for: .touchUpInside)
        
        return button
    }
}

/// Holds information about the buttons that are used to control navigation and tracking.
///
/// These button attributes are the only ones unique to each of these buttons.
public struct ActionButtonComponents {
    
    /// The appearance of the button.
    enum Appearance {
        /// An image button appears using the specified UIImage
        case imageButton(image: UIImage)
        /// A text button appears using the specified text label
        case textButton(label: String)
    }
    
    /// How to align the button horizontally within the button frame
    enum ButtonContainerHorizontalAlignment {
        /// put the button in the center
        case center
        /// put the button right of center
        case rightcenter
        /// put the button to the right
        case right
        /// put the button left of center
        case leftcenter
        /// put the button to the left
        case left
    }
    
    /// Button apperance (image or text)
    var appearance: Appearance
    
    /// Accessibility label
    var label: String
    
    /// Function to call when the button is tapped
    ///
    /// - TODO: Potentially unnecessary when the transitioning between views is refactored.
    var targetSelector: Selector
    
    /// The horizontal alignment within the button container
    var alignment: ButtonContainerHorizontalAlignment
    
    /// Tag to use to identify the button if we need to interact with it later.  Pass 0 if no subsequent interaction is required.
    var tag: Int
}
