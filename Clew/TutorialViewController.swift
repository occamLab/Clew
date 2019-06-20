//
//  TutorialViewController.swift
//  Clew Dev
//
//  Created by occamlab on 6/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit


class TutorialViewController: UIViewController {
    
    @IBAction func CloseTips(_ sender: UIButton) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController?.dismiss(animated: true)
        appDelegate.window?.rootViewController = ViewController()
        print("hi")
    }
    
}
