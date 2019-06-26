//
//  ResumeTrackingConfirmController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

/// A View Controller for aligning and confirming a route navigation resume state
class ResumeTrackingConfirmController: UIViewController {

    /// button for aligning phone
    var confirmAlignmentButton: UIButton!
    
    /// button for recalling a voice note for a route
    var readVoiceNoteButton: UIButton!
    
    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        view.frame = CGRect(x: 0,
//                            y: UIConstants.yOriginOfButtonFrame,
//                            width: UIConstants.buttonFrameWidth,
//                            height: UIConstants.buttonFrameHeight)
        
        let label = UILabel(frame: CGRect(x: 15,
                                          y: UIScreen.main.bounds.size.height/5,
                                          width: UIScreen.main.bounds.size.width-30,
                                          height: UIScreen.main.bounds.size.height/2))
        
        view.frame = CGRect(x: 0,
                            y: 0,
                            width: UIScreen.main.bounds.size.width,
                            height: UIScreen.main.bounds.size.height)
        
//        let label = UILabel(frame: CGRect(x: 15,
//                                          y: UIScreen.main.bounds.size.height/5,
//                                          width: UIScreen.main.bounds.size.width-30,
//                                          height: UIScreen.main.bounds.size.height/2))
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        let waitingPeriod = ViewController.alignmentWaitingPeriod
        let alignInfo = String.localizedStringWithFormat(NSLocalizedString("Hold your device flat with the screen facing up. Press the top (short) edge flush against the same vertical surface that you used to create the landmark.  When you are ready, activate the align button to start the %lu-second alignment countdown that will complete the procedure. Do not move the device until the phone provides confirmation via a vibration or sound cue.", comment: "Info for user"), waitingPeriod)

        // var mainText: String?
        let mainText = alignInfo
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
                                                       appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Read")!),
                                                       label: "Play recorded voice note")
        
        // MARK: ConfirmAlignmentButton
        confirmAlignmentButton = UIButton.makeImageButton(view,
                                                          alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                          appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Align")!),
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
