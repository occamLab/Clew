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
    
    /// Image, label, and target for stop navigation button.
    //        let stopNavigationButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "StopNavigation")!), label: "Stop navigation", targetSelector: Selector.stopNavigationButtonTapped, alignment: .center, tag: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view = UIView(frame: CGRect(x: 0,
                                    y: UIConstants.yOriginOfButtonFrame,
                                    width: UIConstants.buttonFrameWidth,
                                    height: UIConstants.buttonFrameHeight))

        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.isHidden = true
 
        stopNavigationButton = UIButton.makeImageButton(view,
                                                        alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                        appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "StopNavigation")!),
                                                        label: "Stop navigation")
        
        // Do any additional setup after loading the view.
        view.addSubview(stopNavigationButton)
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
