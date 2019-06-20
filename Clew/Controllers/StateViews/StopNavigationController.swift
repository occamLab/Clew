//
//  StopNavigationController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

class StopNavigationController: UIViewController {

    /// Button view container for stop navigation button
    var stopNavigationView: UIView!
    
    var stopNavigationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view = UIView(frame: CGRect(x: 0,
                                    y: UIConstants.yOriginOfButtonFrame,
                                    width: UIConstants.buttonFrameWidth,
                                    height: UIConstants.buttonFrameHeight))

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
 
        stopNavigationButton = UIButton.makeImageButton(view,
                                                        alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                        appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "StopNavigation")!),
                                                        label: "Stop navigation")
        
        if let parent: UIViewController = parent {
            stopNavigationButton.addTarget(parent,
                                            action: #selector(ViewController.stopNavigation),
                                            for: .touchUpInside)
        }
        
        // Do any additional setup after loading the view.
        view.addSubview(stopNavigationButton)
    }
}
