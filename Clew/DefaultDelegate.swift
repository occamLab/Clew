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
    func allowRouteRating() -> Bool {
        return true
    }
    
    func finishAnnouncement(announcement: String) { }
    
    func didTransitionTo(newState: AppState) { }
    
    func didReceiveNewCameraPose(transform: simd_float4x4) { }
}
