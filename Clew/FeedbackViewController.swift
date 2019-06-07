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
    /// This is called when the view should close.  This method posts a notification "ClewPopoverDismissed" that can be listened to if an object needs to know that the view is being closed.
    @objc func closeFeedback() {
        dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: Notification.Name("ClewPopoverDismissed"), object: nil)
    }
    
}
