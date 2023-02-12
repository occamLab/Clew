//
//  PauseTrackingController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

/// A View Controller for handling the pause route state
/// also handles associated buttons
class PauseTrackingController: UIViewController, UIScrollViewDelegate {

    /// button for storing Anchor Point descriptions
    var enterAnchorPointDescriptionButton: UIButton!
    
    /// button for recording a voice note about a
    /// Anchor Point
    var recordVoiceNoteButton: UIButton!
    
    /// button for aligning phone position in space
    var confirmAlignmentButton: UIButton!
    
    /// text label for the state
    var label: UILabel!
    
    /// paused Boolean that should be set from ViewController in order to display appropriate text
    var paused: Bool!
    
    /// a Boolean that indicates whether the current pause or resume process is for visual alignment
    var isVisualAlignment: Bool!
    
    /// recordingSingleUseRoute Boolean that should be set from ViewController in order to display appropriate text
    var recordingSingleUseRoute: Bool!
    
    /// startAnchorPoint Boolean that should be set from ViewController in order to display appropriate text
    var startAnchorPoint: Bool!
    
    /// called when the view loads (any time)
    override func viewDidAppear(_ animated: Bool) {
        /// update label font
        
        /// label details
        let waitingPeriod = ViewController.alignmentWaitingPeriod
        var mainText: String
        if isVisualAlignment {
            mainText = String.localizedStringWithFormat(NSLocalizedString("visualAnchorPointInstructions", comment: "Information on how to record a visual anchor point."), waitingPeriod)
        } else {
            mainText = String.localizedStringWithFormat(NSLocalizedString("physicalAnchorPointInstructions", comment: "Information on how to record a physical anchor point."), waitingPeriod)
        }
        mainText += "\n\n" + NSLocalizedString("voiceNoteSuggestions", comment: "this text tells the user about the purpose of the voice note and text information buttons.")
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = mainText
        label.tag = UIView.mainTextTag
        
        /// set confirm alignment button as initially active voiceover button
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.enterAnchorPointDescriptionButton)

    }
    
    /// called when the view has loaded the first time.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// create a main view which passes touch events down the hierarchy
        // we subtract one pixel from the height to prevent accessibility elements in the parent view from being hidden (Warning: this is not documented behavior, so we may need to revisit this down the road)
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.size.width,
                                                 height: UIScreen.main.bounds.size.height - 1))
        /// create stack view for aligning and distributing bottom layer buttons
        let stackView   = UIStackView()
        
        /// create a label, and a scrollview for it to live in
        label = UILabel()
        let scrollView = UIScrollView()
        
        /// allow for constraints to be applied to label, scrollview
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.indicatorStyle = .white;
        label.translatesAutoresizingMaskIntoConstraints = false
        
        /// darken background of view
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        /// label details
        let waitingPeriod = ViewController.alignmentWaitingPeriod
        // TODO: not sure why this code is duplicated
        var mainText: String
        if isVisualAlignment {
            mainText = String.localizedStringWithFormat(NSLocalizedString("visualAnchorPointInstructions", comment: "Information on how to record a visual anchor point."), waitingPeriod)
        } else {
            mainText = String.localizedStringWithFormat(NSLocalizedString("physicalAnchorPointInstructions", comment: "Information on how to record a physical anchor point."), waitingPeriod)
        }
        mainText += "\n\n" + NSLocalizedString("voiceNoteSuggestions", comment: "this text tells the user about the purpose of the voice note and text information buttons.")
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = mainText
        label.tag = UIView.mainTextTag
        
        /// place label inside of the scrollview
        scrollView.addSubview(label)
        view.addSubview(scrollView)

        /// set top, left, right constraints on scrollView to
        /// "main" view + 8.0 padding on each side
        scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIScreen.main.bounds.size.height*0.2+30).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8.0).isActive = true
        
        /// set top, left, right AND bottom constraints on label to
        /// scrollView + 8.0 padding on each side
        label.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8.0).isActive = true
        label.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 8.0).isActive = true
        label.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -8.0).isActive = true
        label.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8.0).isActive = true
        
        /// set the width of the label to the width of the scrollView (-16 for 8.0 padding on each side)
        label.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16.0).isActive = true
        
        /// configure label: Zero lines + Word Wrapping
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping

        /// initialize buttons with some basic size constaints
        enterAnchorPointDescriptionButton = UIButton.makeConstraintButton(view,
                                                                  alignment: UIConstants.ButtonContainerHorizontalAlignment.left,
                                                                  appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Describe")!),
                                                                  label: NSLocalizedString("enterAnchorPointDescriptionButtonAccessibilityLabel", comment: "This is the accessibility label for the button which allows the user to save a text based description of their anchor point when saving a route. This feature should allow the user to more easily realign with their anchorpoint."))
        
        recordVoiceNoteButton = UIButton.makeConstraintButton(view,
                                                         alignment: UIConstants.ButtonContainerHorizontalAlignment.right,
                                                         appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "VoiceNote")!),
                                                         label: NSLocalizedString("enterAnchorPointVoiceNoteButtonAccessibilityLabel", comment: "This is the accessibility label for the button which allows the user to save a voice note description of their anchor point when saving a route. This feature should allow the user to more easily realign with their anchorpoint."))
        
        confirmAlignmentButton = UIButton.makeConstraintButton(view,
                                                          alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                          appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Align")!),
                                                          label: NSLocalizedString("startAlignmentCountdownButtonAccessibilityLabel", comment: "this is athe accessibility label for the button which allows the user to start an alignment procedure when saving an anchor point"))
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        
        /// define horizonal, centered, and equal alignment of elements
        /// inside the bottom stack
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        
        /// add elements to the stack
        stackView.addArrangedSubview(confirmAlignmentButton)

        /// create stack view for aligning and distributing bottom layer buttons
        let subStackView   = UIStackView()
        stackView.addArrangedSubview(subStackView)
        subStackView.translatesAutoresizingMaskIntoConstraints = false;
        
        /// define horizonal, centered, and equal alignment of elements
        /// inside the bottom stack
        subStackView.axis = NSLayoutConstraint.Axis.horizontal
        subStackView.distribution  = UIStackView.Distribution.equalSpacing
        subStackView.alignment = UIStackView.Alignment.center
        subStackView.addArrangedSubview(recordVoiceNoteButton)
        subStackView.addArrangedSubview(enterAnchorPointDescriptionButton)
        subStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.yButtonFrameMargin).isActive = true
        subStackView.heightAnchor.constraint(equalTo: stackView.heightAnchor, multiplier: 0.33).isActive = true
        scrollView.flashScrollIndicators()

        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.yButtonFrameMargin).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.yButtonFrameMargin).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIConstants.yOriginOfButtonFrame + UIConstants.yButtonFrameMargin).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.topAnchor, constant: UIConstants.yOriginOfButtonFrame + UIConstants.hierarchyButtonFrameHeight - UIConstants.yButtonFrameMargin).isActive = true
        
        /// set the bottom anchor reltive to the top anchor of stack view
        scrollView.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -10).isActive = true
        
        /// set function targets for the functions in this state
        if let parent: UIViewController = parent {
            enterAnchorPointDescriptionButton.addTarget(parent,
                                     action: #selector(ViewController.showAnchorPointInformationDialog),
                                     for: .touchUpInside)
            recordVoiceNoteButton.addTarget(parent,
                                       action: #selector(ViewController.recordVoiceNote),
                                       for: .touchUpInside)
            confirmAlignmentButton.addTarget(parent,
                                            action: #selector(ViewController.confirmAlignment),
                                            for: .touchUpInside)
        }
    }
}
