//
//  BurgerMenuViewController.swift
//  Clew
//
//  Created by HK Rho on 8/6/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import SwiftUI
import InAppSettingsKit

class BurgerMenuViewController: UITableViewController, UIPopoverPresentationControllerDelegate, IASKSettingsDelegate {
    var tutorialHostingController: UIHostingController<TutorialTestView>?
    var siriHostingController: UIHostingController<NavigationView<SiriWalkthrough>>?
    var visualAlignmentHostingController: UIHostingController<NavigationView<VisualAnchorPointPractice>>?


    func settingsViewControllerDidEnd(_ settingsViewController: IASKAppSettingsViewController) {
        settingsViewController.dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: Notification.Name("ClewPopoverDismissed"), object: nil)
    }
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(forName: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil, queue: nil) { (notification) -> Void in
            self.tutorialHostingController?.dismiss(animated: true)
            self.siriHostingController?.dismiss(animated: true)
            self.visualAlignmentHostingController?.dismiss(animated: true)
        }
    }
    
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
//        if indexPath == [0,1] {
//            helpButtonPressed()
//        }
        if indexPath == [0,1] {
            tutorialButtonPressed()
        }
        if indexPath == [0,2] {
            siriShortcutsButtonPressed()
        }
        if indexPath == [0,3] {
            visualAlignmentTutorialButtonPressed()
        }
        if indexPath == [0,4] {
            feedbackButtonPressed()
        }
    }
    
    /// Called when the settings button is pressed.  This function will display the settings view (managed by SettingsViewController) as a popover.
    func settingsButtonPressed() {
        let popoverContent = IASKAppSettingsViewController()
        popoverContent.preferredContentSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        popoverContent.delegate = self
        let nav = UINavigationController(rootViewController: popoverContent)
        nav.modalPresentationStyle = .popover
        let popover = nav.popoverPresentationController
        popover?.delegate = self
        popover?.sourceView = self.view
        popover?.sourceRect = CGRect(x: 0, y: UIConstants.settingsAndHelpFrameHeight/2, width: 0,height: 0)
        NotificationCenter.default.post(name: Notification.Name("ClewPopoverDisplayed"), object: nil)
        
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
        NotificationCenter.default.post(name: Notification.Name("ClewPopoverDisplayed"), object: nil)

        self.present(nav, animated: true, completion: nil)
    }
    
    func tutorialButtonPressed() {
        let tutorialView = TutorialTestView()
        ShowTutorialPage.shared.confineToSection = false
        tutorialHostingController = UIHostingController(rootView: tutorialView)
        self.present(tutorialHostingController!, animated: true, completion: nil)
    }
    
    func siriShortcutsButtonPressed() {
        let siriView = NavigationView {
            SiriWalkthrough()
        }
        siriHostingController = UIHostingController(rootView: siriView)
        NotificationCenter.default.post(name: Notification.Name("ClewPopoverDisplayed"), object: nil)
        ShowTutorialPage.shared.confineToSection = true
        self.present(siriHostingController!, animated: true)
    }
    
    func visualAlignmentTutorialButtonPressed() {
        let visualAlignmentTutorial = NavigationView {
            VisualAnchorPointPractice()
        }
        visualAlignmentHostingController = UIHostingController(rootView: visualAlignmentTutorial)
        NotificationCenter.default.post(name: Notification.Name("ClewPopoverDisplayed"), object: nil)
        ShowTutorialPage.shared.confineToSection = true
        self.present(visualAlignmentHostingController!, animated: true)
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
        NotificationCenter.default.post(name: Notification.Name("ClewPopoverDisplayed"), object: nil)

        self.present(nav, animated: true, completion: nil)
    }
    
    /// Dismisses the burger menu
    @objc func doneWithBurgerMenu() {
        dismiss(animated: true, completion: nil)
    }
}
