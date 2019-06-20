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
//    var recordPathView: UIView!
    
    var recordPathButton: UIButton!
    
    var addLandmarkButton: UIButton!

    var routesButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.frame = CGRect(x: 0,
                            y: UIConstants.yOriginOfButtonFrame,
                            width: UIConstants.buttonFrameWidth,
                            height: UIConstants.buttonFrameHeight)
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
//        view.isHidden = true
        
        let label = UILabel(frame: CGRect(x: 15,
                                          y: UIScreen.main.bounds.size.height/5,
                                          width: UIScreen.main.bounds.size.width-30,
                                          height: UIScreen.main.bounds.size.height/2))
        
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

        recordPathButton = UIButton.makeImageButton(view,
                                                    alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                    appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "StartRecording")!),
                                                    label: "Record path")
        
        addLandmarkButton = UIButton.makeImageButton(view,
                                                     alignment: UIConstants.ButtonContainerHorizontalAlignment.right,
                                                     appearance: UIConstants.ButtonAppearance.textButton(label: "Landmark"),
                                                     label: "Saved routes list")
        
        routesButton = UIButton.makeImageButton(view,
                                                alignment: UIConstants.ButtonContainerHorizontalAlignment.left,
                                                appearance: UIConstants.ButtonAppearance.textButton(label: "Routes"),
                                                label: "Saved routes list")
        
        if let parent: UIViewController = parent {
            routesButton.addTarget(parent,
                                          action: #selector(ViewController.routesButtonPressed),
                                          for: .touchUpInside)
            addLandmarkButton.addTarget(parent,
                                          action: #selector(ViewController.startCreateLandmarkProcedure),
                                          for: .touchUpInside)
            recordPathButton.addTarget(parent,
                                          action: #selector(ViewController.recordPath),
                                          for: .touchUpInside)
        }
        
        // Do any additional setup after loading the view.
        view.addSubview(routesButton)
        view.addSubview(addLandmarkButton)
        view.addSubview(recordPathButton)
    }
}
