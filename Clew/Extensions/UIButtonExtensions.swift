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
    func addLargeTitle(_ title: String) {
        setTitle(title, for: .normal)
        setTitleColor(.black, for: .normal)
        titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 35)!
        titleLabel?.textAlignment = .center
        titleLabel?.numberOfLines = 0
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        titleEdgeInsets.top = 0
        titleEdgeInsets.left = 5
        titleEdgeInsets.bottom = 0
        titleEdgeInsets.right = 5
    }
    
    static func makeConstraintButton(_ containerView: UIView,
                                      alignment: UIConstants.ButtonContainerHorizontalAlignment,
                                      appearance: UIConstants.ButtonAppearance,
                                      label:String) -> UIButton {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        
        /// enable use of constaint layout system
        button.translatesAutoresizingMaskIntoConstraints = false
        let maxImageHeight = UIConstants.buttonFrameHeight - 2*UIConstants.yButtonFrameMargin
        let maxImageWidth = (UIConstants.buttonFrameWidth - CGFloat(UIConstants.numButtonsInContainer + 1)*UIConstants.yButtonFrameMargin)/CGFloat(UIConstants.numButtonsInContainer)
        
        /// set width of button and constraint height to be equal to width
        button.widthAnchor.constraint(equalToConstant: min(maxImageHeight, maxImageWidth)).isActive = true
        button.heightAnchor.constraint(equalToConstant: min(maxImageHeight, maxImageWidth)).isActive = true

        /// apply appearance, either an image or a text field
        switch appearance {
        case .imageButton(let image):
            button.setImage(image, for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.contentVerticalAlignment = .fill
            button.contentHorizontalAlignment = .fill
        case .textButton(let label):
            button.setTitle(label, for: .normal)
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.white.cgColor
        }
        
        button.accessibilityLabel = label
        
        return button
    }
    
}






