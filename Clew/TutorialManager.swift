//
//  TutorialManager.swift
//  Clew
//
//  Created by occamlab on 6/24/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import SceneKit

class TutorialManager: ClewObserver {
    // TODO: double check that overriding the default implementation actually gets called
    func finishAnnouncement(announcement: String) {
    }
 
    func didTransitionTo(newState: AppState) {
        if case .navigatingRoute = newState {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: NSLocalizedString("Let's learn about route navigation!", comment: "Message to user during tutorial"))
            print("howdy!")
        }
        
        if case .mainScreen = newState {
            let TVC = TutorialViewController()
            TVC.handleStateTransitionToReadyToRecordSingleRoute()
        }
        
        if case .recordingRoute = newState {
            print("recording!")
        }
    }
    
    func didReceiveNewCameraPose(transform: simd_float4x4) {
        /*
        let angleFromVertical = acos(-transform.columns.0.y)
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light )
        
        if abs(angleFromVertical) < 0.1 {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) {_ in
                feedbackGenerator.impactOccurred()
            }
        }
        if abs(angleFromVertical) < 0.5 && abs(angleFromVertical) > 0.1 {
                Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) {_ in
                    feedbackGenerator.impactOccurred()
            }
        }
        print("angleFromVertical", angleFromVertical) */
        
        // optionally do something to respond to this event
        // if appropriate, pass the event to children
        
//        for child in getChildViewControllers() {
//            if let observer = child as ClewObserver {
//                observer.didReceiveNewCameraPose(transform: transform)
//            }
//        }
    }
}
