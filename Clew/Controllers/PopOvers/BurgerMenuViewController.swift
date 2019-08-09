//
//  BurgerMenuViewController.swift
//  Clew
//
//  Created by HK Rho on 8/6/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation

class BurgerMenuViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    /// Called when the user selects an element from the routes table. Different indexPath/tableViewCell being tapped triggers different popup that is indicated by the content of the UILabel inside the tableViewCell (check corresponding storyboard).
    ///
    /// - Parameters:
    ///   - tableView: the table view
    ///   - indexPath: the path that was selected
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected", indexPath)
        if indexPath == [0,0] {
            settingsButtonPressed()
        }
        if indexPath == [0,1] {
            helpButtonPressed()
        }
        if indexPath == [0,2] {
            feedbackButtonPressed()
        }
    }
    
    /// Called when the settings button is pressed.  This function will display the settings view (managed by SettingsViewController) as a popover.
    func settingsButtonPressed() {
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

    /// Called when the Feedback button is pressed.  This function will display the Feedback view (managed by FeedbackViewController) as a popover.
    func feedbackButtonPressed() {
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

        self.present(nav, animated: true, completion: nil)
    }
    
    /// Called when the help button is pressed.  This function will display the help view (managed by HelpViewController) as a popover.
    func helpButtonPressed() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "SettingsAndHelp", bundle: nil)
        let popoverContent = storyBoard.instantiateViewController(withIdentifier: "Help") as! HelpViewController
        popoverContent.preferredContentSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        let nav = UINavigationController(rootViewController: popoverContent)
        nav.modalPresentationStyle = .popover
        let popover = nav.popoverPresentationController
        popover?.delegate = self
        popover?.sourceView = self.view
        popover?.sourceRect = CGRect(x: 0, y: 0, width: 0, height: 0)
        popoverContent.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: popoverContent, action: #selector(popoverContent.doneWithHelp))

        self.present(nav, animated: true, completion: nil)
    }
    
    /// Dismisses the burger menu
    @objc func doneWithBurgerMenu() {
        dismiss(animated: true, completion: nil)
    }
}
