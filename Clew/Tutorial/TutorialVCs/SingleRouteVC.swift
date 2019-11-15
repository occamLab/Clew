//
//  SingleRouteVC.swift
//  Clew Dev
//
//  Created by occamlab on 6/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

class SingleRouteVC: TutorialChildViewController {
    
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
    var singleRouteCongratsView: UIView!
    var congratsLabel: UILabel!
    var congratsNextButton: UIButton!
    /////
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.addSubview(backgroundShadow)
        
        createObjects()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: landmarkCallout)
        NotificationCenter.default.post(name: Notification.Name("UnhideMainScreenAccessibilityElements"), object: nil)
        
        self.view.addSubview(landmarkCallout!)
        self.view.addSubview(landmarkNextButton)
        self.view.addSubview(landmarkArrow!)
        self.view.addSubview(skipButton!)
        self.view.bringSubviewToFront(skipButton!)
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func createObjects() {
        landmarkCallout = createCalloutToView(withTagID: UIView.recordPathButtonTag, calloutText: NSLocalizedString("The Landmark button helps create saved routes. For now, let's just create a single use route.", comment: "Landmark callout during tutorial."), buttonAccessibilityName: NSLocalizedString("Landmark Button", comment: "Landmark Button"))
        landmarkArrow = createCalloutArrowToView(withTagID: UIView.addAnchorPointButtonTag)

        recordArrow = createCalloutArrowToView(withTagID: UIView.recordPathButtonTag)

        landmarkNextButton = NextButton().createNextButton(buttonAction: #selector(landmarkNextButtonAction))
        recordNextButton = NextButton().createNextButton(buttonAction: #selector(recordNextButtonAction))
        pauseNextButton = NextButton().createNextButton(buttonAction: #selector(pauseNextButtonAction))
        navigateNextButton = NextButton().createNextButton(buttonAction: #selector(navigateNextButtonAction))
        skipButton = SkipButton().createSkipButton(buttonAction:
            #selector(skipButtonAction))
        congratsNextButton = NextButton().createNextButton(buttonAction: #selector(endTutorialNextButtonAction))
        congratsNextButton.backgroundColor = UIColor.white
        congratsNextButton.setTitleColor(clewGreen, for: .normal)
        
        // TODO: disable VoiceOver for rootContainerView and recordPathController in the CongratsView
        singleRouteCongratsView = CongratsView().createCongratsView(congratsText: NSLocalizedString("Congratulations! \n You have completed the tutorial. \n Now you can get started with the app!", comment: "Congratulations callout for completing the tutorial."), congratsAccessibilityLabel: NSLocalizedString("Congratulations! You have completed the tutorial. Now you can get started with the app!", comment: "Congratulations callout for completing the tutorial accessibility label."))
        singleRouteCongratsView.addSubview(congratsNextButton)
    }
    
    func transitionToMainApp() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController?.dismiss(animated: false)
        appDelegate.window = UIWindow(frame:UIScreen.main.bounds)
        appDelegate.window?.makeKeyAndVisible()
        appDelegate.window?.rootViewController = ViewController()
    }
    
    @objc func skipButtonAction(sender: UIButton!) {
        skipNavigationProcesses()
    }

    
    /// function that creates alerts for the home button
    func skipNavigationProcesses() {
        // Create alert to warn users of lost information
        let alert = UIAlertController(title: NSLocalizedString("Are you sure?", comment: "Are you sure?"),
                                      message: NSLocalizedString("If you exit this process right now, you will be skipping the process of recording and navigating a simple route.", comment: "warning message"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Skip this part of the tutorial.", comment: "Skip this part of the tutorial."), style: .default, handler: { action -> Void in
            // proceed to home page
            self.transitionToMainApp()
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            (appDelegate.window?.rootViewController as? ViewController)?.tutorialViewController.state = .endTutorial
        }
        ))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .default, handler: { action -> Void in
            // nothing to do, just stay on the page
        }
        ))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func landmarkNextButtonAction(sender: UIButton!) {
        landmarkArrow!.removeFromSuperview()
        landmarkCallout!.removeFromSuperview()
        landmarkNextButton.removeFromSuperview()
        
        // Create record callout here instead of under createObjects() to prevent it from being added to view hiearchy upon initializing readyToRecordSingleRoute state.
        recordCallout = createCalloutToView(withTagID: UIView.recordPathButtonTag, calloutText: NSLocalizedString("The Record button allows you to start recording a route. Click the 'record' button to continue.", comment: "The Record button allows you to start recording a route. Click the 'record' button to continue."), buttonAccessibilityName: NSLocalizedString("Record Button", comment: "Record Button"))
        
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
        navigateCallout = createCalloutToView(withTagID: UIView.startNavigationButtonTag, calloutText: NSLocalizedString("The navigate button allows you to navigate the route, click the next button and then click the navigate button to continue", comment: "The navigate button allows you to navigate the route, click the next button and then click the navigate button to continue"), buttonAccessibilityName: NSLocalizedString("Navigate Button", comment: "Navigate Button"))
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
    
    @objc func endTutorialNextButtonAction(sender: UIButton!) {
        
        // remove all subviews after the end of single route tutorial portion
        for view in self.view.subviews {
            view.removeFromSuperview()
        }

        tutorialParent?.state = .endTutorial
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
                self.pauseCallout = self.createCalloutToView(withTagID: UIView.startNavigationButtonTag, calloutText: NSLocalizedString("The Pause button is also important to saving routes, but let's just keep recording a single use route for now. Click the next button.", comment: "The Pause button is also important to saving routes, but let's just keep recording a single use route for now. Click the next button."), buttonAccessibilityName: NSLocalizedString("Pause Button", comment: "Pause Button"))
                self.pauseArrow = self.createCalloutArrowToView(withTagID: UIView.pauseSessionButtonTag)
                self.view.addSubview(self.pauseCallout!)
                self.view.addSubview(self.pauseArrow!)
                self.view.addSubview(self.pauseNextButton!)
                // Brings tutorialViewController to the front so that the shadow can be added onto it and thus cover the startNavigationViewController
                self.tutorialParent?.parent?.view.bringSubviewToFront(self.tutorialParent!.view)
                self.view.bringSubviewToFront(self.skipButton!)
            }
        }
        
        if case .navigatingRoute = newState {
            tutorialParent?.state = .teachTheNavigationOfASingleRoute
            navigateArrow!.removeFromSuperview()
            navigateCallout!.removeFromSuperview()
        }
        
        
        if case .mainScreen = newState {
            // Double check that we are in tutorial mode to safe guard against future changes to the main app state that might inadvertently affect the tutorial.
            if tutorialParent?.state == .teachTheNavigationOfASingleRoute {
                self.view.addSubview(singleRouteCongratsView)
                
                // Delays bringing the TutorialViewController to the front until recordPathController has been added to the main ViewController. By bringing the TutorialViewController to the front, the congratsView added will also appear at the front.
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                    self.tutorialParent?.parent?.view.bringSubviewToFront(self.tutorialParent!.view)
                }
                tutorialParent?.state = .displayCongratsView
            } 
        }
        
    }
    
    override func allowRouteRating() -> Bool {
        return false
    }
    
    override func allowRoutesList() -> Bool {
        return false
    }
    
    override func allowLandmarkProcedure() -> Bool {
        return false
    }
    
    override func allowSettingsPressed() -> Bool {
        return false
    }
    
    override func allowFeedbackPressed() -> Bool {
        return false
    }
    
    override func allowHelpPressed() -> Bool {
        return false
    }
    
    override func allowHomeButtonPressed() -> Bool {
        return false
    }
    
    override func allowAnnouncements() -> Bool {
        return false
    }
    
    override func allowFirstTimePopups() -> Bool {
        return false
    }
    
    override func allowPauseButtonPressed() -> Bool {
        return false
    }
}

