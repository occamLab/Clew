//
//  TransparentTouchView.swift
//  Clew
//
//  Created by Dieter Brehm on 7/3/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation

/// class which, when used as a uiview in a view controller, passes all touch events
/// down the view hierarchy. Only applies to specific instances of this class, not to
/// any child subviews. Child subviews still recieve touch events properly.
class TransparentTouchView: UIView {
    
    /// override the function that determines point (input/touch) input as a bool
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for view in self.subviews {
            if view.isUserInteractionEnabled, view.point(inside: self.convert(point, to: view), with: event) {
                return true
            }
        }
        
        return false
    }
}
