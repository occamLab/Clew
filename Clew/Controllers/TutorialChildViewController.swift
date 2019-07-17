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

class TutorialChildViewController: UIViewController, ClewObserver {
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

        let buttonLabel = UILabel(frame: CGRect(x: 0, y:0, width: 300, height: 150))


        buttonLabel.layer.masksToBounds = true
        buttonLabel.layer.cornerRadius = 8.0
        buttonLabel.numberOfLines = 0
        //        buttonLabel.center = CGPoint(x: xCenter, y: 275)
        //        buttonLabel.center = CGPoint(x: 200, y: 275)
        buttonLabel.textAlignment = .center
        buttonLabel.text = calloutText
        buttonLabel.backgroundColor = UIColor.white
        //self.sendSubviewToBack(buttonLabel)
        buttonLabel.isHidden = false
        buttonLabel.tag = 0xCADFACE

//        let arrowImage = UIImage(named: "calloutArrow")
//        let imageView = UIImageView(image: arrowImage!)
//        view.addSubview(imageView)
//        imageView.isHidden = false

        let xCenter = viewToCallout.frame.midX
        let yCenter = viewToCallout.frame.maxY + 50
        print("1 - locationText")
        print(viewToCallout.frame.minX)
        buttonLabel.center = CGPoint(x: xCenter, y: 200)
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
        view.sendSubviewToBack(buttonLabel)
         return buttonLabel
    }

    func createCalloutArrowToView(withTagID tagID: Int, arrowTilt: Int)-> UIView? {
        guard let grandParent = tutorialParent?.parent as? ViewController,
            let viewToCallout = grandParent.view.viewWithTag(tagID) else {
                return nil
            }
        let arrowImage = UIImage(named: "calloutArrow")
        let imageView = UIImageView(image: arrowImage!)
        view.addSubview(imageView)
        imageView.isHidden = false
        let xCenter = viewToCallout.frame.midX
        imageView.frame = CGRect(x: xCenter - imageView.frame.width/4, y: 325, width: 100, height: 100)
        return imageView
    }

    func finishAnnouncement(announcement: String) { }
    func didReceiveNewCameraPose(transform: simd_float4x4)  {}
    func didTransitionTo(newState: AppState) {}
}
