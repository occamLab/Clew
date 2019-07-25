//
//  SingleRouteVC.swift
//  Clew Dev
//
//  Created by occamlab on 6/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

class SingleRouteVC: TutorialChildViewController {
    
    var nextButton: UIButton!
    var backgroundShadow: UIView! = TutorialShadowBackground()
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
    /////
    var skipButton: UIButton!
    var skipYellow = UIColor(red: 254/255, green: 243/255, blue: 62/255, alpha: 1.0)
    var congratsView: UIView!
    var congratsLabel: UILabel!
    /////
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(backgroundShadow)
        
        createObjects()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: landmarkCallout)
        
        self.view.addSubview(landmarkCallout!)
        self.view.addSubview(landmarkNextButton)
        self.view.addSubview(landmarkArrow!)
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: nil)
    }
    
    func createObjects() {
        landmarkCallout = createCalloutToView(withTagID: UIView.recordPathButtonTag, calloutText: "The Landmark button helps create saved routes. For now, let's just create a single use route.", buttonAccessibilityName: "Landmark Button")
        landmarkArrow = createCalloutArrowToView(withTagID: UIView.addLandmarkButtonTag)
        recordCallout = createCalloutToView(withTagID: UIView.recordPathButtonTag, calloutText: "The Record button allows you to start recording a route. Click the 'record' button to continue.", buttonAccessibilityName: "Record Button")
        recordArrow = createCalloutArrowToView(withTagID: UIView.recordPathButtonTag)
        
        landmarkNextButton = createNextButton(buttonAction: #selector(landmarkNextButtonAction))
        recordNextButton = createNextButton(buttonAction: #selector(recordNextButtonAction))
        pauseNextButton = createNextButton(buttonAction: #selector(pauseNextButtonAction))
        navigateNextButton = createNextButton(buttonAction: #selector(navigateNextButtonAction))
        skipButton = createSkipButton()
    }
    
    func createNextButton(buttonAction: Selector) -> UIButton {
        nextButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*1/5, y: UIScreen.main.bounds.size.width*3/10 + UIScreen.main.bounds.size.height*1/10 + 100, width: UIScreen.main.bounds.size.width*2/5, height: UIScreen.main.bounds.size.height*1/10))
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
    
    /////
    func createSkipButton() -> UIButton {
        skipButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.size.width*1/2 - UIScreen.main.bounds.size.width*1/5, y: UIScreen.main.bounds.size.width*1/10, width: UIScreen.main.bounds.size.width*2/5, height: UIScreen.main.bounds.size.height*1/10))
        skipButton.backgroundColor = .white
        skipButton.setTitleColor(skipYellow, for: .normal)
        skipButton.setTitle("SKIP", for: .normal)
        skipButton.layer.masksToBounds = true
        skipButton.layer.cornerRadius = 8.0
        skipButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30.0)
        skipButton.isAccessibilityElement = true
        skipButton.isUserInteractionEnabled = true
        skipButton.addTarget(self, action: #selector(skipButtonAction), for: .touchUpInside)
        return skipButton
    }
    
    func transitionToMainApp() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController?.dismiss(animated: false)
        appDelegate.window = UIWindow(frame:UIScreen.main.bounds)
        appDelegate.window?.makeKeyAndVisible()
        appDelegate.window?.rootViewController = ViewController()
    }
    
    @objc func skipButtonAction(sender: UIButton!) {
        transitionToMainApp()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        (appDelegate.window?.rootViewController as? ViewController)?.tutorialViewController.state = .endTutorial
    }
    /////
    
    @objc func landmarkNextButtonAction(sender: UIButton!) {
        landmarkArrow!.removeFromSuperview()
        landmarkCallout!.removeFromSuperview()
        landmarkNextButton.removeFromSuperview()
        self.view.addSubview(recordCallout!)
        self.view.addSubview(recordNextButton)
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: recordCallout)
    }
    
    @objc func recordNextButtonAction(sender: UIButton!) {
        recordNextButton.removeFromSuperview()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: recordCallout)
        self.view.addSubview(recordArrow!)
        backgroundShadow.removeFromSuperview()
    }
    
    @objc func pauseNextButtonAction(sender: UIButton!) {
        pauseNextButton.removeFromSuperview()
        pauseArrow!.removeFromSuperview()
        pauseCallout!.removeFromSuperview()
        navigateCallout = createCalloutToView(withTagID: UIView.startNavigationButtonTag, calloutText: "The navigate button allows you to navigate the route, click the next button and then click the navigate button to continue", buttonAccessibilityName: "Navigate Button")
        self.view.addSubview(navigateCallout!)
        self.view.addSubview(navigateNextButton!)
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: navigateCallout)
    }
    
    @objc func navigateNextButtonAction(sender: UIButton!) {
        navigateNextButton.removeFromSuperview()
        backgroundShadow.removeFromSuperview()
        navigateArrow = createCalloutArrowToView(withTagID: UIView.startNavigationButtonTag)
        self.view.addSubview(navigateArrow!)
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: navigateCallout)
    }
    
    override func didTransitionTo(newState: AppState) {
        if case .recordingRoute = newState {
            tutorialParent?.state = .recordingSingleRoute
            recordCallout!.removeFromSuperview()
            recordArrow!.removeFromSuperview()
        }
        
        if case .readyToNavigateOrPause = newState {
            self.view.addSubview(backgroundShadow)  
            tutorialParent?.state = .teachTheNavigationOfASingleRoute
            // Delaying the callout introduction until after the view has successfully been added
            // TODO: think about healthier ways this can be done
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                self.pauseCallout = self.createCalloutToView(withTagID: UIView.startNavigationButtonTag, calloutText: "The Pause button is also important to saving routes, but let's just keep recording a single use route for now. Click the next button.", buttonAccessibilityName: "Pause Button")
                self.pauseArrow = self.createCalloutArrowToView(withTagID: UIView.pauseSessionButtonTag)
                self.view.addSubview(self.pauseCallout!)
                self.view.addSubview(self.pauseArrow!)
                self.view.addSubview(self.pauseNextButton!)
                // Brings tutorialViewController to the front so that the shadow can be added onto it and thus cover the startNavigationViewController
            self.tutorialParent?.parent?.view.bringSubviewToFront(self.tutorialParent!.view)
            }
        }
        
        if case .navigatingRoute = newState {
            tutorialParent?.state = .teachTheNavigationOfASingleRoute
            navigateArrow!.removeFromSuperview()
            navigateCallout!.removeFromSuperview()
        }
        
        if case .ratingRoute = newState {
            ///////
            //tutorialParent?.parent?.RouteRatingController.remove()
            ///////
            tutorialParent?.state = .endTutorial
            //            removeObserver(tutorialViewController) TODO: fix
        }
        
    }
    override func allowRouteRating() -> Bool {
        return false
    }
}

