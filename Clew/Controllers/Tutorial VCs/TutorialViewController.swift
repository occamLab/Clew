//
//  TutorialViewController.swift
//  Clew
//
//  Created by occamlab on 6/24/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import SceneKit
import UIKit

class TutorialViewController: UIViewController, ClewObserver {

    let singleRouteChildVC = SingleRouteVC()
    let phoneOrientationTrainingChildVC = PhoneOrientationTrainingVC()
    
    @IBOutlet weak var staticLabel2: DesignableLabel!
    @IBAction func CloseTips(_ sender: UIButton) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController?.dismiss(animated: false)
        appDelegate.window = UIWindow(frame:UIScreen.main.bounds)
        appDelegate.window?.makeKeyAndVisible()
        appDelegate.window?.rootViewController = ViewController()
        print("hi")
    }
    
    /// A custom enumeration type that describes the exact state of the tutorial.
    enum TutorialState {
        /// This is the screen that comes up immediately after the phone orientation training
        case readyToRecordSingleRoute(announceArrival: Bool)
        case initializing
        
        /// rawValue is useful for serializing state values, which we are currently using for our logging feature
        var rawValue: String {
            switch self {
            case .readyToRecordSingleRoute:
                return "readyToRecordSingleRoute"
            case .initializing:
                return "initializing"
            }
        }
    }
    
    
    var state = TutorialState.initializing {
        didSet {
            //        logger.logStateTransition(newState: state)
            switch state {
            case .readyToRecordSingleRoute:
                singleRouteChildVC.handleStateTransitionToReadyToRecordSingleRoute()
            case .initializing:
                initialize()
            }
        }
    }
    
    
    func  initialize() {
    }
    
    // TODO: double check that overriding the default implementation actually gets called
    func finishAnnouncement(announcement: String) {
    }
 
        
        // optionally do something to respond to this event
        // if appropriate, pass the event to children
        
//        for child in getChildViewControllers() {
//            if let observer = child as ClewObserver {
//                observer.didReceiveNewCameraPose(transform: transform)
//            }
//        }


    func didTransitionTo(newState: AppState) {
        if case .navigatingRoute = newState {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: NSLocalizedString("Let's learn about route navigation!", comment: "Message to user during tutorial"))
            print("howdy!")
        }
        
        if case .mainScreen = newState {
            singleRouteChildVC.handleStateTransitionToReadyToRecordSingleRoute()
        }
        
        if case .recordingRoute = newState {
            singleRouteChildVC.handleStateTransitionToRecordingSingleRoute()
        }
    }

    func didReceiveNewCameraPose(transform: simd_float4x4) {
//        phoneOrientationTrainingChildVC.didReceiveNewCameraPose(transform: transform)
        print("received new camera pose")
    }

}
