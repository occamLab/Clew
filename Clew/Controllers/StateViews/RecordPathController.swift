//
//  RecordPathController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

class RecordPathController: UIViewController {

    /// Button view container for start recording button.
    var recordPathView: UIView!
    
    var recordPathButton: UIButton!
    
    var addLandmarkButton: UIButton!

    var routesButton: UIButton!
    
    //        /// Image, label, and target for start recording button.
    //        let recordPathButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "StartRecording")!), label: "Record path", targetSelector: Selector.recordPathButtonTapped, alignment: .center, tag: 0)
    //
    //        /// Image, label, and target for start recording button. TODO: need an image
    //        let addLandmarkButton = ActionButtonComponents(appearance: .textButton(label: "Landmark"), label: "Create landmark", targetSelector: Selector.landmarkButtonTapped, alignment: .right, tag: 0)
    //
    //        /// Image, label, and target for routes button.
    //        let routesButton = ActionButtonComponents(appearance: .textButton(label: "Routes"), label: "Saved routes list", targetSelector: Selector.routesButtonTapped, alignment: .left, tag: 0)


    override func viewDidLoad() {
        super.viewDidLoad()

        view = UIView(frame: CGRect(x: 0,
                                    y: UIConstants.yOriginOfButtonFrame,
                                    width: UIConstants.buttonFrameWidth,
                                    height: UIConstants.buttonFrameHeight))
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.isHidden = true

        recordPathButton = UIButton.makeImageButton(view,
                                                    alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                    appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "StartRecording")!),
                                                    label: "Record path")
        
        addLandmarkButton = UIButton.makeImageButton(view,
                                                     alignment: UIConstants.ButtonContainerHorizontalAlignment.right,
                                                     appearance: UIConstants.ButtonAppearance.textButton(label: "Landmark"),
                                                     label: "Saved routes list")
        
        // Do any additional setup after loading the view.
        // Do any additional setup after loading the view.
        view.addSubview(routesButton)
        view.addSubview(addLandmarkButton)
        view.addSubview(recordPathButton)
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
