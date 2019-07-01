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
    var lastHapticFeedbackTime = Date()
    
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
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy )
        
        let intendedInterval = TimeInterval(1/(4*exp(-pow(angleFromVertical, 2))))
        print("intendedInterval", intendedInterval)
       // if abs(angleFromVertical) < 0.1 {
            let now = Date()
            let timeInterval = now.timeIntervalSince(lastHapticFeedbackTime)
            print("timeInterval", timeInterval)
            if timeInterval > intendedInterval {
                feedbackGenerator.impactOccurred()
                lastHapticFeedbackTime = now
            }
        //}
        /*else if abs(angleFromVertical) < 0.5 && abs(angleFromVertical) > 0.1 {
                Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) {_ in
                    feedbackGenerator.impactOccurred()
            }
        }*/
        print("angleFromVertical", angleFromVertical)
    }
}
