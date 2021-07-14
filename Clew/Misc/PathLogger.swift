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
import FirebaseAnalytics
import SceneKit
#if !APPCLIP
import FirebaseAuth
#endif

//FirebaseApp.configure()
//Analytics.

/// A class to handle logging app usage data
class PathLogger {
    /// A handle to the Firebase storage
    let storageBaseRef = Storage.storage().reference()
    /// history of settings in the app
    var settingsHistory: [(Date, Dictionary<String, Any>)] = []
    /// path data taken during RECORDPATH - [[1x16 transform matrix, navigation offset, use navigation offset]]
    var pathData: LinkedList<[Float]> = []
    /// time stamps for pathData
    var pathDataTime: LinkedList<Double> = []
    /// path data taken during NAVIGATEPATH - [[1x16 transform matrix, navigation offset, use navigation offset]]
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
    
    /// the navigation route that the user is currently navigating
    var currentNavigationRoute: SavedRoute?
    /// the ARWorldMap that is currently navigating
    var currentNavigationMap: Any?
    
    /// language used in recording
    func currentLocale() -> String {
        let preferredLanguage = Locale.preferredLanguages[0] as String
        print(preferredLanguage)
        return preferredLanguage
    }
    
    /// Sets the current route and map so we can log it later
    /// - Parameters:
    ///   - route: the route being navigated
    ///   - worldMap: the world map expressed as an optional Any type
    func setCurrentRoute(route: SavedRoute, worldMap: Any?) {
        currentNavigationRoute = route
        currentNavigationMap = worldMap
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
    ///   - headingOffset: the offset
    func logTransformMatrix(state: AppState, scn: SCNMatrix4, headingOffset: Float?, useHeadingOffset: Bool) {
        let logTime = -dataTimer.timeIntervalSinceNow
        
        // TODO: figure out better way to indicate nil value than hardcoded value of -1000.0
        let logMatrix = [scn.m11, scn.m12, scn.m13, scn.m14,
                         scn.m21, scn.m22, scn.m23, scn.m24,
                         scn.m31, scn.m32, scn.m33, scn.m34,
                         scn.m41, scn.m42, scn.m43, scn.m44, headingOffset == nil ? -1000.0 : headingOffset!, useHeadingOffset ? 1.0 : 0.0]
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
    
    func logSettings(defaultUnit: Int, defaultColor: Int, soundFeedback: Bool, voiceFeedback: Bool, hapticFeedback: Bool, sendLogs: Bool, timerLength: Int, adjustOffset: Bool) {
        settingsHistory.append((Date(), ["defaultUnit": defaultUnit, "defaultColor": defaultColor, "soundFeedback": soundFeedback, "voiceFeedback": voiceFeedback, "hapticFeedback": hapticFeedback, "sendLogs": sendLogs, "timerLength": timerLength, "adjustOffset": adjustOffset]))
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
        
        // reset these
        currentNavigationMap = nil
        currentNavigationRoute = nil
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
    func compileLogData(_ debug: Bool?)->[String] {
        // compile log data
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let pathDate = dateFormatter.string(from: date)
        let pathID = UIDevice.current.identifierForVendor!.uuidString + dateFormatter.string(from: date)
        let userId: String
        
        #if !APPCLIP
        if let currentUser = Auth.auth().currentUser {
            userId = currentUser.uid
        } else {
            userId = Analytics.appInstanceID()!
        }
        #else
        userId = Analytics.appInstanceID()!
        #endif
        
        var logFileURLs: [String] = []
        if let metaDataLogURL = sendMetaData(pathDate, pathID+"-0", userId, debug) {
            logFileURLs.append(metaDataLogURL)
        }
        if let pathDataLogURL = sendPathData(pathID, userId) {
            logFileURLs.append(pathDataLogURL)
        }
        return logFileURLs
    }
    
    /// Send the meta data log to the cloud
    ///
    /// - Parameters:
    ///   - pathDate: the path date
    ///   - pathID: the path id
    ///   - userId: the user id
    ///   - debug: true if the route was unsuccessful (useful for debugging) and false if the route was successful
    func sendMetaData(_ pathDate: String, _ pathID: String, _ userId: String, _ debug: Bool?)->String? {
        let pathType: String
        if debug == nil {
            pathType = "notrated"
        } else if debug! {
            pathType = "debug"
        } else {
            pathType = "success"
        }
        
        // compute time stamps for settings
        for i in 0..<settingsHistory.count {
            settingsHistory[i].1["relativeTimeStamp"] = settingsHistory[i].0.timeIntervalSince(stateTransitionLogTimer)
        }
        
        let body: [String : Any] = ["userId": userId,
                                    "PathID": pathID,
                                    "PathDate": pathDate,
                                    "PathType": pathType,
                                    "isVoiceOverOn": UIAccessibility.isVoiceOverRunning,
                                    "routeId": currentNavigationRoute != nil ? currentNavigationRoute!.id : "",
                                    "hasMap": currentNavigationMap != nil,
                                    "keypointData": Array(keypointData),
                                    "trackingErrorPhase": Array(trackingErrorPhase),
                                    "trackingErrorTime": Array(trackingErrorTime),
                                    "trackingErrorData": Array(trackingErrorData),
                                    "stateSequence": Array(stateSequence),
                                    "stateSequenceTime": Array(stateSequenceTime),
                                    "settingsHistory": settingsHistory.map({$0.1})]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            // here "jsonData" is the dictionary encoded in JSON data
            let storageRef = storageBaseRef.child("logs").child(userId).child(pathID + "_metadata.json")
            let fileType = StorageMetadata()
            fileType.contentType = "application/json"
            // upload the image to Firebase storage and setup auto snapshotting
            storageRef.putData(jsonData, metadata: fileType) { (metadata, error) in
                guard metadata != nil else {
                    // Uh-oh, an error occurred!
                    print("could not upload meta data to firebase", error!.localizedDescription)
                    return
                }
                print("Successfully uploaded log! ", storageRef.fullPath)
            }
            storageBaseRef.child("logs").child("0w5zdRj6HDahFNdqKNklSpfpSmq2").child("66F17E75-9F09-438A-89C1-36D1ACF4DFA82021-06-01T14:26:53-04:00-0_metadata.json").getData(maxSize: 100000000) { data, error in
                print("data: \(data), error \(error)")
                let str = String(decoding: data!, as: UTF8.self)
                print(str)
            }
            return storageRef.fullPath
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    /// Send the path data log to the cloud.
    ///
    /// - Parameters:
    ///   - pathID: the id of the path
    ///   - userId: the user id
    func sendPathData(_ pathID: String, _ userId: String)->String? {
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
            let storageRef = storageBaseRef.child("logs").child(userId).child(pathID + "_pathdata.json")
            let fileType = StorageMetadata()
            fileType.contentType = "application/json"
            // upload the image to Firebase storage and setup auto snapshotting
            storageRef.putData(jsonData, metadata: fileType) { (metadata, error) in
                guard let metadata = metadata else {
                    // Uh-oh, an error occurred!
                    print("could not upload path data to firebase", error!.localizedDescription)
                    return
                }
                print("Successfully uploaded log! ", storageRef.fullPath)
            }
            return storageRef.fullPath
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}

