//
//  TutorialManager.swift
//  Clew
//
//  Created by occamlab on 6/24/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation

class TutorialManager: ClewObserver {
    func finishAnnouncement(announcement: String) {
    }
    
    func didTransitionTo(newState: AppState) {
        if case .navigatingRoute = newState {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: NSLocalizedString("Let's learn about route navigation!", comment: "Message to user during tutorial"))
            print("howdy!")
        }
    }
}
