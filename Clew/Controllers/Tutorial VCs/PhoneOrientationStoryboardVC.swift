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

class PhoneOrientationStoryboardVC: UIViewController {
    let tutorialViewController = TutorialViewController()
    let tipsAndWarningsViewController = TipsAndWarningsViewController()
    let viewController = ViewController()
    let phoneOrientationTrainingVC = PhoneOrientationTrainingVC()
    
    @IBOutlet weak var PhoneOrientationGIF: FLAnimatedImageView!
    
    /// Closes the viewcontroller
    @IBAction func CloseTips(_ sender: UIButton) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController?.dismiss(animated: false)
        appDelegate.window = UIWindow(frame:UIScreen.main.bounds)
        appDelegate.window?.makeKeyAndVisible()
        appDelegate.window?.rootViewController = ViewController()
    }
    
    @IBAction func SkipTutorial(_ sender: UIButton) {
//        tutorialViewController.state = .readyToRecordSingleRoute
//        tipsAndWarningsViewController.remove()
//        self.dismiss(animated: false, completion: nil)
        self.view.window!.rootViewController?.dismiss(animated: false, completion: nil)
       UIApplication.shared.keyWindow?.rootViewController = viewController
        tutorialViewController.state = .readyToRecordSingleRoute
        print("the state is", tutorialViewController.state)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imageData = try! Data(contentsOf: Bundle.main.url(forResource: "PhoneOrientation", withExtension: "gif")!)
        PhoneOrientationGIF.animatedImage = FLAnimatedImage(animatedGIFData: imageData)
    }
}
