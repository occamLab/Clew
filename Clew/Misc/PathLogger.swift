//
//  PathLogger.swift
//  Clew
//
//  Created by Paul Ruvolo on 5/3/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//


import Foundation
import ARCoreGeospatial
import FirebaseStorage
import SceneKit
import ARKit
import FirebaseAnalytics
import FirebaseAuth

//FirebaseApp.configure()
//Analytics.

struct GeospatialWorldTransformPair {
    let geospatialTransform: GARGeospatialTransform
    let cameraWorldTransform: simd_float4x4
    
    func asDict()->[String: Any] {
        return ["geospatialTransform": geospatialTransform.asDict(), "cameraWorldTransform": cameraWorldTransform.asColumnMajorArray]
    }
}

/// A class to handle logging app usage data
class PathLogger {
    public static var shared = PathLogger()
    /// A handle to the Firebase storage
    let storageBaseRef = Storage.storage().reference()
    /// history of settings in the app
    var settingsHistory: [(Date, Dictionary<String, Any>)] = []
    /// geo spatial camera transforms from ARCore
    var geospatialTransforms: [GARGeospatialTransform] = []
    /// time stamps for geospatialTransform
    var geospatialTransformTimes: [Double] = []
    /// time stamps for geospatialTransform
    var geoLocationAlignmentAttemptTimes: [Double] = []
    /// saved route geospatial locations
    var geoLocationAlignmentAttempts: [(simd_float4x4, LocationInfoGeoSpatial, GARGeospatialTransform, Bool)] = []
    var savedRouteGeospatialLocations: [LocationInfoGeoSpatial] = []
    
    /// keeps track of the current GAR anchors and timestamps
    var garAnchors: [[LoggedGARAnchor]] = []
    var garAnchorTimestamps: [Double] = []
    var garAnchorCameraWorldTransforms: [GeospatialWorldTransformPair] = []
    
    /// logging for cloud anchors
    var cloudAnchorsForAlignment: [LoggedCloudAnchor] = []
    
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
    var currentNavigationMap: ARWorldMap?
    
    private init() {
        
    }
    
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
    func setCurrentRoute(route: SavedRoute, worldMap: ARWorldMap?) {
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
    
    func logGeospatialTransform(_ transform: GARGeospatialTransform) {
        geospatialTransformTimes.append(-stateTransitionLogTimer.timeIntervalSinceNow)
        geospatialTransforms.append(transform)
    }
    
    func logGARAnchors(anchors: [GARAnchor], cameraWorldTransform: simd_float4x4, geospatialTransform: GARGeospatialTransform, timestamp: Double) {
        garAnchors.append(anchors.map({anchor in LoggedGARAnchor(transform: anchor.transform, hasValidTransform: anchor.hasValidTransform, cloudIdentifier: anchor.cloudIdentifier ?? "", identifier: anchor.identifier)}))
        garAnchorTimestamps.append(timestamp)
        garAnchorCameraWorldTransforms.append(GeospatialWorldTransformPair(geospatialTransform: geospatialTransform, cameraWorldTransform: cameraWorldTransform))
    }
    
    func logSavedRouteGeospatialLocations(_ savedLocations: [LocationInfoGeoSpatial]) {
        savedRouteGeospatialLocations = savedLocations
    }
    
    func logGeolocationAlignmentAttempt(anchorTransform: simd_float4x4, geoSpatialAlignmentCrumb: LocationInfoGeoSpatial, cameraGeospatialTransform: GARGeospatialTransform, wasAccepted: Bool) {
        geoLocationAlignmentAttempts.append((anchorTransform, geoSpatialAlignmentCrumb, cameraGeospatialTransform, wasAccepted))
        geoLocationAlignmentAttemptTimes.append(-dataTimer.timeIntervalSinceNow)
    }

    
    func logCloudAnchorForAlignment(anchorIdentifier: String, cloudAnchorID: String, anchorTransform: ARAnchor) {
        cloudAnchorsForAlignment.append(LoggedCloudAnchor(anchorIdentifier: anchorIdentifier, cloudAnchorID: cloudAnchorID, anchorTransform: anchorTransform))
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
    
    func logSettings(localizationThreshold: Int, filterGeoSpatial: Bool, disableARWorldMap: Bool, visualizeCloudAnchors: Bool, defaultUnit: Int, defaultColor: Int, soundFeedback: Bool, voiceFeedback: Bool, hapticFeedback: Bool, sendLogs: Bool, timerLength: Int, adjustOffset: Bool) {
        settingsHistory.append((Date(), ["localizationThreshold": localizationThreshold, "disableARWorldMap": disableARWorldMap, "visualizeCloudAnchors": visualizeCloudAnchors, "filterGeoSpatial": filterGeoSpatial, "defaultUnit": defaultUnit, "defaultColor": defaultColor, "soundFeedback": soundFeedback, "voiceFeedback": voiceFeedback, "hapticFeedback": hapticFeedback, "sendLogs": sendLogs, "timerLength": timerLength, "adjustOffset": adjustOffset]))
    }
    
    func uploadRating(_ isDebug: Bool, forRoute: [String]) {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        let body: [String : Any] = ["routeLogs": forRoute, "isDebug": isDebug]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            // here "jsonData" is the dictionary encoded in JSON data
            let storageRef = storageBaseRef.child("geo_location").child("logs").child(userId).child(UUID().uuidString + "_rating.json")
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
        } catch {
            print(error.localizedDescription)
        }
    }
    
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
        cloudAnchorsForAlignment = []
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
        savedRouteGeospatialLocations = []
        garAnchorTimestamps = []
        garAnchorCameraWorldTransforms = []
        garAnchors = []
        geoLocationAlignmentAttemptTimes = []
        geoLocationAlignmentAttempts = []
        dataTimer = Date()
    }
    
