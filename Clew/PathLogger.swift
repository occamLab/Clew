//
//  PathLogger.swift
//  Clew
//
//  Created by Paul Ruvolo on 5/3/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import Firebase
import SceneKit

class PathLogger {    
    /// A handle to the Firebase storage
    let storageBaseRef = Storage.storage().reference()

    /// path data taken during RECORDPATH - [[1x16 transform matrix]]
    var pathData: [[Float]] = []
    /// time stamps for pathData
    var pathDataTime: [Double] = []
    /// path data taken during NAVIGATEPATH - [[1x16 transform matrix]]
    var navigationData: [[Float]] = []
    /// time stamps for navigationData
    var navigationDataTime: [Double] = []
    /// timer to use for logging
    var dataTimer = Date()
    /// list of tracking errors ["InsufficientFeatures", "ExcessiveMotion"]
    var trackingErrorData: [String] = []
    /// time stamp of tracking error
    var trackingErrorTime: [Double] = []
    /// tracking phase - true: recording, false: navigation
    var trackingErrorPhase: [Bool] = []

    /// timer for logging state transitions
    var stateTransitionLogTimer = Date()
    /// all state transitions the app went through
    var stateSequence: [String] = []
    /// time stamp of state transitions
    var stateSequenceTime: [Double] = []

    /// description data during NAVIGATION
    var speechData: [String] = []
    /// time stamp for speechData
    var speechDataTime: [Double] = []
    /// list of keypoints - [[(LocationInfo)x, y, z, yaw]]
    var keypointData: [Array<Any>] = []
    
    func logStateTransition(newState: AppState) {
        stateSequenceTime.append(-stateTransitionLogTimer.timeIntervalSinceNow)
        stateSequence.append(newState.rawValue)
    }
    
    func logSpeech(utterance: String) {
        speechData.append(utterance)
        speechDataTime.append(-dataTimer.timeIntervalSinceNow)
    }
    
    func logTrackingError(isRecordingPhase: Bool, trackingError: String) {
        trackingErrorPhase.append(isRecordingPhase)
        trackingErrorTime.append(-dataTimer.timeIntervalSinceNow)
        trackingErrorData.append(trackingError)
    }
    
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

    func logKeypoints(keypoints: [KeypointInfo]) {
        keypointData = []
        for keypoint in keypoints {
            let data = [keypoint.location.x, keypoint.location.y, keypoint.location.z, keypoint.location.yaw]
            keypointData.append(data)
        }
    }
    
    func resetPathLog() {
        // reset all logging related variables for the path
        pathData = []
        pathDataTime = []
        dataTimer = Date()
        
        trackingErrorData = []
        trackingErrorTime = []
        trackingErrorPhase = []
    }
    
    func resetNavigationLog() {
        // clear any old log variables
        navigationData = []
        navigationDataTime = []
        speechData = []
        speechDataTime = []
        dataTimer = Date()
    }
    
    func resetStateSequenceLog() {
        // reset log variables that aren't tied to path recording or navigation
        stateSequence = []
        stateSequenceTime = []
    }
    
    func compileLogData(_ debug: Bool) {
        // compile log data
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let pathDate = dateFormatter.string(from: date)
        let pathID = UIDevice.current.identifierForVendor!.uuidString + dateFormatter.string(from: date)
        let userId = UIDevice.current.identifierForVendor!.uuidString
        
        sendMetaData(pathDate, pathID+"-0", userId, debug)
        sendPathData(pathID, userId)
        
        resetStateSequenceLog()
    }
    
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
                                    "keypointData": keypointData,
                                    "trackingErrorPhase": trackingErrorPhase,
                                    "trackingErrorTime": trackingErrorTime,
                                    "trackingErrorData": trackingErrorData,
                                    "stateSequence": stateSequence,
                                    "stateSequenceTime": stateSequenceTime]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            // here "jsonData" is the dictionary encoded in JSON data
            let storageRef = storageBaseRef.child(userId + "_" + pathID + "_metadata.json")
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
    
    func sendPathData(_ pathID: String, _ userId: String) {
        let body: [String : Any] = ["userId": userId,
                                    "PathID": pathID,
                                    "PathDate": "0",
                                    "PathType": "0",
                                    "PathData": pathData,
                                    "pathDataTime": pathDataTime,
                                    "navigationData": navigationData,
                                    "navigationDataTime": navigationDataTime,
                                    "speechData": speechData,
                                    "speechDataTime": speechDataTime]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            // here "jsonData" is the dictionary encoded as a JSON
            let storageRef = storageBaseRef.child(userId + "_" + pathID + "_pathdata.json")
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
