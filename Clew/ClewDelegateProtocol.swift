//
//  ClewDelegateProtocol.swift
//  Clew
//
//  Created by OccamLab on 7/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation

protocol ClewDelegate : ClewObserver {
    func allowRouteRating() -> Bool
    func allowRoutesList() -> Bool
    func allowLandmarkProcedure() -> Bool
    func allowSettingsPressed() -> Bool
    func allowFeedbackPressed() -> Bool
    func allowHelpPressed() -> Bool
    func allowHomeButtonPressed() -> Bool
    func allowAnnouncements() -> Bool
}