    /// Reset the logging variables having to do with state sequence tracking
    func resetStateSequenceLog() {
        // reset log variables that aren't tied to path recording or navigation
        stateSequence = []
        stateSequenceTime = []
        geospatialTransforms = []
        geospatialTransformTimes = []
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
        
        if let currentUser = Auth.auth().currentUser {
            userId = currentUser.uid
        } else {
            userId = Analytics.appInstanceID()!
        }
        
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
                                    "ARLoggerDataDir": ARLogger.shared.baseTrialPath,
                                    "routeId": currentNavigationRoute != nil ? currentNavigationRoute!.id : "",
                                    "hasMap": currentNavigationMap != nil,
                                    "cloudAnchorsForAlignment": cloudAnchorsForAlignment.map( { $0.asDict() }),
                                    "garAnchorTimestamps": garAnchorTimestamps,
                                    "garAnchorCameraWorldTransformsAndGeoSpatialData": garAnchorCameraWorldTransforms.map({$0.asDict()}),
                                    "garAnchors": garAnchors.map({garAnchorList in garAnchorList.map({garAnchor in garAnchor.asDict() })}),
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
            let storageRef = storageBaseRef.child("geo_location").child("logs").child(userId).child(pathID + "_metadata.json")
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
                                    "speechDataTime": Array(speechDataTime), "geoSpatialTransforms": geospatialTransforms.map({$0.asDict()}), "geoSpatialTransformTimes": geospatialTransformTimes, "geoLocationAlignmentAttemptTimes": geoLocationAlignmentAttemptTimes, "savedRouteGeospatialLocations": savedRouteGeospatialLocations.map({$0.asDict()}), "geoLocationAlignmentAttempts": geoLocationAlignmentAttempts.map({ ["anchorTransform": $0.0.asColumnMajorArray, "geoSpatialAlignmentCrumb": $0.1.asDict(), "cameraGeospatialTransform": $0.2.asDict(), "wasAccepted": $0.3] })]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            // here "jsonData" is the dictionary encoded as a JSON
            let storageRef = storageBaseRef.child("geo_location").child("logs").child(userId).child(pathID + "_pathdata.json")
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

extension LocationInfoGeoSpatial {
    func asDict()->[String: Any] {
        return [ "latitude": latitude, "longitude": longitude, "heading": heading, "altitude": altitude, "altitudeUncertainty": altitudeUncertainty, "horizontalUncertainty": horizontalUncertainty, "headingUncertainty": headingUncertainty, "GARAnchorUUID": GARAnchorUUID?.uuidString ?? "", "geoAnchorTransform": geoAnchorTransform?.asColumnMajorArray ?? [] ]
    }
}

struct LoggedCloudAnchor {
    let anchorIdentifier: String
    let cloudAnchorID: String
    let anchorTransform: ARAnchor
            
    func asDict()->[String: Any] {
        return [ "anchorIdentifier": anchorIdentifier, "cloudAnchorID": cloudAnchorID, "anchorTransform": anchorTransform.transform.asColumnMajorArray ]
    }
}


struct LoggedGARAnchor {
    let transform: simd_float4x4
    let hasValidTransform: Bool
    let cloudIdentifier: String
    let identifier: UUID
    
    func asDict()->[String: Any] {
        return ["transform": transform.asColumnMajorArray,
                "hasValidTransform": hasValidTransform,
                "cloudIdentifier": cloudIdentifier,
                "identifier": identifier.uuidString]
    }
}
