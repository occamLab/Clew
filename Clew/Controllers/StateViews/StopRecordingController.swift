//
//  StopRecordingController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

class StopRecordingController: UIViewController {

    /// Button view container for stop recording button
    var stopRecordingView: UIView!
    
    var stopRecordingButton: UIButton!
    
    /// Image, label, and target for stop recording button.
    //        let stopRecordingButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "StopRecording")!), label: "Stop recording", targetSelector: Selector.stopRecordingButtonTapped, alignment: .center, tag: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view = UIView(frame: CGRect(x: 0,
                                    y: UIConstants.yOriginOfButtonFrame,
                                    width: UIConstants.buttonFrameWidth,
                                    height: UIConstants.buttonFrameHeight))
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.isHidden = true
        
        stopRecordingButton = UIButton.makeImageButton(view,
                                                       alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                       appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "StopRecording")!),
                                                       label: "Stop recording")
        
        // Do any additional setup after loading the view.
        view.addSubview(stopRecordingButton)
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
