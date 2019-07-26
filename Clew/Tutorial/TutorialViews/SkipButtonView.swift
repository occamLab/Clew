//
//  SkipButtonView.swift
//  Clew
//
//  Created by Terri Liu on 2019/7/26.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import UIKit

/// A class that creates the "skip" buttons in the tutorial
class SkipButton: UIButton {
    var skipButton: UIButton!
    var skipYellow = UIColor(red: 254/255, green: 243/255, blue: 62/255, alpha: 1.0)
    
    func createSkipButton(buttonAction: Selector) -> UIButton {
        skipButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.size.width*3/4 - UIScreen.main.bounds.size.width*1/5, y: UIScreen.main.bounds.size.width*1/14, width: UIScreen.main.bounds.size.width*2/5, height: UIScreen.main.bounds.size.height*1/10))
        skipButton.setTitleColor(skipYellow, for: .normal)
        skipButton.setTitle("SKIP", for: .normal)
        skipButton.layer.masksToBounds = true
        skipButton.layer.cornerRadius = 8.0
        skipButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30.0)
        skipButton.isAccessibilityElement = true
        skipButton.isUserInteractionEnabled = true
        skipButton.addTarget(self, action: buttonAction, for: .touchUpInside)
        return skipButton
    }
}
