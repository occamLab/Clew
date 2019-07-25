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

var scrollView: UIScrollView!

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

    func createCalloutToView(withTagID tagID: Int, calloutText: String, buttonAccessibilityName: String? = nil)->UIView? {
        guard let grandParent = tutorialParent?.parent as? ViewController,
            let viewToCallout = grandParent.view.viewWithTag(tagID) else {
                return nil
        }
        
        let buttonLabel = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*2/5, y: UIScreen.main.bounds.size.height/6, width: UIScreen.main.bounds.size.width*4/5 + 50, height: 200))
        buttonLabel.text = calloutText
        buttonLabel.textColor = UIColor.black
        buttonLabel.backgroundColor = UIColor.white
        buttonLabel.textAlignment = .center
        buttonLabel.numberOfLines = 0
        buttonLabel.lineBreakMode = .byWordWrapping
        buttonLabel.layer.masksToBounds = true
        buttonLabel.layer.cornerRadius = 8.0
        buttonLabel.font = UIFont.systemFont(ofSize: 24.0)
        buttonLabel.layer.borderColor = UIColor.black.cgColor
        buttonLabel.layer.borderWidth = 3.0
        if buttonAccessibilityName != nil {
            buttonLabel.accessibilityLabel = "Description for" +  buttonAccessibilityName! + ":" + calloutText
        }
        let xCenter = viewToCallout.frame.midX
        let yCenter = viewToCallout.frame.maxY + 50
        
//        NSLayoutConstraint.activate([
//            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
//            scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
//            ])
//        scrollView.addSubview(buttonLabel)
//
//            buttonLabel.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            buttonLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//            buttonLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
//            buttonLabel.topAnchor.constraint(equalTo: scrollView.topAnchor),
//            buttonLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
//            buttonLabel.heightAnchor.constraint(equalToConstant: 2000).isActive = true
//            buttonLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
//            ])

        print("1 - locationText")
        print(viewToCallout.frame.minX)
        buttonLabel.center = CGPoint(x: xCenter, y: UIScreen.main.bounds.size.height/8 + 100)

        return buttonLabel
    }

    func createCalloutArrowToView(withTagID tagID: Int)-> UIView? {
        guard let grandParent = tutorialParent?.parent as? ViewController,
            let viewToCallout = grandParent.view.viewWithTag(tagID) else {
                return nil
            }
        let arrowImage = UIImage(named: "calloutArrow")
        let imageView = UIImageView(image: arrowImage!)
        imageView.isHidden = false
        let xCenter = viewToCallout.frame.midX
        imageView.frame = CGRect(x: xCenter - imageView.frame.width/8, y: 375, width: 100, height: 100)

        return imageView
    }

    func finishAnnouncement(announcement: String) { }
    func didReceiveNewCameraPose(transform: simd_float4x4)  {}
    func didTransitionTo(newState: AppState) {}
    
    func allowRouteRating() -> Bool {
        return true
    }
    func allowRoutesList() -> Bool {
        return true
    }
    func allowLandmarkProcedure() -> Bool {
        return true
    }
    func allowSettingsPressed() -> Bool {
        return true
    }
    func allowFeedbackPressed() -> Bool {
        return true
    }
    func allowHelpPressed() -> Bool {
        return true
    }
    func allowHomeButtonPressed() -> Bool {
        return true
    }
    func allowAnnouncements() -> Bool {
        return true
    }
}
