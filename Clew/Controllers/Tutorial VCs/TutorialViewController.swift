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
import SRCountdownTimer

class TutorialViewController: UIViewController, ClewObserver {
    var countdownTimer: SRCountdownTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.size.width,
                                                 height: UIScreen.main.bounds.size.height))
        // put new timer here
        countdownTimer = SRCountdownTimer(frame: CGRect(x: UIConstants.buttonFrameWidth*1/10,
                                                        y: UIConstants.yOriginOfButtonFrame/10,
                                                        width: UIConstants.buttonFrameWidth*8/10,
                                                        height: UIConstants.buttonFrameWidth*8/10))
        countdownTimer.labelFont = UIFont(name: "HelveticaNeue-Light", size: 100)
        countdownTimer.labelTextColor = UIColor.white
        countdownTimer.timerFinishingText = "End"
        countdownTimer.lineWidth = 10
        countdownTimer.lineColor = UIColor.white
        countdownTimer.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        countdownTimer.isHidden = true
        countdownTimer.accessibilityElementsHidden = true
    }
    
    let singleRouteChildVC = SingleRouteVC()
    let phoneOrientationTrainingChildVC  = PhoneOrientationTrainingVC()
    
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
                add(phoneOrientationTrainingChildVC)
            case .optimalOrientationAchieved:
                print("nothing")
            case .readyToRecordSingleRoute:
                removeAllChildVCs()
                add(singleRouteChildVC)
            case .recordingSingleRoute:
                print("recording single route")
            case .teachTheNavigationOfASingleRoute:
                print("placeholder")
            case .initializing:
                initialize()
            }
        }
    }
    
    func removeAllChildVCs() {
        for child in children {
            child.remove()
        }
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



    func didTransitionTo(newState: AppState) {
        for child in children {
            if let observer = child as? ClewObserver {
                observer.didTransitionTo(newState: newState)
            }
        }
    }

    func didReceiveNewCameraPose(transform: simd_float4x4) {
        print("received new camera pose")
        
        // optionally do something in the TutorialViewController
        for child in children {
            print("propagating to children")
            if let observer = child as? ClewObserver {
                observer.didReceiveNewCameraPose(transform: transform)
            }
        }
    }
    

}

