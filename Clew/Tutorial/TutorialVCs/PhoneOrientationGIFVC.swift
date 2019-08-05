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
    var instructionLabel: UILabel!
    var gotItButton: UIButton!
    var skipButton: UIButton!
    var gifView: UIImageView?
    var gifImages: [UIImage]! = []
    var clewGreen = UIColor(red: 103/255, green: 188/255, blue: 71/255, alpha: 1.0)
    
    
    /// function that creates an array of images
    /// used for putting all the frames that consist a gif into an array
    func createImageArray(total: Int, imagePrefix: String) -> [UIImage] {
        var imageArray: [UIImage] = []

        for imageCount in 1..<total {
            let imageName = "\(imagePrefix)\(imageCount).png"
            let image = UIImage(named: imageName)
            imageArray.append(image!)
        }
        return imageArray
    }
    
    /// function that animates an array of images
    func animateGIF(imageView: UIImageView, images: [UIImage]) {
        imageView.animationImages = images
        imageView.animationDuration = 4.0
        imageView.startAnimating()
    }
    
    /// function that creates a view that explains how to complete the phone orientation part of the tutorial
    func createIntroView() -> UIView {
        // initialize view where all the labels and buttons will be added as a subview
        introView = UIView(frame:CGRect(x: 0,
                                        y: 0,
                                        width: UIScreen.main.bounds.size.width,
                                        height: UIScreen.main.bounds.size.height))
        introView.backgroundColor = clewGreen
        
        // Align Your Phone
        alignLabel = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*2/5, y: UIScreen.main.bounds.size.height/23, width: UIScreen.main.bounds.size.width*4/5, height: 200))
        alignLabel.text = NSLocalizedString("ALIGN YOUR PHONE!", comment: "Instructs user to align their phone.")
        alignLabel.textColor = UIColor.white
        alignLabel.textAlignment = .center
        alignLabel.numberOfLines = 0
        alignLabel.lineBreakMode = .byWordWrapping
        alignLabel.layer.masksToBounds = true
        alignLabel.font = UIFont.systemFont(ofSize: 35.0)
        alignLabel.isAccessibilityElement = true
        alignLabel.accessibilityLabel = "ALIGN YOUR PHONE!"
        introView.addSubview(alignLabel)
        
        // Detailed Instruction
        instructionLabel = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIScreen.main.bounds.size.width*2/5, y: UIScreen.main.bounds.size.height*1/3.9, width: UIScreen.main.bounds.size.width*4/5, height: 130))
        instructionLabel.text = NSLocalizedString("Use the speed of the vibrations to determine whether the phone is in the correct orientation. The faster the vibration, the closer you are to proper orientation.", comment: "Detailed description for phone orientation section of the tutorial.")
        instructionLabel.textColor = UIColor.black
        instructionLabel.backgroundColor = UIColor.white
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.layer.cornerRadius = 8.0
        instructionLabel.layer.borderColor = UIColor.black.cgColor
        instructionLabel.layer.borderWidth = 3.0
        instructionLabel.lineBreakMode = .byWordWrapping
        instructionLabel.layer.masksToBounds = true
        instructionLabel.font = UIFont.systemFont(ofSize:17.0)
        instructionLabel.accessibilityLabel = "Use the speed of the vibrations to determine whether the phone is in the correct orientation. The faster the vibration, the closer you are to proper orientation."
        introView.addSubview(instructionLabel)
        
        // GotIt Button
        gotItButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - UIConstants.buttonFrameWidth/6,
                                             y: UIConstants.yOriginOfSettingsAndHelpButton,
                                             width: UIConstants.buttonFrameWidth/3,
                                             height: UIConstants.buttonFrameWidth/5))
        gotItButton.isAccessibilityElement = true
        gotItButton.titleLabel?.font = UIFont.systemFont(ofSize: 24.0)
        gotItButton.accessibilityLabel = NSLocalizedString("Got It", comment: "Got It")
        gotItButton.setImage(UIImage(named: "GotIt"), for: .normal)
        gotItButton.addTarget(self, action: #selector(gotItButtonAction), for: .touchUpInside)
        introView.addSubview(gotItButton)
        
        // Skip Button
        skipButton = SkipButton().createSkipButton(buttonAction:
            #selector(skipButtonAction))
        introView.addSubview(skipButton)
        
        // GIF
        let gifView = UIImageView(image: UIImage(named: "phoneOrientationGIF1"))
        let gifImages = createImageArray(total: 9, imagePrefix: "phoneOrientationGIF")
        gifView.frame = CGRect(x: UIScreen.main.bounds.size.width/2 - 125, y: UIScreen.main.bounds.size.height*5/10.9, width: 250, height: 250)
        animateGIF(imageView: gifView, images: gifImages)
        introView.addSubview(gifView)
        
        return introView
    }
    
    
    /// function that creates alerts for the skip button
    func skipNavigationProcesses() {
        let alert = UIAlertController(title: NSLocalizedString("Are you sure?", comment: "Are you sure?"),
                                      message: NSLocalizedString("If you exit this process right now, you won't be orienting your phone.", comment: "If you exit this process right now, you won't be orienting your phone."),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Skip this part of the tutorial.", comment: "Skip this part of the tutorial."), style: .default, handler: { action -> Void in
            // proceed to readyToRecordSingleRoute state
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            (appDelegate.window?.rootViewController as? ViewController)?.tutorialViewController.state = .readyToRecordSingleRoute
        }
        ))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .default, handler: { action -> Void in
            // nothing to do, just stay on the page
        }
        ))
        self.present(alert, animated: true, completion: nil)
    }
    

    // Callback function for when the 'skip' button is tapped
    @objc func skipButtonAction(sender: UIButton!) {
        skipNavigationProcesses()
    }
    
    // Callback function for when the 'got it" button is tapped
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
