//
//  TutorialShadowBackground.swift
//  Clew
//
//  Created by Terri Liu on 2019/7/11.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import UIKit

/// A view that adds a shadow to the background for the tutorial
class TutorialShadowBackground: UIView {
    
    /// required for non storyboard UIView
    /// objects
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented.")
    }
    
    /// initializer for view, initializes all subview objects
    /// like buttons
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.frame = CGRect(x: 0,
                            y: 0,
                            width: UIScreen.main.bounds.width,
                            height: UIScreen.main.bounds.height)
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    }
}
