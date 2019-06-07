//
//  FeedbackLogger.swift
//  Clew
//
//  Created by tad on 6/7/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import Firebase


class FeedbackLogger {

    //creates a reference to the feedback folder within firebase
    let feedbackRef = Storage.storage().reference().child("feedback")
    
    //a function which saves the feedback and publishis it to the firebase website
    func writeFeedbackToFirebase(name : String, data : Data) -> Int {
        
        //creates a reference to the location we want to save the new file
        let fileRef = feedbackRef.child("\(name)")
        
        
        // Upload the file to the path defined by fileRef then checks for any errors
        let uploadTask = fileRef.putData(data, metadata: nil){ (metadata, error) in
            guard metadata != nil else {
                // prints an errorstatement to the console
                print("could not upload feedback to firebase", error!.localizedDescription)
                //quits the conditional
                return
            }
        }
        return 0
    }
    
    //takes in all the different pieces of data and combines them into a properly formatted string of type Data
    func makeData(name: String, message: String, country: String?) -> Data {
        
        //combines all of the input strings into one data string of the proper formatting
        let data = "DATE: \(Date().description(with: .current)) \nNAME: \(name) \nCOUNTRY: \(country!) \nMESSAGE: \(message)"
        
        //converts the data into a NSData type so it can be pushed to firebase
        let feedbackNSString = data as NSString
        let feedbackData = feedbackNSString.data(using: String.Encoding.utf8.rawValue)!
        
        //returns the data properly combined and formatted
        return feedbackData
    }
    //combines the information together and saves a file to Firebase containing the user's feedback
    func saveFeedback(name: String, message: String, country: String?) -> Int{
        //calls the functions to create the properly formatted data and upload the result to firebase
        return writeFeedbackToFirebase(name: name, data: makeData(name: name, message: message, country: country))
    }
}
