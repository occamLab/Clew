//
//  TutorialChildViewController.swift
//  Clew
//
//  Created by Terri Liu on 2019/7/2.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import SceneKit
import UIKit

class TutorialChildViewController: UIViewController, ClewDelegate {
    var tutorialParent: TutorialViewController? {
        return parent as? TutorialViewController
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.size.width,
                                                 height: UIScreen.main.bounds.size.height))
    }

    func createCalloutToView(withTagID tagID: Int, calloutText: String)->UIView? {
        guard let grandParent = tutorialParent?.parent as? ViewController,
            let viewToCallout = grandParent.view.viewWithTag(tagID) else {
                return nil
        }
        
        let buttonLabel = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*2/5, y: UIScreen.main.bounds.size.height/6, width: UIScreen.main.bounds.size.width*4/5, height: 200))
        buttonLabel.text = calloutText
        buttonLabel.textColor = UIColor.black
        buttonLabel.backgroundColor = UIColor.white
        buttonLabel.textAlignment = .center
        buttonLabel.numberOfLines = 0
        buttonLabel.lineBreakMode = .byWordWrapping
        //        landmarkLabel.layoutMargins = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 10.0)
        buttonLabel.layer.masksToBounds = true
        buttonLabel.layer.cornerRadius = 8.0
        buttonLabel.font = UIFont.systemFont(ofSize: 24.0)
        buttonLabel.layer.borderColor = UIColor.black.cgColor
        buttonLabel.layer.borderWidth = 3.0
        
        view.addSubview(buttonLabel)

//        let arrowImage = UIImage(named: "calloutArrow")
//        let imageView = UIImageView(image: arrowImage!)
//        view.addSubview(imageView)
//        imageView.isHidden = false

        let xCenter = viewToCallout.frame.midX
        let yCenter = viewToCallout.frame.maxY + 50
        print("1 - locationText")
        print(viewToCallout.frame.minX)
        buttonLabel.center = CGPoint(x: xCenter, y: UIScreen.main.bounds.size.height/8 + 100)
//        imageView.frame = CGRect(x: xCenter - imageView.frame.width/4, y: 325, width: 100, height: 100)

        /// button to hide the existing UILabel
//        var checkButton: UIButton!
//        checkButton = UIButton(frame: CGRect(x: viewToCallout.frame.midX, y: 310, width: 100, height: 30))
//        checkButton.isAccessibilityElement = true
//        checkButton.setTitle("Check", for: .normal)
//        checkButton.accessibilityLabel = "Check"
//        checkButton.setImage(UIImage(named: "CheckMark"), for: .normal)
//


        view.addSubview(buttonLabel)
//        view.sendSubviewToBack(buttonLabel)
        return buttonLabel
    }

    func createCalloutArrowToView(withTagID tagID: Int)-> UIView? {
        guard let grandParent = tutorialParent?.parent as? ViewController,
            let viewToCallout = grandParent.view.viewWithTag(tagID) else {
                return nil
            }
        let arrowImage = UIImage(named: "calloutArrow")
        let imageView = UIImageView(image: arrowImage!)
        view.addSubview(imageView)
        imageView.isHidden = false
        let xCenter = viewToCallout.frame.midX
        imageView.frame = CGRect(x: xCenter - imageView.frame.width/4, y: 375, width: 100, height: 100)
        return imageView
    }

    func finishAnnouncement(announcement: String) { }
    func didReceiveNewCameraPose(transform: simd_float4x4)  {}
    func didTransitionTo(newState: AppState) {}
    func allowRouteRating() -> Bool {
        return true
    }
}
