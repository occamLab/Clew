//
//  ResumeTrackingController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

class ResumeTrackingController: UIViewController {

    /// the view on which the user can initiate the tracking resume procedure
    var resumeTrackingView: UIView!
    
    var resumeButton: UIButton!
    
    //        let resumeButton = ActionButtonComponents(appearance: .textButton(label: "Resume"), label: "Resume", targetSelector: Selector.resumeButtonTapped, alignment: .center, tag: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view = UIView(frame: CGRect(x: 0,
                                    y: 0,
                                    width: UIScreen.main.bounds.size.width,
                                    height: UIScreen.main.bounds.size.height))

        let label = UILabel(frame: CGRect(x: 15,
                                          y: UIScreen.main.bounds.size.height/5,
                                          width: UIScreen.main.bounds.size.width-30,
                                          height: UIScreen.main.bounds.size.height/2))
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.isHidden = true
        
        let mainText = "Return to the last paused location and press Resume for further instructions."
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = label.font.withSize(20)
        label.text = mainText
        label.tag = UIView.mainTextTag
        
        /// The button that the allows the user to resume a paused route
        resumeButton = UIButton.makeImageButton(view,
                                                alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                appearance: UIConstants.ButtonAppearance.textButton(label: "Resume"),
                                                label: "Resume")
        
        // Do any additional setup after loading the view.
        view.addSubview(label)
        view.addSubview(resumeButton)
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
