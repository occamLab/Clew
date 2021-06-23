//
//  PauseTrackingController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit
import SceneKit // EEA

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
    
    /// recordingSingleUseRoute Boolean that should be set from ViewController in order to display appropriate text
    var recordingSingleUseRoute: Bool!
    
    /// startAnchorPoint Boolean that should be set from ViewController in order to display appropriate text
    var startAnchorPoint: Bool!
    
    /// called when the view loads (any time)
    override func viewDidAppear(_ animated: Bool) {
        /// update label font
        
        /// label details
        let waitingPeriod = ViewController.alignmentWaitingPeriod
        var mainText : String
        
        if paused  && recordingSingleUseRoute {
            mainText = String.localizedStringWithFormat(NSLocalizedString("singleUseRouteAnchorPointText", comment: "Information on how to record an anchor point when used for pausing a single use route"), waitingPeriod)
        } else {
            if startAnchorPoint{
                mainText = String.localizedStringWithFormat(NSLocalizedString("multipleUseRouteStartAnchorPointText", comment: "Information on how to record an anchor point when used recording the starting anchor point of a multiple use route."), waitingPeriod)
                
            } else {
                mainText = String.localizedStringWithFormat(NSLocalizedString("multipleUseRouteEndAnchorPointText", comment: "Information on how to record an anchor point when used recording the ending anchor point of a multiple use route."), waitingPeriod)
            }
            
        }
        
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
        var mainText:String
        
        if paused && recordingSingleUseRoute {
            mainText = String.localizedStringWithFormat(NSLocalizedString("singleUseRouteAnchorPointText", comment: "Information on how to record an anchor point when used for pausing a single use route"), waitingPeriod)
        } else {
            if startAnchorPoint {
                mainText = String.localizedStringWithFormat(NSLocalizedString("multipleUseRouteStartAnchorPointText", comment: "Information on how to record an anchor point when used recording the starting anchor point of a multiple use route."), waitingPeriod)
            } else {
                mainText = String.localizedStringWithFormat(NSLocalizedString("multipleUseRouteEndAnchorPointText", comment: "Information on how to record an anchor point when used recording the ending anchor point of a multiple use route."), waitingPeriod)
            }
            
        }
        
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
        scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIScreen.main.bounds.size.height*0.15).isActive = true
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
        stackView.addArrangedSubview(enterAnchorPointDescriptionButton)
        stackView.addArrangedSubview(recordVoiceNoteButton)
        stackView.addArrangedSubview(confirmAlignmentButton)
        
        scrollView.flashScrollIndicators()

        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8.0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UIConstants.buttonFrameWidth/7 * 2).isActive = true
        
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
