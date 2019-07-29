//
//  PhoneOrientationStoryboardVC.swift
//  Clew
//
//  Created by HK Rho on 7/11/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import UIKit
import FLAnimatedImage

class PhoneOrientationGIFVC: TutorialChildViewController {
    var introView: UIView!
    var alignLabel: UILabel!
    var gotItButton: UIButton!
    var skipButton: UIButton!
    
    var clewGreen = UIColor(red: 103/255, green: 188/255, blue: 71/255, alpha: 1.0)
    
    
    @IBOutlet weak var PhoneOrientationGIF: FLAnimatedImageView!
    
    func createIntroView() -> UIView {
        introView = UIView(frame:CGRect(x: 0,
                                        y: 0,
                                        width: UIScreen.main.bounds.size.width,
                                        height: UIScreen.main.bounds.size.height))
        introView.backgroundColor = clewGreen
        alignLabel = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*2/5, y: UIScreen.main.bounds.size.height/8, width: UIScreen.main.bounds.size.width*4/5, height: 200))
        alignLabel.text = "ALIGN YOUR PHONE!"
        alignLabel.textColor = UIColor.white
        alignLabel.textAlignment = .center
        alignLabel.numberOfLines = 0
        alignLabel.lineBreakMode = .byWordWrapping
        alignLabel.layer.masksToBounds = true
        alignLabel.font = UIFont.systemFont(ofSize: 35.0)
        alignLabel.isAccessibilityElement = true
        alignLabel.accessibilityLabel = "Congratulations! You have successfully oriented your phone. Now you will be recording a simple single route."
        introView.addSubview(alignLabel)
        
        gotItButton = UIButton(frame: CGRect(x: UIConstants.buttonFrameWidth/(7/3),
                                             y: UIConstants.yOriginOfSettingsAndHelpButton + 10,
                                             width: UIConstants.buttonFrameWidth/5,
                                             height: UIConstants.buttonFrameWidth/7))
        gotItButton.isAccessibilityElement = true
        gotItButton.setTitle("Got it", for: .normal)
        gotItButton.titleLabel?.font = UIFont.systemFont(ofSize: 24.0)
        gotItButton.accessibilityLabel = "Got It"
        gotItButton.setImage(UIImage(named: "buttonBackground2"), for: .normal)
        gotItButton.addTarget(self, action: #selector(gotItButtonAction), for: .touchUpInside)
        introView.addSubview(gotItButton)
        
        skipButton = SkipButton().createSkipButton(buttonAction:
            #selector(skipButtonAction))
        introView.addSubview(skipButton)
//
//        gifView.frame = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
//        let imageData = try! Data(contentsOf: Bundle.main.url(forResource: "PhoneOrientation", withExtension: "gif")!)
//        phoneOrientationGIF = FLAnimatedImage(animatedGIFData: imageData)
        
        return introView
    }
    
    func transitionToMainApp() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController?.dismiss(animated: false)
        appDelegate.window = UIWindow(frame:UIScreen.main.bounds)
        appDelegate.window?.makeKeyAndVisible()
        appDelegate.window?.rootViewController = ViewController()
    }
    
    /// function that creates alerts for the home button
    func skipNavigationProcesses() {
        // Create alert to warn users of lost information
        let alert = UIAlertController(title: "Are you sure?",
                                      message: "If you exit this process right now, you won't be orienting your phone.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Skip this part of the tutorial.", style: .default, handler: { action -> Void in
            // proceed to readyToRecordSingleRoute state
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            (appDelegate.window?.rootViewController as? ViewController)?.tutorialViewController.state = .readyToRecordSingleRoute
        }
        ))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action -> Void in
            // nothing to do, just stay on the page
        }
        ))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func SkipTutorial(_ sender: UIButton) {
        transitionToMainApp()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        (appDelegate.window?.rootViewController as? ViewController)?.tutorialViewController.state = .readyToRecordSingleRoute
    }

    // Callback function for when the 'skip' button is tapped
    @objc func skipButtonAction(sender: UIButton!) {
        skipNavigationProcesses()
    }
    
    @objc func gotItButtonAction(sender: UIButton!) {
        introView.removeFromSuperview()
        tutorialParent?.state = .startOrientationTraining
        // TODO: state change
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let imageData = try! Data(contentsOf: Bundle.main.url(forResource: "PhoneOrientation", withExtension: "gif")!)
//        PhoneOrientationGIF.animatedImage = FLAnimatedImage(animatedGIFData: imageData)
        
        introView = createIntroView()
        self.view.addSubview(introView)
    }
}
