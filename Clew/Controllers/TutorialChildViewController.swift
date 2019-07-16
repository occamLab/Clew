//
//  TutorialChildViewController.swift
//  Clew
//
//  Created by Terri Liu on 2019/7/2.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import SceneKit
import UIKit

class TutorialChildViewController: UIViewController, ClewObserver {
    var tutorialParent: TutorialViewController? {
        return parent as? TutorialViewController
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.size.width,
                                                 height: UIScreen.main.bounds.size.height))
    }

    func finishAnnouncement(announcement: String) { }
    func didReceiveNewCameraPose(transform: simd_float4x4)  {}
    func didTransitionTo(newState: AppState) {}
}
