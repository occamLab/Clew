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

    var lastHapticFeedbackTime = Date()

    /// Timer that is visible to the user on the screen during phone orientation training
    var countdownTimer: SRCountdownTimer!

    /// Timer that is used in conjunction with the 'countdownTimer'. Used to trigger state transition
    var countdown:Timer?

    // View that contains 'congratsLabel' and 'nextButton'
    var congratsView: UIView!

    // Label that congratulates user for completing phone orientation training and provides details on the next part of the tutorial
    var congratsLabel: UILabel!

    // Button for moving to the next state of the tutorial
    var nextButton: UIButton!

    // View for giving a darker tint on the screen
    var backgroundShadow: UIView! = TutorialShadowBackground()

    // Color used in other colors in Clew
    var clewGreen = UIColor(red: 103/255, green: 188/255, blue: 71/255, alpha: 1.0)


    /// Callback function for when `countdownTimer` updates.  This allows us to announce the new value via voice
    /// - Parameter newValue: the new value (in seconds) displayed on the countdown timer
    @objc func timerDidUpdateCounterValue(newValue: Int) {
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String(newValue))
    }

    /// Callback function for when the 'next' button in the congratsView popup is tapped. This changes the state of the TutorialViewController.
    @objc func nextButtonAction(sender: UIButton!) {
        tutorialParent?.state = .readyToRecordSingleRoute
    }

    /// Callback function for when 'countdown' = 0. This triggers a popup to be shown that congratulates the user for completing phone orientation training
    @objc func timerCalled() {
        print("timer finished")
        countdownTimer.isHidden = true
        countdownTimer.removeFromSuperview()
        congratsView = createCongratsView()
        // start VoiceOver at 'congratsLabel'
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: congratsLabel)
        self.view.addSubview(congratsView)
    }

    /// Initializes a view and the button in that view. The view will be shown after the user completes phone orientation training
    func createCongratsView() -> UIView {
        congratsView = UIView(frame:CGRect(x: 0,
                                           y: 0,
                                           width: UIScreen.main.bounds.size.width,
                                           height: UIScreen.main.bounds.size.height))
        congratsLabel = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*2/5, y: UIScreen.main.bounds.size.height/6, width: UIScreen.main.bounds.size.width*4/5, height: 200))
        congratsLabel.text = "Congratulations! \n You have successfully oriented your phone. \n Now you will be recording a simple single route."
        congratsLabel.textColor = UIColor.black
        congratsLabel.backgroundColor = UIColor.white
        congratsLabel.textAlignment = .center
        congratsLabel.numberOfLines = 0
        congratsLabel.lineBreakMode = .byWordWrapping
        congratsLabel.layer.masksToBounds = true
        congratsLabel.layer.cornerRadius = 8.0
        congratsLabel.font = UIFont.systemFont(ofSize: 24.0)
        congratsLabel.layer.borderWidth = 3.0
        congratsLabel.isAccessibilityElement = true
        congratsLabel.accessibilityLabel = "Congratulations! You have successfully oriented your phone. Now you will be recording a simple single route."
        congratsView.addSubview(congratsLabel)

        nextButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*1/5, y: UIScreen.main.bounds.size.width*2/5 + UIScreen.main.bounds.size.height*1/10 + 100, width: UIScreen.main.bounds.size.width*2/5, height: UIScreen.main.bounds.size.height*1/10))
        nextButton.backgroundColor = clewGreen
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.setTitle("Next", for: .normal)
        nextButton.layer.masksToBounds = true
        nextButton.layer.cornerRadius = 10.0
        nextButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30.0)
        nextButton.isAccessibilityElement = true
        nextButton.isUserInteractionEnabled = true
        nextButton.addTarget(self, action: #selector(nextButtonAction), for: .touchUpInside)
        nextButton.layer.borderWidth = 3.0
        congratsView.addSubview(nextButton)

        return congratsView
    }

    /// Called when the view appears on screen.
    /// - Parameter animated: True if the appearance is animated
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        presentedCallout = createCalloutToView(withTagID: 0xFEEDDAD, calloutText: "This button will allow you to record a path. Click it to move on to the next phase of the tutorial!")
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
