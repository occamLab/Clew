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
        buttonLabel.textAlignment = .center
        buttonLabel.textColor = UIColor.black
        buttonLabel.layer.masksToBounds = true
        /// update label font
        /// TODO: is this a safe implementation? Might crash if label has no body, unclear.
        buttonLabel.font = UIFont.preferredFont(forTextStyle: .body)
        
        if buttonAccessibilityName != nil {
            buttonLabel.accessibilityLabel = "Description for" +  buttonAccessibilityName! + ":" + calloutText
        }
        let xCenter = viewToCallout.frame.midX
        let yCenter = viewToCallout.frame.maxY + 50
        

        print("1 - locationText")
        print(viewToCallout.frame.minX)
        buttonLabel.center = CGPoint(x: xCenter, y: UIScreen.main.bounds.size.height/8 + 100)

        let scrollView = UIScrollView()

        /// allow for constraints to be applied to label, scrollview
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.indicatorStyle = .white
        scrollView.layer.borderColor = UIColor.black.cgColor
        scrollView.layer.borderWidth = 3.0
        scrollView.layer.cornerRadius = 9.0
        scrollView.backgroundColor = UIColor.white

        buttonLabel.translatesAutoresizingMaskIntoConstraints = false

        /// place label inside of the scrollview
        scrollView.addSubview(buttonLabel)
        self.view.addSubview(scrollView)

        /// set top, left, right constraints on scrollView to
        /// "main" view + 8.0 padding on each side
        scrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 50).isActive = true
        scrollView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 70).isActive = true
        scrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -50).isActive = true
        /// set the height constraint on the scrollView to 0.5 * the main view height
        scrollView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.3).isActive = true

        scrollView.flashScrollIndicators()

        /// configure label: Zero lines + Word Wrapping
        buttonLabel.numberOfLines = 0
        buttonLabel.lineBreakMode = NSLineBreakMode.byWordWrapping


        /// set top, left, right AND bottom constraints on label to
        /// scrollView + 8.0 padding on each side
        buttonLabel.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 8).isActive = true
        buttonLabel.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -8).isActive = true
        buttonLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8).isActive = true
        buttonLabel.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8).isActive = true

        /// set the width of the label to the width of the scrollView (-16 for 8.0 padding on each side)
        /// center buttonLabel among scrollView so that it is centered vertically and horizontally
        buttonLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16).isActive = true
        buttonLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        buttonLabel.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true

        return scrollView
        
    }

    func convertToDynamicText(label: UILabel)-> UIView {
        let scrollView = UIScrollView()
        
        /// allow for constraints to be applied to label, scrollview
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.indicatorStyle = .white
        scrollView.layer.borderColor = UIColor.black.cgColor
        scrollView.layer.borderWidth = 3.0
        scrollView.layer.cornerRadius = 9.0
        scrollView.backgroundColor = UIColor.white
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        /// place label inside of the scrollview
        scrollView.addSubview(label)
        self.view.addSubview(scrollView)
        
        /// set top, left, right constraints on scrollView to
        /// "main" view + 8.0 padding on each side
        scrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 50).isActive = true
        scrollView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 70).isActive = true
        scrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -50).isActive = true
        /// set the height constraint on the scrollView to 0.5 * the main view height
        scrollView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.3).isActive = true
        
        scrollView.flashScrollIndicators()
        
        /// configure label: Zero lines + Word Wrapping
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        
        /// set top, left, right AND bottom constraints on label to
        /// scrollView + 8.0 padding on each side
        label.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 8).isActive = true
        label.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -8).isActive = true
        label.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8).isActive = true
        label.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8).isActive = true
        
        /// set the width of the label to the width of the scrollView (-16 for 8.0 padding on each side)
        /// center buttonLabel among scrollView so that it is centered vertically and horizontally
        label.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16).isActive = true
        label.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
        return scrollView
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
    func allowFirstTimePopups() -> Bool {
        return true
    }
    func allowPauseButtonPressed() -> Bool {
        return true
    }
}
