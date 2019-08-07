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
    
    /// called when the view loads (any time)
    override func viewDidAppear(_ animated: Bool) {
        /// update label font
        
        /// label details
        let waitingPeriod = ViewController.alignmentWaitingPeriod
        var mainText:String = "nil"
        
        if (paused == true && recordingSingleUseRoute == true){
            mainText = String.localizedStringWithFormat(NSLocalizedString("To be able to resume your tracking at a later point you need to record an anchor point for the end of your route. An anchor point records the position and alignment of your device so the app can reload your route from a temporary file. As a result the accuracy of your return navigation relies entirely on how accurately you can realign and position your phone with your saved anchor point at a later point. We suggest using the text and voice note buttons to record a text note and/or a voice recording which can help you realign your device to the anchor point you recorded at a later time.\nTo create an anchor point, hold your device flat with the screen facing up. Press the top (short) edge flush against a flat vertical surface (such as a wall) the ”align” button starts a %lu-second countdown. The countdown is intended to give you time to position your device; the Anchor point will be saved at the end of the countdown.", comment: "Info for user"), waitingPeriod)
        } else {
            if startAnchorPoint{
                mainText = String.localizedStringWithFormat(NSLocalizedString("To allow your route to be navigated at a later point you need to record an anchor point for the start of your route. An anchor point records the position and alignment of your device so the app can reload your route from a saved file. As a result the accuracy of your saved route navigation relies entirely on how accurately you can realign and position your phone with your saved anchor point at a later point. We suggest using the text and voice note buttons to record a text note and/or a voice recording which can help you realign your device to the anchor point you recorded at a later time.\nTo create an anchor point, hold your device flat with the screen facing up. Press the top (short) edge flush against a flat vertical surface (such as a wall) the ”align” button starts a %lu-second countdown. The countdown is intended to give you time to position your device; the Anchor point will be saved at the end of the countdown.", comment: "Info for user"), waitingPeriod)
            } else {
                mainText = String.localizedStringWithFormat(NSLocalizedString("To allow your route to be navigated in the reverse direction you need to record an anchor point for the end of your route. An anchor point records the position and alignment of your device so the app can reload your route from a saved file. As a result the accuracy of your saved route navigation relies entirely on how accurately you can realign and position your phone with your saved anchor point at a later point. We suggest using the text and voice note buttons to record a text note and/or a voice recording which can help you realign your device to the anchor point you recorded at a later time.\nTo create an anchor point, hold your device flat with the screen facing up. Press the top (short) edge flush against a flat vertical surface (such as a wall) the ”align” button starts a %lu-second countdown. The countdown is intended to give you time to position your device; the Anchor point will be saved at the end of the countdown.", comment: "Info for user"), waitingPeriod)
            }
            
        }
        
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = mainText
        label.tag = UIView.mainTextTag
        label.font = UIFont.preferredFont(forTextStyle: .body)
        
        /// set confirm alignment button as initially active voiceover button
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.confirmAlignmentButton)

    }
    
    /// called when the view has loaded the first time.  We setup various app elements in here.
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
        var mainText:String = "nil"
        
        if (paused == true && recordingSingleUseRoute == true){
            mainText = String.localizedStringWithFormat(NSLocalizedString("To be able to resume your tracking at a later point you need to record an anchor point for the end of your route. An anchor point records the position and alignment of your device so the app can reload your route from a temporary file. As a result the accuracy of your return navigation relies entirely on how accurately you can realign and position your phone with your saved anchor point at a later point. We suggest using the text and voice note buttons to record a text note and/or a voice recording which can help you realign your device to the anchor point you recorded at a later time.\nTo create an anchor point, hold your device flat with the screen facing up. Press the top (short) edge flush against a flat vertical surface (such as a wall) the ”align” button starts a %lu-second countdown. The countdown is intended to give you time to position your device; the Anchor point will be saved at the end of the countdown.", comment: "Info for user"), waitingPeriod)
        } else {
            if startAnchorPoint{
                mainText = String.localizedStringWithFormat(NSLocalizedString("To allow your route to be navigated at a later point you need to record an anchor point for the start of your route. An anchor point records the position and alignment of your device so the app can reload your route from a saved file. As a result the accuracy of your saved route navigation relies entirely on how accurately you can realign and position your phone with your saved anchor point at a later point. We suggest using the text and voice note buttons to record a text note and/or a voice recording which can help you realign your device to the anchor point you recorded at a later time.\nTo create an anchor point, hold your device flat with the screen facing up. Press the top (short) edge flush against a flat vertical surface (such as a wall) the ”align” button starts a %lu-second countdown. The countdown is intended to give you time to position your device; the Anchor point will be saved at the end of the countdown.", comment: "Info for user"), waitingPeriod)
            } else {
                mainText = String.localizedStringWithFormat(NSLocalizedString("To allow your route to be navigated in the reverse direction you need to record an anchor point for the end of your route. An anchor point records the position and alignment of your device so the app can reload your route from a saved file. As a result the accuracy of your saved route navigation relies entirely on how accurately you can realign and position your phone with your saved anchor point at a later point. We suggest using the text and voice note buttons to record a text note and/or a voice recording which can help you realign your device to the anchor point you recorded at a later time.\nTo create an anchor point, hold your device flat with the screen facing up. Press the top (short) edge flush against a flat vertical surface (such as a wall) the ”align” button starts a %lu-second countdown. The countdown is intended to give you time to position your device; the Anchor point will be saved at the end of the countdown.", comment: "Info for user"), waitingPeriod)
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
        enterAnchorPointDescriptionButton = UIButton.makeConstraintButton(view,
                                                                  alignment: UIConstants.ButtonContainerHorizontalAlignment.left,
                                                                  appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Describe")!),
                                                                  label: "Enter text to help you remember this Anchor Point")
        
        recordVoiceNoteButton = UIButton.makeConstraintButton(view,
                                                         alignment: UIConstants.ButtonContainerHorizontalAlignment.right,
                                                         appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "VoiceNote")!),
                                                         label: "Record audio to help you remember this Anchor Point")
        
        confirmAlignmentButton = UIButton.makeConstraintButton(view,
                                                          alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                          appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Align")!),
                                                          label: "Start alignment countdown")
        
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
