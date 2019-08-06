//
//  BurgerMenuViewController.swift
//  Clew
//
//  Created by SCOPE on 8/6/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation

class BurgerMenuViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var Settings: UIButton!
    @IBOutlet weak var Tutorial: UIControl!
    @IBOutlet weak var Feedback: UIControl!
    
    @IBOutlet weak var SettingsButton: UIButton!
    @IBOutlet weak var FeedbackButton: UIButton!
    
    @IBAction func settingsTapped(sender: UIView) {
        print("YO")
        let storyBoard: UIStoryboard = UIStoryboard(name: "SettingsAndHelp", bundle: nil)
        let popoverContent = storyBoard.instantiateViewController(withIdentifier: "Settings") as! SettingsViewController
        popoverContent.preferredContentSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        let nav = UINavigationController(rootViewController: popoverContent)
        nav.modalPresentationStyle = .popover
        let popover = nav.popoverPresentationController
        popover?.delegate = self
        popover?.sourceView = self.view
        popover?.sourceRect = CGRect(x: 0, y: UIConstants.settingsAndHelpFrameHeight/2, width: 0,height: 0)
        
        popoverContent.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: popoverContent, action: #selector(popoverContent.doneWithSettings))
        
        
        self.present(nav, animated: true, completion: nil)
    }
    
    @IBAction func feedbackButtonTapped(sender: UIButton) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "SettingsAndHelp", bundle: nil)
        let popoverContent = storyBoard.instantiateViewController(withIdentifier: "Feedback") as! FeedbackViewController
        popoverContent.preferredContentSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        let nav = UINavigationController(rootViewController: popoverContent)
        nav.modalPresentationStyle = .popover
        let popover = nav.popoverPresentationController
        popover?.delegate = self
        popover?.sourceView = self.view
        popover?.sourceRect = CGRect(x: 0,
                                     y: UIConstants.settingsAndHelpFrameHeight/2,
                                     width: 0,
                                     height: 0)
        popoverContent.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: popoverContent, action: #selector(popoverContent.closeFeedback))
//        suppressTrackingWarnings = true
        self.present(nav, animated: true, completion: nil)
    }
    
}
