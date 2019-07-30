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
        congratsLabel.backgroundColor = UIColor.white
        congratsLabel.textAlignment = .center
        congratsLabel.numberOfLines = 0
        congratsLabel.lineBreakMode = .byWordWrapping
        congratsLabel.layer.masksToBounds = true
        congratsLabel.layer.cornerRadius = 8.0
        congratsLabel.font = UIFont.systemFont(ofSize: 24.0)
        congratsLabel.layer.borderWidth = 3.0
        congratsLabel.isAccessibilityElement = true
        congratsLabel.accessibilityLabel = congratsAccessibilityLabel
        congratsView.addSubview(congratsLabel)
        
        return congratsView
    }
}
