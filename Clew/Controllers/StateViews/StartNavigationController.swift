//
//  StartNavigationController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

/// A View Controller for the starting navigation state
class StartNavigationController: UIViewController {

    /// button for beginning navigation along a route
    var startNavigationButton: UIButton!
    
    /// button for pausing navigation
    var pauseButton: UIButton!

    /// called when the view has loaded.  We setup various app elements in here.
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
        
        startNavigationButton = UIButton.makeImageButton(view,
                                                         alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                         appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "StartNavigation")!),
                                                         label: "Start navigation")
        
        pauseButton = UIButton.makeImageButton(view,
                                               alignment: UIConstants.ButtonContainerHorizontalAlignment.right,
                                               appearance: UIConstants.ButtonAppearance.textButton(label: "Pause"),
                                               label: "Pause session")
        
        if let parent: UIViewController = parent {
            startNavigationButton.addTarget(parent,
                                   action: #selector(ViewController.startNavigation),
                                   for: .touchUpInside)
            pauseButton.addTarget(parent,
                                        action: #selector(ViewController.startPauseProcedure),
                                        for: .touchUpInside)
        }
        
        // Do any additional setup after loading the view.
        view.addSubview(startNavigationButton)
        view.addSubview(pauseButton)
    }
}
