//
//  FeedbackViewController.swift
//  Clew
//
//  Created by Tim Novak on 6/7/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation

class FeedbackViewController : UIViewController, UITextViewDelegate, UIPopoverPresentationControllerDelegate, RecorderViewControllerDelegate {

    //MARK: Outlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var feedbackTextField: UITextView!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    //MARK: Private variables and constants
    ///sets an empty audiofile url
    var audio: URL? = nil
    ///creates a timer for keeping the scrollindicator shown
    var timerForShowScrollIndicator: Timer?
    
    //MARK: functions
    ///called when the popover is loaded
    override func viewDidLoad(){
        
        ///performs the default loading behavor of the superclass
        super.viewDidLoad()
        
        ///sets itself as the feedback field's delegate so it can clear the text in the feedback field upon editing
        feedbackTextField.delegate = self
        
        ///starts the timer which shows the scroll bar indicator
        startTimerForShowScrollIndicator()
        
        ///sets the title of the popover
        title = "\(NSLocalizedString("feedbackMenuTitle", comment: "this is the title on the feedback popover content"))"
        
        addTapGestureRecognizer()
    }
    
    func addTapGestureRecognizer() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }
    
    ///called when the voice recording is started
    func didStartRecording() {
    }
    
    ///called when the voice recording is finished
    func didFinishRecording(audioFileURL: URL) {
        audio = audioFileURL
    }
    
    ///handles the permissions of dealing with the recorder view
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
        
        ///if there is a properly formatted recorder view
        if segue.identifier == "recorderSubView", let recorderViewController  = segue.destination as? RecorderViewController {
            
            ///sets itself as the delegate for the recorder view controller
            recorderViewController.delegate = self
        }
    }

    //MARK: Actions

    
    ///This is a function which takes the feedback from the form and sends it to firebase. This function is called when the send feedback button is pressed
    @IBAction func sendFeedback(_ sender: UIButton) {
        
        ///creates an instance of the feedback logger so the functions inside can be used to send data to firebase
        let feedbackLogger = FeedbackLogger()
        
        ///retrieves the name from the form
        var name = nameTextField.text!
        
        ///performs input processing on the name to make sure that the user inputted a name
        if name == ""{
            ///if the user did not input a name the program just sets the value of the users 'name to a special empty value
            name = "NO NAME GIVEN"
        }
        
        ///retrieves the name from the form
        var number = phoneNumberTextField.text!
        ///performs input processing on the name to make sure that the user inputted a name
        if number == "" {
            ///if the user did not input a phone number it sets the value of the phone number to a special value
            number = "NONE"
        }
        
        ///retrieves the name from the form
        var email = emailTextField.text!
        if email == "" {
            ///if the user did not input an email it sets the value of the email to a special value
            email = "NONE"
        }
        
        ///retrieves the feedback message from the form
        var feedback = feedbackTextField.text!
        if feedback == "" {
            ///if the user did not input textual feedback it sets the value to a special empty value
            feedback = "NONE"
        }
        
        
        ///if the user properly included a name
        if audio != nil || feedback != "NONE"{
            ///retrieves the data from the feedback field and sends it to firebase using functions described in the feedback logger class. sucessvalue is a variable which stores a zero or one corresponding to the sucess of the upload (one means that there was a failure
            let sucessvalue = feedbackLogger.saveFeedback(name: name, message: feedback, country: countryTextField.text!, phone: number, email: email,audio: audio)
            
            ///performs check which will print different states to the console based on the sucess of uploading files to firebase
            switch sucessvalue{
            case 0:
                    print("Uploaded to Firebase Sucessfully")
            case 1:
                    print("Feedback failed to upload")
            case 2:
                    print("Audio failied to upload")
            default:
                    print("This shouldn't happen")
            }
            ///closes the popup
            closeFeedback()
            
        }else{
            
            //closes the popup without sending if the user did not enter any feedback
            closeFeedback()
            
        }

    }

    /// This is called when the view should close.  This method posts a notification "ClewPopoverDismissed" that can be listened to if an object needs to know that the view is being closed.
    @objc func closeFeedback() {
        dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: Notification.Name("ClewPopoverDismissed"), object: nil)
    }
    ///force shows the scroll bar indicator
    @objc func showScrollIndicator() {
        //if the scroll indicator is not curently shown play the animation of it expanding out
        UIView.animate(withDuration: 0.001) {
            //show the scroll indicator
            self.scrollView.flashScrollIndicators()
        }
    }
    
    ///handles the timer for the scroll indicator such that the scroll indicatyor is forced to be shown every .3 seconds
    func startTimerForShowScrollIndicator() {
        
        ///sets the timer to activate every .3 seconds and call showScrollIndicator function to force load the scroll indicator.
        self.timerForShowScrollIndicator = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(self.showScrollIndicator), userInfo: nil, repeats: true)
    }
    
}
