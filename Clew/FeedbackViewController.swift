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
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    //MARK: Actions
    //This is a function which takes the feedback from the form and sends it to firebase. This function is called when the send feedback button is pressed
    @IBAction func sendFeedback(_ sender: UIButton) {
        
        //creates an instance of the feedback logger so the functions inside can be used to send data to firebase
        let feedbackLogger = FeedbackLogger()
        
        //retrieves the name from the form
        var name = nameTextField.text!
        //performs input processing on the name to make sure that the user inputted a name
        if name == "Name" || name == "Please enter a name"{
            //if the user did not input a name it prompts them to do so and sets the value of the name to a special value so the feedback request is not sent
            nameTextField.text = "Please enter a name"
            name = "NONE"
        }
        
        //retrieves the name from the form
        var number = phoneNumberTextField.text!
        //performs input processing on the name to make sure that the user inputted a name
        if number == "Phone Number (optional)" {
            //if the user did not input a phone number it sets the value of the ohone number to a special value
            number = "NONE"
        }
        
        //retrieves the name from the form
        var email = emailTextField.text!
        if email == "Email (optional)" {
            //if the user did not input an email it sets the value of the ohone number to a special value
            email = "NONE"
        }
        
        var feedback = feedbackTextField.text!
        
        if feedback == "Enter Feedback"{
            //if the user did not input any feedback the program prompts them to do so and sets the value of theor feedback to a special value so that the file will not get sent.
            feedbackTextField.text = "Please enter feedback on Clew"
            feedback = "NONE"
        }
        //if the user insists on sending an empty feedback message close the popover as you normally would to give the user the impression that they sent it however do not actually send the message so as to minimize the number of invalid responses saved to the database
        if feedback == "Please enter feedback on Clew"{
            closeFeedback()
        }
        
        //if the feedback was entered properly
        if feedback != "NONE" && name != "NONE" && feedback != "Please enter feedback on Clew"{
            //retrieves the data from the feedback field and sends it to firebase using functions described in the feedback logger class. sucessvalue is a variable which stores a zero or one corresponding to the sucess of the upload (one means that there was a failure
            let sucessvalue = feedbackLogger.saveFeedback(name: name, message: feedback, country: countryTextField.text!, phone: number, email: email)
            
            //closes the popup
            closeFeedback()
        }

    }

    /// This is called when the view should close.  This method posts a notification "ClewPopoverDismissed" that can be listened to if an object needs to know that the view is being closed.
    @objc func closeFeedback() {
        dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: Notification.Name("ClewPopoverDismissed"), object: nil)
    }
    
}
