//
//  FirebaseInterface.swift
//  Clew
//
//  Created by occamlab on 6/28/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import Foundation
#if !APPCLIP
import Firebase
import FirebaseDatabase
import FirebaseAuth
#endif

class FirebaseInterface {
    
    /// The conection to the Firebase real-time database
    //var databaseHandle = Database.database()
    /// Observe the relevant Firebase paths to handle any dynamic reconfiguration requests (this is currently not used in the app store version of Clew)
    func setupFirebaseObservers(vc: ViewController) {
        #if !APPCLIP
        let responsePathRef = Database.database().reference(withPath: "config/" + UIDevice.current.identifierForVendor!.uuidString)
        responsePathRef.observe(.childChanged) { (snapshot) -> Void in
            vc.handleNewConfig(snapshot: snapshot)
        }
        responsePathRef.observe(.childAdded) { (snapshot) -> Void in
            vc.handleNewConfig(snapshot: snapshot)
        }
        if let currentUID = Auth.auth().currentUser?.uid {
            Database.database().reference(withPath: "\(currentUID)").child("surveys").getData() { (error, snapshot) in
                if let error = error {
                    print("Error getting data \(error)")
                }
                else if snapshot.exists(), let userDict = snapshot.value as? [String : AnyObject] {
                    for (surveyName, surveyInfo) in userDict {
                        if let surveyInfoDict = surveyInfo as? [String : AnyObject], let lastSurveyTime = surveyInfoDict["lastSurveyTime"] as? Double {
                            vc.lastSurveyTime[surveyName] = lastSurveyTime
                        }
                    }
                }
                else {
                    print("No data available")
                }
            }
        }
        #endif
    }
}
