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
class PauseTrackingController: UIViewController {

    /// button for storing landmark descriptions
    var enterLandmarkDescriptionButton: UIButton!
    
    /// button for recording a voice note about a
    /// landmark
    var recordVoiceNoteButton: UIButton!
    
    /// button for aligning phone position in space
    var confirmAlignmentButton: UIButton!

    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()

        view.frame = CGRect(x: 0,
                            y: 0,
                            width: UIScreen.main.bounds.size.width,
                            height: UIScreen.main.bounds.size.height)
                
        let label = UILabel(frame: CGRect(x: 15,
                                          y: UIScreen.main.bounds.size.height/5,
                                          width: UIScreen.main.bounds.size.width-30,
                                          height: UIScreen.main.bounds.size.height/2))
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
//        view.isHidden = true
        
        let mainText = "Landmarks allow you to save or pause your route. You will need to return to the landmark to load or unpause your route. Before creating the landmark, specify text or voice to help you remember its location. To create a landmark, hold your device flat with the screen facing up. Press the top (short) edge flush against a flat vertical surface (such as a wall).  The \"align\" button starts a \(ViewController.alignmentWaitingPeriod)-second countdown. During this time, do not move the device."
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = label.font.withSize(20)
        label.text = mainText
        label.tag = UIView.mainTextTag
        view.addSubview(label)
        
        enterLandmarkDescriptionButton = UIButton.makeImageButton(view,
                                                                  alignment: UIConstants.ButtonContainerHorizontalAlignment.left,
                                                                  appearance: UIConstants.ButtonAppearance.textButton(label: "Describe"),
                                                                  label: "Enter text to help you remember this landmark")
        
        recordVoiceNoteButton = UIButton.makeImageButton(view,
                                                         alignment: UIConstants.ButtonContainerHorizontalAlignment.right,
                                                         appearance: UIConstants.ButtonAppearance.textButton(label: "Voice Note"),
                                                         label: "Record audio to help you remember this landmark")
        
        confirmAlignmentButton = UIButton.makeImageButton(view,
                                                          alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                          appearance: UIConstants.ButtonAppearance.textButton(label: "Align"),
                                                          label: "Start \(ViewController.alignmentWaitingPeriod)-second alignment countdown")
        
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
        
        // Do any additional setup after loading the view.
        view.addSubview(enterLandmarkDescriptionButton)
        view.addSubview(recordVoiceNoteButton)
        view.addSubview(confirmAlignmentButton)
        
    }
}
