//
//  SingleRouteVC.swift
//  Clew Dev
//
//  Created by occamlab on 6/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

class SingleRouteVC: TutorialChildViewController {
    
    var landmarkView: UIView!
    var landmarkLabel: UILabel!
    var nextButton: UIButton!
    var recordView: UIView!
    var recordLabel: UILabel!
    var backgroundShadow: UIView! = TutorialShadowBackground()
    var recordPathController: UIView! = RecordPathController().view
    var announcementManager = AnnouncementManager()
    var navigateView: UIView!
    var navigateLabel: UILabel!
    var pauseView: UIView!
    var pauseLabel: UILabel!
    var clewGreen = UIColor(red: 103/255, green: 188/255, blue: 71/255, alpha: 1.0)
    var landmarkNextButton: UIButton!
    var recordNextButton: UIButton!
    var pauseNextButton: UIButton!
    var navigateNextButton: UIButton!
    var landmarkArrow: UIView?
    var landmarkCallout: UIView?
    var recordArrow: UIView?
    var recordCallout: UIView?
    var pauseArrow: UIView?
    var pauseCallout: UIView?
    var navigateArrow: UIView?
    var navigateCallout: UIView?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(backgroundShadow)
        
        createObjects()
        
        self.view.addSubview(landmarkCallout!)
        self.view.addSubview(landmarkNextButton)
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: nil)
    }
    
    func createObjects() {
        landmarkCallout = createCalloutToView(withTagID: 0xFEEDDAD, calloutText: "Landmark button helps create saved routes. We'll return to this later, for now click on the 'next' button.")
        landmarkCallout!.removeFromSuperview()
        recordCallout = createCalloutToView(withTagID: 0xFEEDDAD, calloutText: "Record button allows you to start recording a route, click the 'record' button to continue.")
        recordCallout!.removeFromSuperview()
        recordArrow = createCalloutArrowToView(withTagID: 0xFEEDDAD)
        recordArrow!.removeFromSuperview()
        pauseCallout = createCalloutToView(withTagID: 0xFEEDDAD, calloutText: "Pause button allows you to create saved routes, we'll return to this later, click the 'next' button to continue.")
        pauseCallout!.removeFromSuperview()
        navigateCallout = createCalloutToView(withTagID: 0xFEEDDAD, calloutText: "Navigate button allows you to navigate the route, click the button to continue")
        navigateCallout!.removeFromSuperview()
        navigateArrow = createCalloutArrowToView(withTagID: 0xFEEDDAD)
        navigateArrow!.removeFromSuperview()
        landmarkNextButton = createNextButton(buttonAction: #selector(landmarkNextButtonAction))
        recordNextButton = createNextButton(buttonAction: #selector(recordNextButtonAction))
        pauseNextButton = createNextButton(buttonAction: #selector(pauseNextButtonAction))
        navigateNextButton = createNextButton(buttonAction: #selector(navigateNextButtonAction))
    }
    
    func createNextButton(buttonAction: Selector) -> UIButton {
        nextButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*1/5, y: UIScreen.main.bounds.size.width*2/5 + UIScreen.main.bounds.size.height*1/10 + 100, width: UIScreen.main.bounds.size.width*2/5, height: UIScreen.main.bounds.size.height*1/10))
        nextButton.backgroundColor = clewGreen
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.setTitle("Next", for: .normal)
        nextButton.layer.masksToBounds = true
        nextButton.layer.cornerRadius = 10.0
        nextButton.layer.borderWidth = 3.0
        nextButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30.0)
        nextButton.isAccessibilityElement = true
        nextButton.isUserInteractionEnabled = true
        nextButton.addTarget(self, action: buttonAction, for: .touchUpInside)
        return nextButton
    }
    
    @objc func landmarkNextButtonAction(sender: UIButton!) {
        landmarkCallout!.removeFromSuperview()
        landmarkNextButton.removeFromSuperview()
        self.view.addSubview(recordCallout!)
        self.view.addSubview(recordNextButton)
    }
    
    @objc func recordNextButtonAction(sender: UIButton!) {
        recordNextButton.removeFromSuperview()
        self.view.addSubview(recordArrow!)
        backgroundShadow.removeFromSuperview()
    }
    
    @objc func pauseNextButtonAction(sender: UIButton!) {
        pauseCallout!.removeFromSuperview()
        pauseNextButton.removeFromSuperview()
        self.view.addSubview(navigateCallout!)
        self.view.addSubview(navigateNextButton!)
    }
    
    @objc func navigateNextButtonAction(sender: UIButton!) {
        navigateNextButton.removeFromSuperview()
        navigateArrow = createCalloutArrowToView(withTagID: 0xFEEDDAD)
        backgroundShadow.removeFromSuperview()
    }
    
    override func didTransitionTo(newState: AppState) {
        if case .recordingRoute = newState {
            tutorialParent?.state = .recordingSingleRoute
            recordCallout!.removeFromSuperview()
            recordArrow!.removeFromSuperview()
            print("is record label still here")
//            announcementManager.announce(announcement: "Walk forward for a few meters turn right and continue for a few meters press the 'stop' button when finished!")
        }
        
        if case .readyToNavigateOrPause = newState {
            self.view.addSubview(backgroundShadow)  
            tutorialParent?.state = .teachTheNavigationOfASingleRoute
            self.view.addSubview(pauseCallout!)
            self.view.addSubview(pauseNextButton!)
        }
        
        if case .navigatingRoute = newState {
            tutorialParent?.state = .teachTheNavigationOfASingleRoute
            navigateArrow!.removeFromSuperview()
            navigateCallout!.removeFromSuperview()
        }
        
        if case .ratingRoute = newState {
            tutorialParent?.state = .endTutorial
            announcementManager.remove()
            //            removeObserver(tutorialViewController) TODO: fix
        }
        
    }
}

