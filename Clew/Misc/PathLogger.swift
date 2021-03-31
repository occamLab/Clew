//
//  PathLogger.swift
//  Clew
//
//  Created by Paul Ruvolo on 5/3/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage
import SceneKit

//FirebaseApp.configure()
//Analytics.

/// A class to handle logging app usage data
class PathLogger {
    /// A handle to the Firebase storage
    let storageBaseRef = Storage.storage().reference()

    /// path data taken during RECORDPATH - [[1x16 transform matrix]]
    var pathData: LinkedList<[Float]> = []
    /// time stamps for pathData
    var pathDataTime: LinkedList<Double> = []
    /// path data taken during NAVIGATEPATH - [[1x16 transform matrix]]
    var navigationData: LinkedList<[Float]> = []
    /// time stamps for navigationData
    var navigationDataTime: LinkedList<Double> = []
    /// timer to use for logging
    var dataTimer = Date()
    /// list of tracking errors ["InsufficientFeatures", "ExcessiveMotion"]
    var trackingErrorData: LinkedList<String> = []
    /// time stamp of tracking error
    var trackingErrorTime: LinkedList<Double> = []
    /// tracking phase - true: recording, false: navigation
    var trackingErrorPhase: LinkedList<Bool> = []

    /// timer for logging state transitions
    var stateTransitionLogTimer = Date()
    /// all state transitions the app went through
    var stateSequence: LinkedList<String> = []
    /// time stamp of state transitions
    var stateSequenceTime: LinkedList<Double> = []

    /// description data during NAVIGATION
    var speechData: LinkedList<String> = []
    /// time stamp for speechData
    var speechDataTime: LinkedList<Double> = []
    /// list of keypoints - [[(LocationInfo)x, y, z, yaw]]
    var keypointData: LinkedList<Array<Any>> = []
    
    /// language used in recording
//    var langData: [String] = []
//    let langData = Locale.preferredLanguages[0]
    func currentLocale() -> String {
        let preferredLanguage = Locale.preferredLanguages[0] as String
        print(preferredLanguage)
        return preferredLanguage
    }
    
    /// Add the specified state transition to the log.
    ///
    /// - Parameter newState: the new state of the app
    func logStateTransition(newState: AppState) {
        stateSequenceTime.append(-stateTransitionLogTimer.timeIntervalSinceNow)
        stateSequence.append(newState.rawValue)
    }
    
    /// Log an utterance issued by the app.
    ///
    /// - Parameter utterance: the utterance that was delivered by the app (either via an `AVAudioSession` or through VoiceOver)
    func logSpeech(utterance: String) {
        speechData.append(utterance)
        speechDataTime.append(-dataTimer.timeIntervalSinceNow)
    }
    
    /// Log a tracking error from the app.
    ///
    /// - Parameters:
    ///   - isRecordingPhase: true if the error is associated with the recording phase, false if it is associated with the navigation phase
    ///   - trackingError: <#trackingError description#>
    func logTrackingError(isRecordingPhase: Bool, trackingError: String) {
        trackingErrorPhase.append(isRecordingPhase)
        trackingErrorTime.append(-dataTimer.timeIntervalSinceNow)
        trackingErrorData.append(trackingError)
    }
    
    /// Log a transformation matrix
    ///
    /// - Parameters:
    ///   - state: the app's state (this helps determine whether to log the transformation as part of the path recording or navigation data)
    ///   - scn: the 4x4 matrix that encodes the position and orientation of the phone
    func logTransformMatrix(state: AppState, scn: SCNMatrix4) {
        let logTime = -dataTimer.timeIntervalSinceNow
        let logMatrix = [scn.m11, scn.m12, scn.m13, scn.m14,
                         scn.m21, scn.m22, scn.m23, scn.m24,
                         scn.m31, scn.m32, scn.m33, scn.m34,
                         scn.m41, scn.m42, scn.m43, scn.m44]
        if case .navigatingRoute = state {
            navigationData.append(logMatrix)
            navigationDataTime.append(logTime)
        } else {
            pathData.append(logMatrix)
            pathDataTime.append(logTime)
        }
    }

    /// Log the keypoints of a route.
    ///
    /// - Parameter keypoints: the keypoints of the route being navigated
    func logKeypoints(keypoints: [KeypointInfo]) {
        keypointData = []
        for keypoint in keypoints {
            let data = [keypoint.location.x, keypoint.location.y, keypoint.location.z, keypoint.location.yaw]
            keypointData.append(data)
        }
    }
    
