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
    //        let confirmAlignmentButton = ActionButtonComponents(appearance: .textButton(label: "Align"), label: "Start \(ViewController.alignmentWaitingPeriod)-second alignment countdown", targetSelector: Selector.confirmAlignmentButtonTapped, alignment: .center, tag: 0)
    
    //        let readVoiceNoteButton = ActionButtonComponents(appearance: .textButton(label: "Play Note"), label: "Play recorded voice note", targetSelector: Selector.readVoiceNoteButtonTapped, alignment: .left, tag: UIView.readVoiceNoteButtonTag)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view = UIView(frame: CGRect(x: 0,
                                    y: 0,
                                    width: UIScreen.main.bounds.size.width,
                                    height: UIScreen.main.bounds.size.height))        

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
        
        // Do any additional setup after loading the view.
        view.addSubview(label)
        view.addSubview(readVoiceNoteButton)
        view.addSubview(confirmAlignmentButton)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
