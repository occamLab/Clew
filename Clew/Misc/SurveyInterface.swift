//
//  SurveyInterface.swift
//  Clew
//
//  Created by occamlab on 6/28/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import StoreKit
#if !APPCLIP
import Firebase
import FirebaseDatabase
import FirebaseAuth
#endif


class SurveyInterface {
    
    
    /// send log data for an successful route navigation (thumbs up)
    @objc func sendLogData(vc: ViewController) {
        sendLogDataHelper(pathStatus: true, vc: vc)
    }
    
    /// Presents a survey to the user as a popover.  The method will check to see if it has been sufficiently long since the user was last asked to fill out this survey before displaying the survey.
    /// - Parameters:
    ///   - mode: type of survey, accepts "onAppLaunch" and "afterRoute" which correspond to the value of the "currentAppLaunchSurvey" and "currentAfterRouteSurvey" keys respectively located in the Firebase Realtime Database at surveys/
    ///   - logFileURLs: this list of URLs will be added to the survey response JSON file if the user winds up submitting the survey.  This makes it easier to link together feedback in the survey with data logs.
    func presentSurveyIfIntervalHasPassed(mode: String, logFileURLs: [String], vc: ViewController) {
        
        #if !APPCLIP
        
        var surveyToTrigger: String = ""
        
        switch mode {
            case "onAppLaunch":
                surveyToTrigger = FirebaseFeedbackSurveyModel.shared.currentAppLaunchSurvey
            case "afterRoute":
                surveyToTrigger = FirebaseFeedbackSurveyModel.shared.currentAfterRouteSurvey
            default:
                surveyToTrigger = "defaultSurvey"
        }
        
        print(surveyToTrigger)
        
        if FirebaseFeedbackSurveyModel.shared.questions[surveyToTrigger] == nil {
            return
        }
        if vc.lastSurveyTime[surveyToTrigger] == nil || -Date(timeIntervalSince1970: vc.lastSurveyTime[surveyToTrigger]!).timeIntervalSinceNow >= FirebaseFeedbackSurveyModel.shared.intervals[surveyToTrigger] ?? 0.0 {
            vc.lastSurveyTime[surveyToTrigger] = Date().timeIntervalSince1970
            
            if let currentUID = Auth.auth().currentUser?.uid {
                let surveyInfo = ["lastSurveyTime": vc.lastSurveyTime[surveyToTrigger]!]
                Database.database().reference(withPath: "\(currentUID)/surveys/\(surveyToTrigger)").updateChildValues(surveyInfo)
            }
            
            let swiftUIView = FirebaseFeedbackSurvey(feedbackSurveyName: surveyToTrigger, logFileURLs: logFileURLs)
            vc.hostingController = UISurveyHostingController(rootView: swiftUIView)
            NotificationCenter.default.post(name: Notification.Name("ClewPopoverDisplayed"), object: nil)
            vc.present(vc.hostingController!, animated: true, completion: nil)
        }
        #endif
    }
    
    /// Presents a survey to the user as a popover.  The method will check to see if it has been sufficiently long since the user was last asked to fill out this survey before displaying the survey.
    /// - Parameters:
    ///   - surveyToTrigger: this is the name of the survey, which should be described in the realtime database under "/surveys/{surveyToTrigger}"
    ///   - logFileURLs: this list of URLs will be added to the survey response JSON file if the user winds up submitting the survey.  This makes it easier to link together feedback in the survey with data logs.
    func presentSurveyIfIntervalHasPassedWithSurveyKey(surveyToTrigger: String, logFileURLs: [String], vc: ViewController) {
        #if !APPCLIP
        if FirebaseFeedbackSurveyModel.shared.questions[surveyToTrigger] == nil {
            return
        }
        if vc.lastSurveyTime[surveyToTrigger] == nil || -Date(timeIntervalSince1970: vc.lastSurveyTime[surveyToTrigger]!).timeIntervalSinceNow >= FirebaseFeedbackSurveyModel.shared.intervals[surveyToTrigger] ?? 0.0 {
            vc.lastSurveyTime[surveyToTrigger] = Date().timeIntervalSince1970
            
            if let currentUID = Auth.auth().currentUser?.uid {
                let surveyInfo = ["lastSurveyTime": vc.lastSurveyTime[surveyToTrigger]!]
                Database.database().reference(withPath: "\(currentUID)/surveys/\(surveyToTrigger)").updateChildValues(surveyInfo)
            }
            
            let swiftUIView = FirebaseFeedbackSurvey(feedbackSurveyName: surveyToTrigger, logFileURLs: logFileURLs)
            vc.hostingController = UISurveyHostingController(rootView: swiftUIView)
            NotificationCenter.default.post(name: Notification.Name("ClewPopoverDisplayed"), object: nil)
            vc.present(vc.hostingController!, animated: true, completion: nil)
        }
        #endif
    }
    
    func sendLogDataHelper(pathStatus: Bool?, announceArrival: Bool = false, vc: ViewController) {
        // send success log data to Firebase
        let logFileURLs = vc.logger.compileLogData(pathStatus)
        vc.logger.resetStateSequenceLog()
        vc.state = .mainScreen(announceArrival: announceArrival)
        if vc.sendLogs {
            // do this in a little while to give it time to announce arrival
            DispatchQueue.main.asyncAfter(deadline: .now() + (announceArrival ? 3 : 1)) {
                self.presentSurveyIfIntervalHasPassed(mode: "afterRoute", logFileURLs: logFileURLs, vc: vc)
            }
        }

    }
}


