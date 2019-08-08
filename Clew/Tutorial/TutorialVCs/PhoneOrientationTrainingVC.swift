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
import FLAnimatedImage

class PhoneOrientationTrainingVC: TutorialChildViewController, SRCountdownTimerDelegate {

    var lastHapticFeedbackTime = Date()

    /// Timer that is visible to the user on the screen during phone orientation training
    var countdownTimer: SRCountdownTimer!

    /// Timer that is used in conjunction with the 'countdownTimer'. Used to trigger state transition
    var countdown:Timer?

    // View that contains 'congratsLabel' and 'nextButton'
    var phoneOrientationTrainingCongratsView: UIView!

    // Label that congratulates user for completing phone orientation training and provides details on the next part of the tutorial
    var congratsLabel: UILabel!

    // Button for moving to the next state of the tutorial
    var nextButton: UIButton!
    
    let gifView = FLAnimatedImageView()
    
    // View for giving a darker tint on the screen
    var backgroundShadow: UIView! = TutorialShadowBackground()
    
    // Used to control enabling/disabling haptic feedback
    var runHapticFeedback : Bool? = true
    
    // Color used in other colors in Clew
    var clewGreen = UIColor(red: 103/255, green: 188/255, blue: 71/255, alpha: 1.0)
    var clewLightGreen = UIColor(red: 198/255, green: 225/255, blue: 167/255, alpha: 1.0)
    var clewYellow = UIColor(red: 254/255, green: 243/255, blue: 62/255, alpha: 1.0)
    
    
    /// Callback function for when `countdownTimer` updates.  This allows us to announce the new value via voice
    /// - Parameter newValue: the new value (in seconds) displayed on the countdown timer
    @objc func timerDidUpdateCounterValue(newValue: Int) {
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String(newValue))
    }

    
    /// Callback function for when the 'next' button in the congratsView popup is tapped. This changes the state of the TutorialViewController.
    @objc func nextButtonAction(sender: UIButton!) {
        
        // remove all subviews after the end of phone orientation training tutorial portion
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
        
        tutorialParent?.state = .readyToRecordSingleRoute
    }

    
    /// Callback function for when 'countdown' = 0. This stops haptic feedback and triggers a popup to be shown that congratulates the user for completing phone orientation training.
    @objc func timerCalled() {
        runHapticFeedback = false
        countdownTimer.removeFromSuperview()
        
        // create congrats view
        // TODO: disable countdown timer when the CongratsView shows up (with VoiceOver the timer is running in the background)
        phoneOrientationTrainingCongratsView = CongratsView().createCongratsView(congratsText: NSLocalizedString("Congratulations! \n You have successfully oriented your phone. \n Now you will be recording a simple single route.", comment: "Congratulations! \n You have successfully oriented your phone. \n Now you will be recording a simple single route."), congratsAccessibilityLabel: NSLocalizedString("Congratulations! You have successfully oriented your phone. Now you will be recording a simple single route.", comment: "Congratulations! You have successfully oriented your phone. Now you will be recording a simple single route."))
        nextButton = NextButton().createNextButton(buttonAction: #selector(nextButtonAction))
        nextButton.backgroundColor = UIColor.white
        nextButton.setTitleColor(clewGreen, for: .normal)
        phoneOrientationTrainingCongratsView.addSubview(nextButton)
        self.view.addSubview(phoneOrientationTrainingCongratsView)
        
        // start VoiceOver at 'congratsLabel'
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: congratsLabel)
    }
    
    
    /// Called when the view appears on screen. Initializes and starts 'timeSinceOpen'.
    /// - Parameter animated: True if the appearance is animated
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.post(name: Notification.Name("HideMainScreenAccessibilityElements"), object: nil)
        
        countdownTimer = SRCountdownTimer(frame: CGRect(x: UIConstants.buttonFrameWidth*1/10,
                                                        y: UIConstants.yOriginOfButtonFrame/10,
                                                        width: UIConstants.buttonFrameWidth*8/10,
                                                        height: UIConstants.buttonFrameWidth*8/10))
        countdownTimer.labelFont = UIFont(name: "HelveticaNeue-Light", size: 100)
        countdownTimer.labelTextColor = UIColor.white
        countdownTimer.timerFinishingText = NSLocalizedString("End", comment: "End")
        countdownTimer.lineWidth = 10
        countdownTimer.lineColor = UIColor.white
        countdownTimer.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        countdownTimer.isHidden = true
        countdownTimer.delegate = self
        countdownTimer.accessibilityElementsHidden = true
        self.view.addSubview(backgroundShadow)
        self.view.addSubview(countdownTimer)
    }


    /// Called when the view has loaded. Make new countdownTimer that will only be used in PhoneorientationTrainingVC
    override func viewDidLoad() {
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name("UnhideMainScreenAccessibilityElements"), object: nil)
    }
    
    /// Send haptic feedback with different frequencies depending on the angle of the phone. Handle transition to the next state when the angle of the phone falls in the range of optimal angle. As the user orients the phone closer to the desired range of the angle, haptic feedback becomes faster. When optimal angle is achieved for a desired amount of time, state transition takes place.
    /// - Parameter transform: the position and orientation of the phone
    override func didReceiveNewCameraPose(transform: simd_float4x4) {

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
        if runHapticFeedback! {
            if timeInterval > intendedInterval {
                feedbackGenerator.impactOccurred()
                lastHapticFeedbackTime = now
            }
        }
    }
}
