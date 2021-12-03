//
//  RouteManager.swift
//  Clew
//
//  Created by Paul Ruvolo on 10/14/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import Foundation

class RouteManager {
    static var shared = RouteManager()
    
    /// list of keypoints calculated after path completion
    private var keypoints: [KeypointInfo]?
    /// keep a list of the keypoints from the original route since the keypoints array is cleared as the user traverses the route (TODO: use an index instead of deleting)
    private var originalKeypoints: [KeypointInfo]?
    /// Intermediate anchor points
    var intermediateAnchorPoints:[RouteAnchorPoint] = []
    
    private init() {
        
    }
    func setRouteKeypoints(kps: [KeypointInfo]) {
        originalKeypoints = kps
        keypoints = kps
    }
    var nextKeypoint: KeypointInfo? {
        return keypoints?.first
    }
    var nextNextKeypoint: KeypointInfo? {
        if let keypoints = keypoints, keypoints.count > 1 {
            return keypoints[1]
        } else {
            return nil
        }
    }
    func checkOffKeypoint() {
        guard let originalKeypoints = originalKeypoints else {
            keypoints?.remove(at: 0)
            return
        }
        for keypoint in originalKeypoints {
            if keypoints?.first!.location.identifier == keypoint.location.identifier {
                PathLogger.shared.logEvent(eventDescription: "keypoint checked off: \(keypoint.location.identifier)")
                break
            }
        }
        keypoints?.remove(at: 0)
    }
    
    func getPreviousKeypoint(to: KeypointInfo)->KeypointInfo? {
        guard let originalKeypoints = originalKeypoints else {
            return nil
        }
        for (pKp, nKp) in zip(originalKeypoints[..<(originalKeypoints.count-1)], originalKeypoints[1...]) {
            if to.location.identifier == nKp.location.identifier {
                return pKp
            }
        }
        return nil
    }
    
    var onLastKeypoint: Bool {
        return keypoints?.count == 1
    }
}
