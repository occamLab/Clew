//
//  ResumeTrackingConfirmController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

class ResumeTrackingConfirmController: UIViewController {
    
    /// the view on which the user can confirm the tracking resume procedure
    var resumeTrackingConfirmView: UIView!
    
    var confirmAlignmentButton: UIButton!
    
    var readVoiceNoteButton: UIButton!
    
    /// The button that allows the user to start the alignment countdown
//            let confirmAlignmentButton = ActionButtonComponents(appearance: .textButton(label: "Align"),
//                                                                label: "Start \(ViewController.alignmentWaitingPeriod)-second alignment countdown",
//                                                                targetSelector: Selector.confirmAlignmentButtonTapped,
//                                                                alignment: .center,
//                                                                tag: 0)
//
//            let readVoiceNoteButton = ActionButtonComponents(appearance: .textButton(label: "Play Note"),
//                                                             label: "Play recorded voice note",
//                                                             targetSelector: Selector.readVoiceNoteButtonTapped,
//                                                             alignment: .left,
//                                                             tag: UIView.readVoiceNoteButtonTag)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view = UIView(frame: CGRect(x: 0,
                                    y: UIConstants.yOriginOfButtonFrame,
                                    width: UIConstants.buttonFrameWidth,
                                    height: UIConstants.buttonFrameHeight))        
        
        let label = UILabel(frame: CGRect(x: 15,
                                          y: UIScreen.main.bounds.size.height/5,
                                          width: UIScreen.main.bounds.size.width-30,
                                          height: UIScreen.main.bounds.size.height/2))
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
//        view.isHidden = true
        
        var mainText : String?
        if let mainText: String = mainText {
            label.textColor = UIColor.white
            label.textAlignment = .center
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.font = label.font.withSize(20)
            label.text = mainText
            label.tag = UIView.mainTextTag
            view.addSubview(label)
        }
        
        // MARK: ReadVoiceNoteButton
        /// The button that plays back the recorded voice note associated with a landmark
        readVoiceNoteButton = UIButton.makeImageButton(view,
                                                       alignment: UIConstants.ButtonContainerHorizontalAlignment.left,
                                                       appearance: UIConstants.ButtonAppearance.textButton(label: "Play Note"),
                                                       label: "Play recorded voice note")
        
        // MARK: ConfirmAlignmentButton
        confirmAlignmentButton = UIButton.makeImageButton(view,
                                                          alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                          appearance: UIConstants.ButtonAppearance.textButton(label: "Align"),
                                                          label: "Start \(ViewController.alignmentWaitingPeriod)-second alignment countdown")
        
        if let parent: UIViewController = parent {
            readVoiceNoteButton.addTarget(parent,
                                   action: #selector(ViewController.readVoiceNote),
                                   for: .touchUpInside)
            confirmAlignmentButton.addTarget(parent,
                                          action: #selector(ViewController.confirmAlignment),
                                          for: .touchUpInside)
        }
        
        // Do any additional setup after loading the view.
        view.addSubview(readVoiceNoteButton)
        view.addSubview(confirmAlignmentButton)
    }
}
