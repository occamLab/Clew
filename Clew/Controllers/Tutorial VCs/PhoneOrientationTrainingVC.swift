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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    /// Callback function for when `countdownTimer` updates.  This allows us to announce the new value via voice
    ///
    /// - Parameter newValue: the new value (in seconds) displayed on the countdown timer
    @objc func timerDidUpdateCounterValue(newValue: Int) {
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String(newValue))
    }

    
    var lastHapticFeedbackTime = Date()
    var countdownTimer: SRCountdownTimer!
    var countdown:Timer?
    
    
    @objc func timerCalled() {
        print("timer finished")
        tutorialParent?.state = .optimalOrientationAchieved
        countdownTimer.isHidden = true
    }
    
    override func viewDidLoad() {
        countdownTimer = SRCountdownTimer(frame: CGRect(x: UIConstants.buttonFrameWidth*1/10,
                                                        y: UIConstants.yOriginOfButtonFrame/10,
                                                        width: UIConstants.buttonFrameWidth*8/10,
                                                        height: UIConstants.buttonFrameWidth*8/10))
        countdownTimer.labelFont = UIFont(name: "HelveticaNeue-Light", size: 100)
        countdownTimer.labelTextColor = UIColor.white
        countdownTimer.timerFinishingText = "End"
        countdownTimer.lineWidth = 10
        countdownTimer.lineColor = UIColor.white
        countdownTimer.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        countdownTimer.isHidden = true
        countdownTimer.delegate = self
        countdownTimer.accessibilityElementsHidden = true
        view.addSubview(countdownTimer)
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
                countdownTimer.isHidden = false
                countdownTimer.start(beginingValue: 3, interval: 1)
                
                countdown = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(timerCalled), userInfo: nil, repeats: false) }
        } else {
            countdownTimer.isHidden = true
            countdown?.invalidate()
        }
        
        if timeInterval > intendedInterval {
            feedbackGenerator.impactOccurred()
            lastHapticFeedbackTime = now
        }
    }
}
