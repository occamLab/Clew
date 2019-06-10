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
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var feedbackTextField: UITextView!
    
    //MARK: Actions
    //This is a function which takes the feedback from the form an sends it to firebase then it closes the popup window
    @IBAction func sendFeedback(_ sender: UIButton) {
        //creates an instance of the feedback logger so the functions inside can be used to send data to firebase
        let feedbackLogger = FeedbackLogger()
        //retrieves the data from the feedback field and sends it to firebase using functions described in the feedback logger class. sucessvalue is a variable which stores a zero or one corresponding to the sucess of the upload (one means that there was a failure
        let sucessvalue = feedbackLogger.saveFeedback(name: nameTextField.text!, message: feedbackTextField.text!, country: countryTextField.text!)
        
        //closes the popup
        closeFeedback()
    }

    /// This is called when the view should close.  This method posts a notification "ClewPopoverDismissed" that can be listened to if an object needs to know that the view is being closed.
    @objc func closeFeedback() {
        dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: Notification.Name("ClewPopoverDismissed"), object: nil)
    }
    
}
