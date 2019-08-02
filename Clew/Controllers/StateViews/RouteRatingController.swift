//
//  RouteRatingController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

/// A View Controller for handling rating the app
/// functionality and route that was just navigated
class RouteRatingController: UIViewController {

    /// a button for rating a path navigation positively
    var thumbsDownButton: UIButton!

    /// a button for rating a path navigation negatively
    var thumbsUpButton: UIButton!
    
    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()

        view.frame = CGRect(x: 0,
                                    y: 0,
                                    width: UIConstants.buttonFrameWidth,
                                    height: UIScreen.main.bounds.size.height)
        
        let label = UILabel(frame: CGRect(x: 15,
                                          y: UIScreen.main.bounds.size.height/5,
                                          width: UIScreen.main.bounds.size.width-30,
                                          height: UIScreen.main.bounds.size.height/2))
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        let mainText = NSLocalizedString("Please rate your service.", comment: "Message for user")
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = label.font.withSize(20)
        label.text = mainText
        label.tag = UIView.mainTextTag
        view.addSubview(label)
        
        thumbsDownButton = UIButton.makeImageButton(view,
                                                    alignment: UIConstants.ButtonContainerHorizontalAlignment.leftcenter,
                                                    appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "thumbs_down")!),
                                                    label: NSLocalizedString("thumbs-down.label", comment: "Unsatisfactory service"))
        thumbsUpButton = UIButton.makeImageButton(view,
                                                  alignment: UIConstants.ButtonContainerHorizontalAlignment.rightcenter,
                                                  appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "thumbs_up")!),
                                                  label: NSLocalizedString("thumbs-up.label", comment: "Satisfactory service"))
        
        if let parent: UIViewController = parent {
            thumbsUpButton.addTarget(parent,
                                     action: #selector(ViewController.sendLogData),
                                     for: .touchUpInside)
            thumbsDownButton.addTarget(parent,
                                       action: #selector(ViewController.sendDebugLogData),
                                       for: .touchUpInside)
        }
        
        view.addSubview(thumbsDownButton)
        view.addSubview(thumbsUpButton)
        
        // Do any additional setup after loading the view.
    }
}
