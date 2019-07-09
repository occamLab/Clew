//
//  PhoneOrientationTrainingVC.swift
//  Clew
//
//  Created by Terri Liu on 2019/6/28.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import SceneKit
import SRCountdownTimer


class PhoneOrientationTrainingVC: TutorialChildViewController, SRCountdownTimerDelegate {
//    var rootContainerView: RootContainerView!
//
//    var tutorialViewController: TutorialViewController!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    var lastHapticFeedbackTime = Date()
    var timeLeft = 10
    var countdown:Timer?
    
    @objc func timerCalled() {
        print("timer finished")
        tutorialParent?.state = .optimalOrientationAchieved
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
        
        // condition to pass if state transition was to occur
        if abs(angleFromVertical) < 0.5 {
            if countdown == nil {
                print("angle falls in range")
//                rootContainerView.countdownTimer.isHidden = false
//                rootContainerView.countdownTimer.start(beginingValue: ViewController.alignmentWaitingPeriod, interval: 1)
//                tutorialViewController.viewDidLoad()
                countdown = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(timerCalled), userInfo: nil, repeats: false)
            }
        } else {
            countdown?.invalidate()
        }
        
        if timeInterval > intendedInterval {
            feedbackGenerator.impactOccurred()
            lastHapticFeedbackTime = now
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
