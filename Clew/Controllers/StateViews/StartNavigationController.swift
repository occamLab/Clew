//
//  StartNavigationController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

class StartNavigationController: UIViewController {

    /// Button view container for start navigation button
    var startNavigationView: UIView!
    
    var startNavigationButton: UIButton!
    
    var pauseButton: UIButton!
    
    //        /// Image, label, and target for start navigation button.
    //        let startNavigationButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "StartNavigation")!), label: "Start navigation", targetSelector: Selector.startNavigationButtonTapped, alignment: .center, tag: 0)
    //
    //
    //        /// Title, label, and target for the pause button
    //        let pauseButton = ActionButtonComponents(appearance: .textButton(label: "Pause"), label: "Pause session", targetSelector: Selector.pauseButtonTapped, alignment: .right, tag: UIView.pauseButtonTag)

    
    override func viewDidLoad() {
        super.viewDidLoad()

        view = UIView(frame: CGRect(x: 0,
                                    y: UIConstants.yOriginOfButtonFrame,
                                    width: UIConstants.buttonFrameWidth,
                                    height: UIConstants.buttonFrameHeight))

        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.isHidden = true
        
        startNavigationButton = UIButton.makeImageButton(view,
                                                         alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                         appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "StartNavigation")!),
                                                         label: "Start navigation")
        
        pauseButton = UIButton.makeImageButton(view,
                                               alignment: UIConstants.ButtonContainerHorizontalAlignment.right,
                                               appearance: UIConstants.ButtonAppearance.textButton(label: "Pause"),
                                               label: "Pause session")
        
        // Do any additional setup after loading the view.
        view.addSubview(startNavigationButton)
        view.addSubview(pauseButton)
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
