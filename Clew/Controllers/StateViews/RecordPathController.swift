//
//  RecordPathController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

/// A View Controller for handling the recording path/route state
class RecordPathController: UIViewController {

    /// Button for recording a route
    var recordPathButton: UIButton!
    
    /// button for creating a new landmark
    var addLandmarkButton: UIButton!

    /// button for accessing saved routes
    var routesButton: UIButton!

    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()

        view.frame = CGRect(x: 0,
                            y: UIConstants.yOriginOfButtonFrame,
                            width: UIConstants.buttonFrameWidth,
                            height: UIConstants.buttonFrameHeight)
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        let label = UILabel(frame: CGRect(x: 15,
                                          y: UIScreen.main.bounds.size.height/5,
                                          width: UIScreen.main.bounds.size.width-30,
                                          height: UIScreen.main.bounds.size.height/2))
        
        var mainText: String?
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
                                                    appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Record")!),
                                                    label: NSLocalizedString("record-path.button.label", comment: "A button that allows you to video record path to a destination"))
        
        addLandmarkButton = UIButton.makeImageButton(view,
                                                     alignment: UIConstants.ButtonContainerHorizontalAlignment.right,
                                                     appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Landmark")!),
                                                     label: NSLocalizedString("landmark.button.label", comment: "A button that allows you to create a landmark to save a route"))
        
        routesButton = UIButton.makeImageButton(view,
                                                alignment: UIConstants.ButtonContainerHorizontalAlignment.left,
                                                appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "route")!),
                                                label: NSLocalizedString("open-saved-routes.button.label", comment: "The label of a button that allows you to access your list of saved routes"))
        
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
