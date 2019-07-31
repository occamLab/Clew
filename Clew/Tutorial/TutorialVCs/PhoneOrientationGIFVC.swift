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
    var descriptionLabel: UILabel!
    var gotItButton: UIButton!
    var skipButton: UIButton!
    var gifView: UIImageView?
    var gifImages: [UIImage]! = []
    
    var clewGreen = UIColor(red: 103/255, green: 188/255, blue: 71/255, alpha: 1.0)
    
    ////////
    func createImageArray(total: Int, imagePrefix: String) -> [UIImage] {
        var imageArray: [UIImage] = []

        for imageCount in 1..<total {
            let imageName = "\(imagePrefix)\(imageCount).png"
            let image = UIImage(named: imageName)
            imageArray.append(image!)
        }
        return imageArray
    }
    
    func animateGIF(imageView: UIImageView, images: [UIImage]) {
        imageView.animationImages = images
        imageView.animationDuration = 5.0
        imageView.startAnimating()
    }
    ////////
    
    
    func createIntroView() -> UIView {
        introView = UIView(frame:CGRect(x: 0,
                                        y: 0,
                                        width: UIScreen.main.bounds.size.width,
                                        height: UIScreen.main.bounds.size.height))
        introView.backgroundColor = clewGreen
        
        alignLabel = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*2/5, y: UIScreen.main.bounds.size.height/15, width: UIScreen.main.bounds.size.width*4/5, height: 200))
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
        
        descriptionLabel = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*2/5, y: UIScreen.main.bounds.size.height/5, width: UIScreen.main.bounds.size.width*4/5, height: 200))
        descriptionLabel.text = "Use the speed of the vibrations to determine whether the phone is in the correct orientation. The faster the vibration, the closer you are to proper orientation."
        descriptionLabel.textColor = UIColor.black
        descriptionLabel.backgroundColor = UIColor.white
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.layer.cornerRadius = 8.0
        descriptionLabel.layer.borderColor = UIColor.black.cgColor
        descriptionLabel.layer.borderWidth = 3.0
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.layer.masksToBounds = true
        descriptionLabel.font = UIFont.systemFont(ofSize:17.0)
        descriptionLabel.accessibilityLabel = "Use the speed of the vibrations to determine whether the phone is in the correct orientation. The faster the vibration, the closer you are to proper orientation."
        introView.addSubview(descriptionLabel)
        
        
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
        
        
        let gifView = UIImageView(image: UIImage(named: "phoneOrientationGIF1"))
        let gifImages = createImageArray(total: 9, imagePrefix: "phoneOrientationGIF")
        gifView.frame = CGRect(x: UIScreen.main.bounds.size.width/2 - 125, y: UIScreen.main.bounds.size.height*4/7, width: 250, height: 250)
        animateGIF(imageView: gifView, images: gifImages)
        introView.addSubview(gifView)
        
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        introView = createIntroView()
        self.view.addSubview(introView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