    /// Log language used by user in recording.
    //
    ///
//    func logLang() {
//        let langData = Locale.preferredLanguages[0]
//        return langData
//    }
    
    
    /// Reset the logging variables having to do with path recording or ones that are shared between path recording / path navigating
    func resetPathLog() {
        // reset all logging related variables for the path
        pathData = []
        pathDataTime = []
        dataTimer = Date()
        
        trackingErrorData = []
        trackingErrorTime = []
        trackingErrorPhase = []
    }
    
    /// Reset the logging variables having to do with path navigation.
    func resetNavigationLog() {
        // clear any old log variables
        navigationData = []
        navigationDataTime = []
        speechData = []
        speechDataTime = []
        dataTimer = Date()
    }
    
    /// Reset the logging variables having to do with state sequence tracking
    func resetStateSequenceLog() {
        // reset log variables that aren't tied to path recording or navigation
        stateSequence = []
        stateSequenceTime = []
    }
    
    /// Compile log data and send it to the cloud
    ///
    /// - Parameter debug: true if the route was unsuccessful (useful for debugging) and false if the route was successful
    func compileLogData(_ debug: Bool) {
        // compile log data
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let pathDate = dateFormatter.string(from: date)
        let pathID = UIDevice.current.identifierForVendor!.uuidString + dateFormatter.string(from: date)
        let userId = Analytics.appInstanceID()
        
        sendMetaData(pathDate, pathID+"-0", userId, debug)
        sendPathData(pathID, userId)
    }
    
    /// Send the meta data log to the cloud
    ///
    /// - Parameters:
    ///   - pathDate: the path date
    ///   - pathID: the path id
    ///   - userId: the user id
    ///   - debug: true if the route was unsuccessful (useful for debugging) and false if the route was successful
    func sendMetaData(_ pathDate: String, _ pathID: String, _ userId: String, _ debug: Bool) {
        let pathType: String
        if(debug) {
            pathType = "debug"
        } else {
            pathType = "success"
        }
        
        let body: [String : Any] = ["userId": userId,
                                    "PathID": pathID,
                                    "PathDate": pathDate,
                                    "PathType": pathType,
                                    "keypointData": Array(keypointData),
                                    "trackingErrorPhase": Array(trackingErrorPhase),
                                    "trackingErrorTime": Array(trackingErrorTime),
                                    "trackingErrorData": Array(trackingErrorData),
                                    "stateSequence": Array(stateSequence),
                                    "stateSequenceTime": Array(stateSequenceTime)]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            // here "jsonData" is the dictionary encoded in JSON data
            // TODO CHANGE THIS FILE NAME
            let storageRef = storageBaseRef.child("path" + "_metadata.json")
            let fileType = StorageMetadata()
            fileType.contentType = "application/json"
            // upload the image to Firebase storage and setup auto snapshotting
            storageRef.putData(jsonData, metadata: fileType) { (metadata, error) in
                guard metadata != nil else {
                    // Uh-oh, an error occurred!
                    print("could not upload meta data to firebase", error!.localizedDescription)
                    return
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Send the path data log to the cloud.
    ///
    /// - Parameters:
    ///   - pathID: the id of the path
    ///   - userId: the user id
    func sendPathData(_ pathID: String, _ userId: String) {
        let body: [String : Any] = ["userId": userId,
                                    "PathID": pathID,
                                    "PathDate": "0",
                                    "PathType": "0",
                                    "PathData": Array(pathData),
                                    "pathDataTime": Array(pathDataTime),
                                    "navigationData": Array(navigationData),
                                    "navigationDataTime": Array(navigationDataTime),
                                    "speechData": Array(speechData),
                                    "speechDataTime": Array(speechDataTime)]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            // here "jsonData" is the dictionary encoded as a JSON
            // TODO CHANGE THIS FILE NAME
            let storageRef = storageBaseRef.child("path_data.json")
            let fileType = StorageMetadata()
            fileType.contentType = "application/json"
            // upload the image to Firebase storage and setup auto snapshotting
            storageRef.putData(jsonData, metadata: fileType) { (metadata, error) in
                guard metadata != nil else {
                    // Uh-oh, an error occurred!
                    print("could not upload path data to firebase", error!.localizedDescription)
                    return
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

