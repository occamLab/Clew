//
//  CongratsView.swift
//  Clew
//
//  Created by Terri Liu on 2019/7/30.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import UIKit

/// Initializes a congratulations view and the button in that view. The view will be shown after the user completes phone orientation training

class CongratsView: UIView {
    var congratsView: UIView!
    var clewGreen = UIColor(red: 103/255, green: 188/255, blue: 71/255, alpha: 1.0)
    var congratsLabel: UILabel!
    
    func createCongratsView(congratsText: String, congratsAccessibilityLabel: String) -> UIView {
        congratsView = UIView(frame:CGRect(x: 0,
                                           y: 0,
                                           width: UIScreen.main.bounds.size.width,
                                           height: UIScreen.main.bounds.size.height))
        congratsView.backgroundColor = clewGreen
        congratsLabel = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*2/5, y: UIScreen.main.bounds.size.height/8, width: UIScreen.main.bounds.size.width*4/5, height: 200))
        congratsLabel.text = congratsText
        congratsLabel.textColor = UIColor.black
        congratsLabel.textAlignment = .center
        congratsLabel.numberOfLines = 0
        congratsLabel.lineBreakMode = .byWordWrapping
        congratsLabel.layer.masksToBounds = true
        congratsLabel.layer.cornerRadius = 8.0
        /// update label font
        /// TODO: is this a safe implementation? Might crash if label has no body, unclear.
        congratsLabel.font = UIFont.preferredFont(forTextStyle: .body)
        congratsLabel.isAccessibilityElement = true
        congratsLabel.accessibilityLabel = congratsAccessibilityLabel
    
        let scrollView = UIScrollView()
        
        /// allow for constraints to be applied to label, scrollview
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.indicatorStyle = .white
        scrollView.layer.borderColor = UIColor.black.cgColor
        scrollView.layer.borderWidth = 3.0
        scrollView.layer.cornerRadius = 9.0
        scrollView.backgroundColor = UIColor.white
        
        congratsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        /// place label inside of the scrollview
        scrollView.addSubview(congratsLabel)
        congratsView.addSubview(scrollView)
        
        /// set top, left, right constraints on scrollView to
        /// "main" view + 8.0 padding on each side
        scrollView.leftAnchor.constraint(equalTo: congratsView.leftAnchor, constant: 50).isActive = true
        scrollView.topAnchor.constraint(equalTo: congratsView.topAnchor, constant: 70).isActive = true
        scrollView.rightAnchor.constraint(equalTo: congratsView.rightAnchor, constant: -50).isActive = true
        /// set the height constraint on the scrollView to 0.5 * the main view height
        scrollView.heightAnchor.constraint(equalTo: congratsView.heightAnchor, multiplier: 0.3).isActive = true
        
        scrollView.flashScrollIndicators()
        
        /// configure label: Zero lines + Word Wrapping
        congratsLabel.numberOfLines = 0
        congratsLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        
        /// set top, left, right AND bottom constraints on label to
        /// scrollView + 8.0 padding on each side
        congratsLabel.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 8).isActive = true
        congratsLabel.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -8).isActive = true
        congratsLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8).isActive = true
        congratsLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8).isActive = true
        
        /// set the width of the label to the width of the scrollView (-16 for 8.0 padding on each side)
        /// center buttonLabel among scrollView so that it is centered vertically and horizontally
        congratsLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16).isActive = true
        congratsLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        congratsLabel.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
        
        return congratsView
    }
}
