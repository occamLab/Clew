//
//  SingleRouteVC.swift
//  Clew Dev
//
//  Created by occamlab on 6/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

class SingleRouteVC: TutorialChildViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: NSLocalizedString("Let's learn about route navigation!", comment: "Message to user during tutorial"))
            print("trying to post this - works")
        }
    }
    
    func didTransitionTo(newState: AppState) {
        print("check if function gets called")
        if case .readyToNavigateOrPause = newState {
            // TODO: maybe figure out a way to reuse this (subclass from a common superclass)
            self.tutorialParent?.state = .teachTheNavigationOfASingleRoute

            // do something to handle this new thing
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
                UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: NSLocalizedString("Great job.  You've recorded a route.  Now we will navigate it back to thst art!", comment: "Message to user during tutorial"))
            }
        }
        if case .mainScreen(let announceArrival) = newState, case .teachTheNavigationOfASingleRoute? = tutorialParent?.state {
            (parent as? TutorialViewController)?.state = .startingOrientationTraining
        }
    }
}
