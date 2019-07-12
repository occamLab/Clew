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
    /// Called when the view appears on screen.
    ///
    /// - Parameter animated: True if the appearance is animated
    
    var backgroundShadow: UIView! = TutorialShadowBackground()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @objc func buttonAction(sender: UIButton!) {
         tutorialParent?.state = .readyToRecordSingleRoute
    }
    
    
    /// Callback function for when `countdownTimer` updates.  This allows us to announce the new value via voice
    ///
    /// - Parameter newValue: the new value (in seconds) displayed on the countdown timer
    @objc func timerDidUpdateCounterValue(newValue: Int) {
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String(newValue))
    }

    
    var lastHapticFeedbackTime = Date()
    
    /// Circle timer that is visible to the user on the screen
    var countdownTimer: SRCountdownTimer!
    
    /// Timer that is used in conjunction with the 'countdownTimer'. Used to trigger state transition
    var countdown:Timer?
    
    /// Callback function for when 'countdown' = 0. This triggers the transition to the next state of the tutorial
    @objc func timerCalled() {
        print("timer finished")
        tutorialParent?.state = .optimalOrientationAchieved
        countdownTimer.isHidden = true
    }
    
    /// Called when the view has loaded. Make new countdownTimer that will only be used in PhoneorientationTrainingVC
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
        view.addSubview(backgroundShadow)
        view.addSubview(countdownTimer)
    }
    
    /// Send haptic feedback with different frequencies depending on the angle of the phone. Handle transition to the next state when the angle of the phone falls in the range of optimal angle. As the user orients the phone closer to the desired range of the angle, haptic feedback becomes faster. When optimal angle is achieved for a desired amount of time, state transition takes place.
    ///
    /// - Parameter transform: the position and orientation of the phone
    override func didReceiveNewCameraPose(transform: simd_float4x4) {
        // UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: NSLocalizedString("Trying to figure out haptic feedback", comment: "Message to user during tutorial"))
        
        let angleFromVertical = acos(-transform.columns.0.y)
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        let intendedInterval = TimeInterval(1/(4*exp(-pow(angleFromVertical, 2))))
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastHapticFeedbackTime)
        
        // handles when the angle the user is holding the phone falls in between the desired optimal angle
        if abs(angleFromVertical) < 0.5 {
            if countdown == nil {
                print("angle falls in range")
                countdownTimer.isHidden = false
                /// NOTE: to change the time that the user needs to hold the phone in the optimal angle for state transition to happen, change both the 'beginingValue' and 'timeInterval'
                countdownTimer.start(beginingValue: 3, interval: 1)
                countdown = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(timerCalled), userInfo: nil, repeats: false) }
        } else {
            countdownTimer.isHidden = true
            countdown?.invalidate()
            countdown = nil
        }
        
        /// send haptic feedback in varying frequency depending on how accurate the angle the user is holding up their phone
        if timeInterval > intendedInterval {
            feedbackGenerator.impactOccurred()
            lastHapticFeedbackTime = now
        }
    }
}
