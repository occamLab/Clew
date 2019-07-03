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
    let phoneOrientationTrainingChildVC  = PhoneOrientationTrainingVC()
    
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
        case startOrientationTraining
        case optimalOrientationAchieved
        /// This is the screen that comes up immediately after the phone orientation training
        case readyToRecordSingleRoute
        case recordingSingleRoute
        case teachTheNavigationOfASingleRoute
        case initializing
        /*
        /// rawValue is useful for serializing state values, which we are currently using for our logging feature
        var rawValue: String {
            switch self {
            case .readyToRecordSingleRoute:
                return "readyToRecordSingleRoute"
            case .initializing:
                return "initializing"
            case .teachTheNavigationOfASingleRoute:
                return "teachTheNavigationOfASingleRoute"
            case .tutorialStarting:
                return "tutorialStarting"
                case .opt
            }
        }*/
    }
    
    
    var state = TutorialState.initializing {
        didSet {
            //        logger.logStateTransition(newState: state)
            switch state {
            case .startOrientationTraining:
                print("does this work - check")
                add(phoneOrientationTrainingChildVC)
            case .optimalOrientationAchieved:
                print("nothing")
            case .readyToRecordSingleRoute:
                add(singleRouteChildVC)
                phoneOrientationTrainingChildVC.remove()
            case .recordingSingleRoute:
                print("recording single route")
            case .teachTheNavigationOfASingleRoute:
                print("placeholder")
            case .initializing:
                initialize()
           // case .startingOrientationTraining:
             //   print("starting orientation training added as child vc")
             //   add(phoneOrientationTrainingChildVC)
            }
        }
    }
    
    func removeAllChildVCs() {
        
    }
    
    func  initialize() {
    }
    
    // TODO: double check that overriding the default implementation actually gets called
    func finishAnnouncement(announcement: String) {
        // if let currentAnnouncement = current
        
        for child in children {
            if let observer = child as? ClewObserver {
                observer.finishAnnouncement(announcement: announcement)
            }
        }
    }
 
        
        // optionally do something to respond to this event
        // if appropriate, pass the event to children
        
//        for child in getChildViewControllers() {
//            if let observer = child as ClewObserver {
//                observer.didReceiveNewCameraPose(transform: transform)
//            }
//        }


    func didTransitionTo(newState: AppState) {
        for child in children {
            if let observer = child as? ClewObserver {
                observer.didTransitionTo(newState: newState)
            }
        }
    }

    func didReceiveNewCameraPose(transform: simd_float4x4) {
        print("received new camera pose")
//        phoneOrientationTrainingChildVC.didReceiveNewCameraPose(transform: transform)
//        add(phoneOrientationTrainingChildVC)
        
        // optionally do something in the TutorialViewController
        // TODO: need to work on/fix
        for child in children {
            print("propagating to children")
            if let observer = child as? ClewObserver {
                observer.didReceiveNewCameraPose(transform: transform)
            }
        }
    }

}


class TutorialChildViewController: UIViewController, ClewObserver {
    var tutorialParent: TutorialViewController? {
        return parent as? TutorialViewController
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.size.width,
                                                 height: UIScreen.main.bounds.size.height))
    }
    
    func finishAnnouncement(announcement: String) { }
    func didReceiveNewCameraPose(transform: simd_float4x4)  {}
    func didTransitionTo(newState: AppState) {}
}
