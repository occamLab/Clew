//
//  ClewObserverProtocol.swift
//  Clew
//
//  Created by occamlab on 6/24/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import SceneKit

protocol ClewObserver {
    func finishAnnouncement(announcement: String)
    func didTransitionTo(newState: AppState)
    func didReceiveNewCameraPose(transform: simd_float4x4)
}

extension ClewObserver {
    func finishAnnouncement(announcement: String) { }
}
