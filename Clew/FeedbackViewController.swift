//
//  FeedbackViewController.swift
//  Clew
//
//  Created by Tim Novak on 6/7/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation

class FeedbackViewController : UIViewController {
    
    override func viewDidLoad(){
        
        title = "Clew Feedback"
        
    }
    
    //MARK: Outlets
    //MARK: Actions
    //This is a function which takes the feedback from the form an sends it to firebase then it closes the popup window
    @IBAction func sendFeedback(_ sender: UIButton) {
        
        let feedbackLogger : FeedbackLogger
        //TODO retrieve form data
        
        //TODO send data to firebase
        let sucessvalue = feedbackLogger.saveFeedback(name: <#T##String#>, message: <#T##String#>, country: <#T##String?#>)
        
        //closes the popup
        closeFeedback()
    }

    /// This is called when the view should close.  This method posts a notification "ClewPopoverDismissed" that can be listened to if an object needs to know that the view is being closed.
    @objc func closeFeedback() {
        dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: Notification.Name("ClewPopoverDismissed"), object: nil)
    }
    
}
