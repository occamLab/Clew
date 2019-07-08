//
//  TransparentTouchView.swift
//  Clew
//
//  Created by Dieter Brehm on 7/8/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation

class TransparentTouchView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for view in self.subviews {
            if view.isUserInteractionEnabled, view.point(inside: self.convert(point, to: view), with: event) {
                return true
            }
        }
        
        return false
    }
}
