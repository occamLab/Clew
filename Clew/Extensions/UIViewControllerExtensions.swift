//
//  UIViewControllerExtensions.swift
//  Clew
//
//  Created by Dieter Brehm on 6/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//
// Extensions for UIViewController base class
// - add: add a new child vc to the current vc (nesting can occur)
// - remove: remove a child vc from the current vc (nesting can occur)
// see: https://www.swiftbysundell.com/basics/child-view-controllers

import Foundation
import UIKit

extension UIViewController {
    /// call on a parent VC with desired child as param
    func add(_ child: UIViewController) {
        /// add the child to the parent
        addChild(child)
        /// add the view of the child to the view of the parent
        view.addSubview(child.view)
        /// notify the child that it was moved to a parent
        child.didMove(toParent: self)
    }
    
    /// call on a child VC
    func remove() {
        // Just to be safe, we check that this view controller
        // is actually added to a parent before removing it.
        guard parent != nil else {
            return
        }
        /// notify the child that it’s about to be removed
        willMove(toParent: nil)
        /// remove the child’s view from the parent’s
        view.removeFromSuperview()
        /// remove the child from its parent
        removeFromParent()
    }
}
