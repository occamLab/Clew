//
//  FeedbackLogger.swift
//  Clew
//
//  Created by tad on 6/7/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage


class FeedbackLogger {

    //MARK: private constants and variables
    ///creates a reference to the feedback folder within firebase
    let feedbackRef = Storage.storage().reference().child("feedback")
    ///creates a referance for the file path of the audiofile
    let uniqueID = UUID().uuidString
    
    //MARK: functions
    ///a function which saves the feedback and publishes it to the firebase website
    func writeFeedbackToFirebase(name : String, data : Data, audio audioFileURL : URL?) -> Int {
        
        ///creates an integer which stores the return value of the function (0 for no errors and 1 for a failed build)
        var returnValue = 0
        
        ///creates a reference to the location we want to save the new file
        let fileRef = feedbackRef.child("\(name)_\(uniqueID)_metadata.json")
        
        let fileType = StorageMetadata()
        fileType.contentType = "application/json"
        
        /// Upload the file to the path defined by fileRef then checks for any errors
        let _ = fileRef.putData(data, metadata: fileType){ (metadata, error) in
            guard metadata != nil else {
                /// prints an errorstatement to the console
                print("could not upload feedback to firebase", error!.localizedDescription)
                ///sets the return value equal to 1 if an error ocurred
                returnValue = 1
                ///quits the conditional
                return
            }
        }
        
        //MARK: Audio Recording to Firebase
        /// if there was an audio note recording attached to the feedback submission then send it to firebase as well
        if audioFileURL != nil{
            
            ///stores a reference to the aidiofile URL
            let audioref = "\(name)_Recording_\(uniqueID).wav"
            
            if let data = try? Data(contentsOf: audioFileURL!) {
                ///sets the file type to the proper audio file
                let fileType = StorageMetadata()
                fileType.contentType = "audio/wav"
                
                let fileRef = feedbackRef.child(audioref)
                let _ = fileRef.putData(data, metadata: fileType){ (metadata, error) in
                    guard metadata != nil else {
                        returnValue = 2
                        /// prints an errorstatement to the console
                        print("could not upload audio recording to firebase", error!.localizedDescription)
                        ///quits the conditional
                        return
                    }
                }
            }
        }
        
        
        return returnValue
    }
    
    ///takes in all the different pieces of data and combines them into a properly formatted string of type Data
    func makeData(name: String, message: String, country inputCountry: String?, phone: String, email: String,isAudio: Bool) -> Data? {
        
        var country: String = "NONE"
        
        ///performs input processing on the country Field
        if inputCountry == ""{
            country = "NONE"
        }else{
            country = inputCountry!
        }
        
        ///sets the default state to not have an audio file
        var audioData = "NONE"
        
        ///performs input processing on the audio data to say whether or not there is an audio file
        if isAudio {
            ///sets the address of the audio file if there is one
            audioData = "\(name)_Recording_\(uniqueID).wav"
        }
        
        ///places the data into a dictionary to be formatted into JSON later
        let body: [String : Any] = ["FeedbackDate": "\(Date().description(with: .current))",
                                    "PhoneNumber": phone,
                                    "Email": email,
                                    "Name": name,
                                    "Country": country,
                                    "Message": message,
                                    "AppInstanceID": Analytics.appInstanceID(),
                                    "AudioFileName": audioData]
        do {
            ///converts the data into JSON
            let data = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            ///returns the data properly combined and formatted
            return data
        }catch {
        print(error.localizedDescription)
        }
        return nil
    }
    ///combines the information together and saves a file to Firebase containing the user's feedback
    func saveFeedback(name: String, message: String, country: String?, phone: String, email: String,audio: URL?) -> Int{
        ///calls the functions to create the properly formatted data and upload the result to firebase
        if audio == nil {
            ///if there is no audio log tell the program to notate theat in the log
            return writeFeedbackToFirebase(name: name, data: makeData(name: name, message: message, country: country, phone: phone, email: email, isAudio: false)!,audio: audio)
        }else{
            ///if there is an audio file tell the program to notate that in the log
            return writeFeedbackToFirebase(name: name, data: makeData(name: name, message: message, country: country, phone: phone, email: email, isAudio: true)!,audio: audio)
        }
        
    }
}
