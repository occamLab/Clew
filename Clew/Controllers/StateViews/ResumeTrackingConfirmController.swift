//
//  ResumeTrackingConfirmController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

/// A View Controller for aligning and confirming a route navigation resume state
class ResumeTrackingConfirmController: UIViewController, UIScrollViewDelegate {

    /// button for aligning phone
    var confirmAlignmentButton: UIButton!
    
    /// button for recalling a voice note for a route
    var readVoiceNoteButton: UIButton!
    
    /// text label for the state
    var label: UILabel!
    
    /// text for Anchor Point information
    var anchorPointLabel: UILabel!
    
    /// called when the view loads (any time)
    override func viewDidAppear(_ animated: Bool) {
        /// update label font
        /// TODO: is this a safe implementation? Might crash if label has no body, unclear.
        /// called when the view loads (any time)
        label.font = UIFont.preferredFont(forTextStyle: .body)
        anchorPointLabel.font = UIFont.preferredFont(forTextStyle: .body)

        /// set confirm alignment button as initially active voiceover button
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.confirmAlignmentButton)
    }
    
    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // we subtract one pixel from the height to prevent accessibility elements in the parent view from being hidden (Warning: this is not documented behavior, so we may need to revisit this down the road)
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.size.width,
                                                 height: UIScreen.main.bounds.size.height - 1))
        
        label = UILabel()
        anchorPointLabel = UILabel()
        let scrollView = UIScrollView()
        
        /// allow for constraints to be applied to label, scrollview
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.indicatorStyle = .white;
        label.translatesAutoresizingMaskIntoConstraints = false
        anchorPointLabel.translatesAutoresizingMaskIntoConstraints = false
        
        /// darken background of view
        view.backgroundColor = UIColor.black.withAlphaComponent(UIConstants.alpha)
        
        /// label details
        let waitingPeriod = ViewController.alignmentWaitingPeriod
        let alignInfo = String.localizedStringWithFormat(NSLocalizedString("anchorPointAlignmentText", comment: "Text describing the process of aligning to an anchorpoint. This text shows up on the alignment screen."), waitingPeriod)

        let mainText = alignInfo
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = mainText
        label.tag = UIView.mainTextTag
        
        anchorPointLabel.textColor = UIColor.white
        anchorPointLabel.textAlignment = .center
        anchorPointLabel.numberOfLines = 0
        anchorPointLabel.lineBreakMode = .byWordWrapping
        anchorPointLabel.font = UIFont.preferredFont(forTextStyle: .body)
        
        /// place label inside of the scrollview
        scrollView.addSubview(anchorPointLabel)
        scrollView.addSubview(label)
        view.addSubview(scrollView)
        
        /// set top, left, right constraints on scrollView to
        /// "main" view + 8.0 padding on each side
        scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIScreen.main.bounds.size.height*0.15).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8.0).isActive = true
        
        /// set the height constraint on the scrollView to 0.5 * the main view height
        scrollView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5).isActive = true
        
        /// constraints for anchorPointLabel
        anchorPointLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8.0).isActive = true
        anchorPointLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 8.0).isActive = true
        anchorPointLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -8.0).isActive = true

        /// set top, left, right AND bottom constraints on label to
        /// scrollView + 8.0 padding on each side
        label.topAnchor.constraint(equalTo: anchorPointLabel.bottomAnchor, constant: 8.0).isActive = true
        label.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 8.0).isActive = true
        label.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -8.0).isActive = true
        label.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8.0).isActive = true
        
        /// set the width of the label to the width of the scrollView (-16 for 8.0 padding on each side)
        label.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16.0).isActive = true
        
        /// constraints for anchorPointLabel
        
        /// configure label: Zero lines + Word Wrapping
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        anchorPointLabel.numberOfLines = 0
        anchorPointLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        // MARK: ReadVoiceNoteButton
        /// The button that plays back the recorded voice note associated with a Anchor Point
        readVoiceNoteButton = UIButton.makeConstraintButton(view,
                                                       alignment: UIConstants.ButtonContainerHorizontalAlignment.left,
                                                       appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Read")!),
                                                       label: NSLocalizedString("playVoiceNoteButtonAccessibilityLabel", comment: "This is the accessibility label for the button which allows the user to replay their recorded voice note when loading an anchor point."))
        
        // MARK: ConfirmAlignmentButton
        confirmAlignmentButton = UIButton.makeConstraintButton(view,
                                                               alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                               appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Align")!),
                                                               label: NSLocalizedString("startAlignmentCountdownButtonAccessibilityLabel", comment: "this is athe accessibility label for the button which allows the user to start an alignment procedure when saving an anchor point"))
        
        /// create stack view for aligning and distributing bottom layer buttons
        let stackView   = UIStackView()
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        /// define horizonal, centered, and equal alignment of elements
        /// inside the bottom stack
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        
        /// add elements to the stack
        stackView.addArrangedSubview(readVoiceNoteButton)
        stackView.addArrangedSubview(confirmAlignmentButton)
        
        scrollView.flashScrollIndicators()
        
        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8.0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UIConstants.buttonFrameWidth/7 * 2).isActive = true

        if let parent: UIViewController = parent {
            readVoiceNoteButton.addTarget(parent,
                                   action: #selector(ViewController.readVoiceNote),
                                   for: .touchUpInside)
            confirmAlignmentButton.addTarget(parent,
                                          action: #selector(ViewController.confirmAlignment),
                                          for: .touchUpInside)
        }
    }
}
