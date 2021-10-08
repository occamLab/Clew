//
//  StopRecordingController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

/// A View Controller for handling the stop recording state
class StopRecordingController: UIViewController {
    
    /// padding button used to force the stop route button to stay in the middle
    var paddingButton: UIButton!

    /// Button for stopping a route recording
    var stopRecordingButton: UIButton!

    /// button for recording a voice note about a part of the route
    var recordVoiceNoteButton: UIButton!
    
    /// called when the view appears (any time)
    override func viewDidAppear(_ animated: Bool) {
        /// set stopRecordingButton as initially active voiceover button
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.stopRecordingButton)
    }
    
    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPresentationStyle = .fullScreen
        view.frame = CGRect(x: 0,
                            y: UIConstants.yOriginOfButtonFrame,
                            width: UIConstants.buttonFrameWidth,
                            height: UIConstants.buttonFrameHeight)
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        paddingButton = UIButton.makeConstraintButton(view,
                                                      alignment: UIConstants.ButtonContainerHorizontalAlignment.left,
                                                      appearance: UIConstants.ButtonAppearance.textButton(label: ""),
                                                      label: "")
        paddingButton.isAccessibilityElement = false
        paddingButton.alpha = 0

        stopRecordingButton = UIButton.makeConstraintButton(view,
                                                       alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                       appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "StopRecording")!),
                                                       label: NSLocalizedString("stopRecordingButtonAccessibilityLabel", comment: "The accessibility label of the button that allows user to stop recording a route."))
        
        
        recordVoiceNoteButton = UIButton.makeConstraintButton(view,
                                                         alignment: UIConstants.ButtonContainerHorizontalAlignment.right,
                                                         appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "VoiceNote")!),
                                                         label: NSLocalizedString("recordSpatialVoiceNoteAccessibilityLabel", comment: "This is the accessibility label for the button which allows the user to save a voice note to their current location in space."))
        
        /// create stack view for aligning and distributing bottom layer buttons
        let stackView   = UIStackView()
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        
        /// define horizonal, centered, and equal alignment of elements
        /// inside the bottom stack
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        
        /// add elements to the stack
        stackView.addArrangedSubview(paddingButton)
        stackView.addArrangedSubview(stopRecordingButton)
        stackView.addArrangedSubview(recordVoiceNoteButton)

        
        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.yButtonFrameMargin).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.yButtonFrameMargin).isActive = true
        
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIConstants.yButtonFrameMargin).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UIConstants.yButtonFrameMargin).isActive = true

        if let parent: UIViewController = parent {
            stopRecordingButton.addTarget(parent,
                                          action: #selector(ViewController.stopRecording),
                                          for: .touchUpInside)
            recordVoiceNoteButton.addTarget(parent,
                                       action: #selector(ViewController.recordVoiceNote),
                                       for: .touchUpInside)
        }
    }
}
