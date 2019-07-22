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
        
        self.view.addSubview(landmarkCallout!)
        self.view.addSubview(landmarkNextButton)
        self.view.addSubview(skipButton)
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: nil)
    }
    
//    /// Used to identify the record path button so it can be located for callouts
//    static let recordPathButtonTag: Int = 0xFABDEED
//    /// Used to identify the landmark button so it can be located for callouts
//    static let landmarkButtonTag: Int = 0xBADFACE
//    /// Used to identify the saved routes list so it can be located for callouts
//    static let routesButtonTag = 0xBEEFAD
    
    func createObjects() {
        landmarkCallout = createCalloutToView(withTagID: UIView.recordPathButtonTag, calloutText: "Landmark button helps create saved routes. We'll return to this later, for now click on the 'next' button.")
        landmarkCallout!.removeFromSuperview()
        landmarkArrow = createCalloutArrowToView(withTagID: UIView.addLandmarkButtonTag)
//        landmarkArrow!.removeFromSuperview()
        recordCallout = createCalloutToView(withTagID: UIView.recordPathButtonTag, calloutText: "Record button allows you to start recording a route, click the 'record' button to continue.")
        recordCallout!.removeFromSuperview()
        recordArrow = createCalloutArrowToView(withTagID: UIView.recordPathButtonTag)
        recordArrow!.removeFromSuperview()
        
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
    }
    
    @objc func recordNextButtonAction(sender: UIButton!) {
        recordNextButton.removeFromSuperview()
        self.view.addSubview(recordArrow!)
        backgroundShadow.removeFromSuperview()
    }
    
    @objc func pauseNextButtonAction(sender: UIButton!) {
//        pauseCallout!.removeFromSuperview()
        pauseNextButton.removeFromSuperview()
        navigateCallout = createCalloutToView(withTagID: UIView.startNavigationButtonTag, calloutText: "Navigate button allows you to navigate the route, click the button to continue")
        navigateCallout!.removeFromSuperview()
        pauseArrow!.removeFromSuperview()
        pauseCallout!.removeFromSuperview()
        self.view.addSubview(navigateCallout!)
        self.view.addSubview(navigateNextButton!)
    }
    
    @objc func navigateNextButtonAction(sender: UIButton!) {
        navigateNextButton.removeFromSuperview()
        navigateArrow = createCalloutArrowToView(withTagID: UIView.startNavigationButtonTag)
//        navigateArrow = createCalloutArrowToView(withTagID: 0xFEEDDAD)
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
            // Delaying the callout introduction until after the view has successfully been added
            // TODO: think about healthier ways this can be done
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                self.pauseCallout = self.createCalloutToView(withTagID: UIView.startNavigationButtonTag, calloutText: "Pause button allows you to create saved routes, we'll return to this later, click the 'next' button to continue.")
                self.pauseArrow = self.createCalloutArrowToView(withTagID: UIView.pauseSessionButtonTag)
                self.view.addSubview(self.pauseCallout!)
                self.view.addSubview(self.pauseArrow!)
            }
            self.view.addSubview(pauseNextButton!)
            
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

