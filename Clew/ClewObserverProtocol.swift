//
//  ClewObserverProtocol.swift
//  Clew
//
//  Created by occamlab on 6/24/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation

protocol ClewObserver {
    func finishAnnouncement(announcement: String)
    func didTransitionTo(newState: AppState)
}
