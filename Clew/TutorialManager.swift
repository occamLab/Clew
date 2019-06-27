//
//  TutorialManager.swift
//  Clew
//
//  Created by occamlab on 6/24/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import SceneKit

class TutorialManager: ClewObserver {
    func finishAnnouncement(announcement: String) {
    }
    
    func didTransitionTo(newState: AppState) {
        if case .navigatingRoute = newState {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: NSLocalizedString("Let's learn about route navigation!", comment: "Message to user during tutorial"))
            print("howdy!")
        }
    }
    func didReceiveNewCameraPose(transform: simd_float4x4) {
        let angleFromVertical = acos(-transform.columns.0.y)
        if abs(angleFromVertical) < 0.1 {
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light )
            feedbackGenerator.impactOccurred()
        }
        print("angleFromVertical", angleFromVertical)
    }
}
