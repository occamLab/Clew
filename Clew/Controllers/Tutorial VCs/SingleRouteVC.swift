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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(backgroundShadow)
        landmarkView = createLandmarkView()
        self.view.addSubview(landmarkView)
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: nil)
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
        landmarkView.removeFromSuperview()
        recordView = createRecordView()
        self.view.addSubview(recordView)
    }
    
    @objc func recordNextButtonAction(sender: UIButton!) {
        recordNextButton.removeFromSuperview()
        backgroundShadow.removeFromSuperview()
    }
    
    @objc func pauseNextButtonAction(sender: UIButton!) {
        pauseView.removeFromSuperview()
        navigateView = createNavigateView()
        self.view.addSubview(navigateView)
    }
    
    @objc func navigateNextButtonAction(sender: UIButton!) {
        navigateNextButton.removeFromSuperview()
        backgroundShadow.removeFromSuperview()
    }
    
    override func didTransitionTo(newState: AppState) {
        if case .recordingRoute = newState {
            tutorialParent?.state = .recordingSingleRoute
            recordLabel.removeFromSuperview()
            print("is record label still here")
//            announcementManager.announce(announcement: "Walk forward for a few meters turn right and continue for a few meters press the 'stop' button when finished!")
        }
        
        if case .readyToNavigateOrPause = newState {
            self.view.addSubview(backgroundShadow)  
            tutorialParent?.state = .teachTheNavigationOfASingleRoute
            pauseView = createPauseView()
            self.view.addSubview(pauseView)
        }
        
        if case .navigatingRoute = newState {
            tutorialParent?.state = .teachTheNavigationOfASingleRoute
            navigateLabel.removeFromSuperview()
        }
        
        if case .ratingRoute = newState {
            tutorialParent?.state = .endTutorial
            announcementManager.remove()
        }
        
    }
    
    func createLandmarkView() -> UIView {
        // Initialize views and add them to the ViewController's view
        landmarkView = UIView(frame:CGRect(x: 0,
                                           y: 0,
                                           width: UIScreen.main.bounds.size.width,
                                           height: UIScreen.main.bounds.size.height))
        
        landmarkLabel = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*2/5, y: UIScreen.main.bounds.size.height/6, width: UIScreen.main.bounds.size.width*4/5, height: 200))
        landmarkLabel.text = "Landmark button helps create saved routes. We'll return to this later, for now click on the 'next' button."
        landmarkLabel.textColor = UIColor.black
        landmarkLabel.backgroundColor = UIColor.white
        landmarkLabel.textAlignment = .center
        landmarkLabel.numberOfLines = 0
        landmarkLabel.lineBreakMode = .byWordWrapping
//        landmarkLabel.layoutMargins = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 10.0)
        landmarkLabel.layer.masksToBounds = true
        landmarkLabel.layer.cornerRadius = 8.0
        landmarkLabel.font = UIFont.systemFont(ofSize: 24.0)
        landmarkLabel.layer.borderColor = UIColor.black.cgColor
        landmarkLabel.layer.borderWidth = 3.0
        
        landmarkView.addSubview(landmarkLabel)
        landmarkNextButton = createNextButton(buttonAction: #selector(landmarkNextButtonAction))
        landmarkView.addSubview(landmarkNextButton)
        
        return landmarkView
    }
    
    func createRecordView() -> UIView {
        recordView = TransparentTouchView(frame:CGRect(x: 0,
                                                       y: 0,
                                                       width: UIScreen.main.bounds.size.width,
                                                       height: UIScreen.main.bounds.size.height))
        
        recordLabel = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*2/5, y: UIScreen.main.bounds.size.height/6, width: UIScreen.main.bounds.size.width*4/5, height: 200))
        recordLabel.text = "Record button allows you to start recording a route, click the 'record' button to continue."
        recordLabel.isAccessibilityElement = true
        recordLabel.textColor = UIColor.black
        recordLabel.backgroundColor = UIColor.white
        recordLabel.layer.masksToBounds = true
        recordLabel.layer.cornerRadius = 8.0
        recordLabel.font = UIFont.systemFont(ofSize: 24.0)
        recordLabel.textAlignment = .center
        recordLabel.layer.borderWidth = 3.0
        recordLabel.numberOfLines = 0
        
        recordView.addSubview(recordLabel)
        recordNextButton = createNextButton(buttonAction: #selector(recordNextButtonAction))
        recordView.addSubview(recordNextButton)
        
        return recordView
    }
    
    func createPauseView() -> UIView {
        // Initialize views and add them to the ViewController's view
        pauseView = UIView(frame:CGRect(x: 0,
                                           y: 0,
                                           width: UIScreen.main.bounds.size.width,
                                           height: UIScreen.main.bounds.size.height))
        
        pauseLabel = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*2/5, y: UIScreen.main.bounds.size.height/6, width: UIScreen.main.bounds.size.width*4/5, height: 200))
        pauseLabel.text = "Pause button allows you to save a route. We'll return to this function later."
        pauseLabel.textColor = UIColor.black
        pauseLabel.backgroundColor = UIColor.white
        pauseLabel.textAlignment = .center
        pauseLabel.numberOfLines = 0
        pauseLabel.lineBreakMode = .byWordWrapping
        pauseLabel.layer.masksToBounds = true
        pauseLabel.layer.borderWidth = 3.0
        pauseLabel.font = UIFont.systemFont(ofSize: 24.0)
        pauseLabel.layer.cornerRadius = 8.0
        pauseView.addSubview(pauseLabel)
        pauseNextButton = createNextButton(buttonAction: #selector(pauseNextButtonAction))
        pauseView.addSubview(pauseNextButton)
        
        return pauseView
    }
    
    func createNavigateView() -> UIView {
            
        navigateView = TransparentTouchView(frame:CGRect(x: 0,
                                                       y: 0,
                                                       width: UIScreen.main.bounds.size.width,
                                                       height: UIScreen.main.bounds.size.height))
        
        navigateLabel = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*2/5, y: UIScreen.main.bounds.size.height/6, width: UIScreen.main.bounds.size.width*4/5, height: 200))
        navigateLabel.text = "Navigate button allows you to navigate back along the route you just recorded, click the 'navigate' button to continue."
        navigateLabel.isAccessibilityElement = true
        navigateLabel.textColor = UIColor.black
        navigateLabel.backgroundColor = UIColor.white
        navigateLabel.layer.masksToBounds = true
        navigateLabel.layer.cornerRadius = 8.0
        navigateLabel.font = UIFont.systemFont(ofSize: 24.0)
        navigateLabel.textAlignment = .center
        navigateLabel.layer.borderWidth = 3.0
        navigateLabel.numberOfLines = 0
        
        navigateView.addSubview(navigateLabel)
        navigateNextButton = createNextButton(buttonAction: #selector(navigateNextButtonAction))
        navigateView.addSubview(navigateNextButton)
        
        return navigateView
    }
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        label.center = CGPoint(x: 160, y: 285)
        label.textAlignment = .center
        label.text = "I'm a test label"
        self.view.addSubview(label)
    }
}

