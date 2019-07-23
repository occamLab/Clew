//
//  DefaultDelegate.swift
//  Clew
//
//  Created by SCOPE on 7/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import SceneKit

class DefaultDelegate : ClewDelegate {
    func allowRoutesList() -> Bool {
        return true
    }
    
    func allowRouteRating() -> Bool {
        return true
    }
    
    func allowLandmarkProcedure() -> Bool {
        return true
    }
    
    func allowSettingsPressed() -> Bool {
        return true
    }
    
    func allowFeedbackPressed() -> Bool {
        return true
    }
    
    func allowHelpPressed() -> Bool {
        return true
    }
    
    func allowHomeButtonPressed() -> Bool {
        return true
    }
    
    func allowAnnouncements() -> Bool {
        return true
    }
    
    func finishAnnouncement(announcement: String) { }
    
    func didTransitionTo(newState: AppState) { }
    
    func didReceiveNewCameraPose(transform: simd_float4x4) { }
}
