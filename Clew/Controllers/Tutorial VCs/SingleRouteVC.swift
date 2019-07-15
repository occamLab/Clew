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
    var gotItButton: UIButton!
    var announcementManager = AnnouncementManager()
    var navigateView: UIView!
    var navigateLabel: UILabel!
    var pauseView: UIView!
    var pauseLabel: UILabel!
    var pauseNextButton: UIButton!
    
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
    
    @objc func nextButtonAction(sender: UIButton!) {
        landmarkView.removeFromSuperview()
        recordView = createRecordView()
        self.view.addSubview(recordView)
    }
    
    @objc func gotItButtonAction(sender: UIButton!) {
        gotItButton.removeFromSuperview()
        backgroundShadow.removeFromSuperview()
    }
    
    @objc func pauseNextButtonAction(sender: UIButton!) {
        pauseView.removeFromSuperview()
        navigateView = createNavigateView()
        self.view.addSubview(navigateView)
    }
    
    override func didTransitionTo(newState: AppState) {
        if case .recordingRoute = newState {
            tutorialParent?.state = .recordingSingleRoute
            recordLabel.removeFromSuperview()
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
    }
    
    func createLandmarkView() -> UIView {
        // Initialize views and add them to the ViewController's view
        landmarkView = UIView(frame:CGRect(x: 0,
                                           y: 0,
                                           width: UIScreen.main.bounds.size.width,
                                           height: UIScreen.main.bounds.size.height))
        
        landmarkLabel = UILabel(frame: CGRect(x: 150, y: 200, width: 200, height: 150))
        landmarkLabel.text = "Landmark button helps create saved routes. We'll return to this later, for now click on the 'next' button."
        landmarkLabel.textColor = UIColor.black
        landmarkLabel.backgroundColor = UIColor.white
        landmarkLabel.textAlignment = .center
        landmarkLabel.numberOfLines = 0
        landmarkLabel.lineBreakMode = .byWordWrapping
//        landmarkLabel.layoutMargins = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 10.0)
        landmarkLabel.layer.masksToBounds = true
        landmarkLabel.layer.cornerRadius = 8.0
        landmarkLabel.layer.borderColor = UIColor.black.cgColor
        landmarkLabel.layer.borderWidth = 3.0
        landmarkView.addSubview(landmarkLabel)
        
        nextButton = UIButton(frame: CGRect(x: 150, y: 350, width: 100, height: 50))
        nextButton.backgroundColor = .white
        nextButton.setTitleColor(.black, for: .normal)
        nextButton.setTitle("Next", for: .normal)
        nextButton.layer.masksToBounds = true
        nextButton.layer.cornerRadius = 8.0
        nextButton.isAccessibilityElement = true
        nextButton.isUserInteractionEnabled = true
        nextButton.addTarget(self, action: #selector(nextButtonAction), for: .touchUpInside)
        landmarkView.addSubview(nextButton)
        
        return landmarkView
    }
    
    func createRecordView() -> UIView {
        recordView = TransparentTouchView(frame:CGRect(x: 0,
                                                       y: 0,
                                                       width: UIScreen.main.bounds.size.width,
                                                       height: UIScreen.main.bounds.size.height))
        
        recordLabel = UILabel(frame: CGRect(x: 100, y: 200, width: 200, height: 150))
        recordLabel.text = "Record button allows you to start recording a route, click the 'record' button to continue."
        recordLabel.isAccessibilityElement = true
        recordLabel.textColor = UIColor.black
        recordLabel.backgroundColor = UIColor.white
        recordLabel.layer.masksToBounds = true
        recordLabel.layer.cornerRadius = 8.0
        recordLabel.textAlignment = .center
        recordLabel.numberOfLines = 0
        recordView.addSubview(recordLabel)
        
        gotItButton = UIButton(frame: CGRect(x: 100, y: 350, width: 100, height: 50))
        gotItButton.backgroundColor = .white
        gotItButton.setTitleColor(.black, for: .normal)
        gotItButton.setTitle("Got it!", for: .normal)
        gotItButton.layer.masksToBounds = true
        gotItButton.layer.cornerRadius = 8.0
        gotItButton.isAccessibilityElement = true
        gotItButton.isUserInteractionEnabled = true
        gotItButton.addTarget(self, action: #selector(gotItButtonAction), for: .touchUpInside)
        recordView.addSubview(gotItButton)
        
        return recordView
    }
    
    func createPauseView() -> UIView {
        // Initialize views and add them to the ViewController's view
        pauseView = UIView(frame:CGRect(x: 0,
                                           y: 0,
                                           width: UIScreen.main.bounds.size.width,
                                           height: UIScreen.main.bounds.size.height))
        
        pauseLabel = UILabel(frame: CGRect(x: 150, y: 200, width: 200, height: 150))
        pauseLabel.text = "Pause button allows you to save a route. We'll return to this function later."
        pauseLabel.textColor = UIColor.black
        pauseLabel.backgroundColor = UIColor.white
        pauseLabel.textAlignment = .center
        pauseLabel.numberOfLines = 0
        pauseLabel.lineBreakMode = .byWordWrapping
        pauseLabel.layer.masksToBounds = true
        pauseLabel.layer.cornerRadius = 8.0
        pauseView.addSubview(pauseLabel)
        
        pauseNextButton = UIButton(frame: CGRect(x: 150, y: 350, width: 100, height: 50))
        pauseNextButton.backgroundColor = .white
        pauseNextButton.setTitleColor(.black, for: .normal)
        pauseNextButton.setTitle("Next", for: .normal)
        pauseNextButton.layer.masksToBounds = true
        pauseNextButton.layer.cornerRadius = 8.0
        pauseNextButton.isAccessibilityElement = true
        pauseNextButton.isUserInteractionEnabled = true
        pauseNextButton.addTarget(self, action: #selector(pauseNextButtonAction), for: .touchUpInside)
        pauseView.addSubview(pauseNextButton)
        
        return pauseView
    }
    
    func createNavigateView() -> UIView {
            
        navigateView = TransparentTouchView(frame:CGRect(x: 0,
                                                       y: 0,
                                                       width: UIScreen.main.bounds.size.width,
                                                       height: UIScreen.main.bounds.size.height))
        
        navigateLabel = UILabel(frame: CGRect(x: 100, y: 200, width: 200, height: 150))
        navigateLabel.text = "Navigate button allows you to navigate back along the route you just recorded, click the 'navigate' button to continue."
        navigateLabel.isAccessibilityElement = true
        navigateLabel.textColor = UIColor.black
        navigateLabel.backgroundColor = UIColor.white
        navigateLabel.layer.masksToBounds = true
        navigateLabel.layer.cornerRadius = 8.0
        navigateLabel.textAlignment = .center
        navigateLabel.numberOfLines = 0
        navigateView.addSubview(navigateLabel)
        
        gotItButton = UIButton(frame: CGRect(x: 150, y: 350, width: 100, height: 50))
        gotItButton.backgroundColor = .white
        gotItButton.setTitleColor(.black, for: .normal)
        gotItButton.setTitle("Got it!", for: .normal)
        gotItButton.layer.masksToBounds = true
        gotItButton.layer.cornerRadius = 8.0
        gotItButton.isAccessibilityElement = true
        gotItButton.isUserInteractionEnabled = true
        gotItButton.addTarget(self, action: #selector(gotItButtonAction), for: .touchUpInside)
        navigateView.addSubview(gotItButton)
        
        return navigateView
    }
}

