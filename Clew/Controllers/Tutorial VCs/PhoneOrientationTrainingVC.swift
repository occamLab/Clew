//
//  PhoneOrientationTrainingVC.swift
//  Clew
//
//  Created by Terri Liu on 2019/6/28.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import SceneKit


class PhoneOrientationTrainingVC: TutorialChildViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    var lastHapticFeedbackTime = Date()
    var timeLeft = 10
    var countdown:Timer? = nil {
        willSet{
            countdown?.invalidate()
        }
    }
    
    @objc func timerCalled() {
        print("timeLeft", timeLeft)
        if timeLeft != 0 {
            timeLeft -= 1
        } else {
            print("stop")
            countdown = nil
        }
    }
    
    override func didReceiveNewCameraPose(transform: simd_float4x4) {
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: NSLocalizedString("Trying to figure out haptic feedback", comment: "Message to user during tutorial"))
        
        let angleFromVertical = acos(-transform.columns.0.y)
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        
        let intendedInterval = TimeInterval(1/(4*exp(-pow(angleFromVertical, 2))))
        print("intendedInterval", intendedInterval)
        
        // if abs(angleFromVertical) < 0.1 {
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastHapticFeedbackTime)
        print("timeInterval", timeInterval)
        print("angleFromVertical", angleFromVertical)
        
        if timeInterval > intendedInterval {
            // condition to pass if state transition was to occur
            if angleFromVertical < 0.5 {
                print("angle falls in range")
                countdown = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerCalled), userInfo: nil, repeats: true)
                if countdown == nil {
                    print("timer finished")
                    tutorialParent?.state = .optimalOrientationAchieved
                }
                
            feedbackGenerator.impactOccurred()
            lastHapticFeedbackTime = now
            }
        }
        
         /* if abs(angleFromVertical) < 0.1 {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) {_ in
            feedbackGenerator.impactOccurred()
            self.tutorialParent?.state = .optimalOrientationAchieved
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: NSLocalizedString("Great job.  you have the phone positioned properly!", comment: "Message to user during tutorial"))

         }
         if abs(angleFromVertical) < 0.5 && abs(angleFromVertical) > 0.1 {
         Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) {_ in
         feedbackGenerator.impactOccurred()
         }
         }
         print("angleFromVertical", angleFromVertical) */
    }
}
