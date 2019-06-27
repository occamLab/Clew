//
//  PauseTrackingController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

class TransparentTouchView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for view in self.subviews {
            if view.isUserInteractionEnabled, view.point(inside: self.convert(point, to: view), with: event) {
                return true
            }
        }
        
        return false
    }
}

/// A View Controller for handling the pause route state
/// also handles associated buttons
class PauseTrackingController: UIViewController, UIScrollViewDelegate {

    /// button for storing landmark descriptions
    var enterLandmarkDescriptionButton: UIButton!
    
    /// button for recording a voice note about a
    /// landmark
    var recordVoiceNoteButton: UIButton!
    
    /// button for aligning phone position in space
    var confirmAlignmentButton: UIButton!
    
    var label: UILabel!
    
    override func viewDidAppear(_ animated: Bool) {
        label.font = UIFont.preferredFont(forTextStyle: .body)
    }
    
    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// create a main view which passes touch events down the hierarchy
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.size.width,
                                                 height: UIScreen.main.bounds.size.height))
        
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
        let mainText = String.localizedStringWithFormat(NSLocalizedString("Landmarks allow you to save or pause your route. You will need to return to the landmark to load or unpause your route. Before creating the landmark, specify text or voice to help you remember its location. To create a landmark, hold your device flat with the screen facing up. Press the top (short) edge flush against a flat vertical surface (such as a wall).  The \"align\" button starts a %lu-second countdown. During this time, do not move the device.", comment: "Info for user"), waitingPeriod)
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
        scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100.0).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8.0).isActive = true
        
        /// set the height constraint on the scrollView to 0.5 * the main view height
        scrollView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5).isActive = true
        
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
        enterLandmarkDescriptionButton = UIButton.makeConstraintButton(view,
                                                                  alignment: UIConstants.ButtonContainerHorizontalAlignment.left,
                                                                  appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Describe")!),
                                                                  label: "Enter text to help you remember this landmark")
        
        recordVoiceNoteButton = UIButton.makeConstraintButton(view,
                                                         alignment: UIConstants.ButtonContainerHorizontalAlignment.right,
                                                         appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "VoiceNote")!),
                                                         label: "Record audio to help you remember this landmark")
        
        confirmAlignmentButton = UIButton.makeConstraintButton(view,
                                                          alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                          appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Align")!),
                                                          label: "Start \(ViewController.alignmentWaitingPeriod)-second alignment countdown")
        
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
        stackView.addArrangedSubview(enterLandmarkDescriptionButton)
        stackView.addArrangedSubview(confirmAlignmentButton)
        stackView.addArrangedSubview(recordVoiceNoteButton)
        
        scrollView.flashScrollIndicators()

        /// size the stack
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 450.0).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8.0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UIConstants.buttonFrameWidth/7 * 2).isActive = true
        
        /// set function targets for the functions in this state
        if let parent: UIViewController = parent {
            enterLandmarkDescriptionButton.addTarget(parent,
                                     action: #selector(ViewController.showLandmarkInformationDialog),
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
