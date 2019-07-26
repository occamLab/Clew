//
//  NextButtonView.swift
//  Clew
//
//  Created by Terri Liu on 2019/7/26.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import UIKit

/// A class that creates the "next" buttons in the tutorial
class NextButton: UIButton {
    var nextButton: UIButton!
    var clewGreen = UIColor(red: 103/255, green: 188/255, blue: 71/255, alpha: 1.0)
    
    func createNextButton(buttonAction: Selector) -> UIButton {
        nextButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*1/5, y: UIScreen.main.bounds.size.width*3/10 + UIScreen.main.bounds.size.height*1/10 + 100, width: UIScreen.main.bounds.size.width*2/5, height: UIScreen.main.bounds.size.height*1/10))
        nextButton.backgroundColor = clewGreen
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.setTitle("Next", for: .normal)
        nextButton.layer.masksToBounds = true
        nextButton.layer.cornerRadius = 10.0
        nextButton.layer.borderWidth = 3.0
        nextButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30.0)
        nextButton.isAccessibilityElement = true
        nextButton.isUserInteractionEnabled = true
        nextButton.addTarget(self, action: buttonAction, for: .touchUpInside)
        return nextButton
    }
}


