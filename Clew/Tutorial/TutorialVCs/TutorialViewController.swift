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

class TutorialViewController: UIViewController, ClewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.size.width,
                                                 height: UIScreen.main.bounds.size.height))
    }
    
    let singleRouteChildVC = SingleRouteVC()
    let phoneOrientationTrainingChildVC  = PhoneOrientationTrainingVC()
    let tipsAndWarningsChildVC = TipsAndWarningsViewController()
    let phoneOrientationGIFChildVC = PhoneOrientationGIFVC()
    
    /// A custom enumeration type that describes the exact state of the tutorial.
    enum TutorialState {
        case explainOrientationTraining
        case startOrientationTraining
        case optimalOrientationAchieved
        /// This is the screen that comes up immediately after the phone orientation training
        case readyToRecordSingleRoute
        case recordingSingleRoute
        case teachTheNavigationOfASingleRoute
        case initializing
        case displayCongratsView
        case endTutorial
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
            case .explainOrientationTraining:
                removeAllChildVCs()
                add(phoneOrientationGIFChildVC)
            case .startOrientationTraining:
                removeAllChildVCs()
                add(phoneOrientationTrainingChildVC)
            case .optimalOrientationAchieved:
                state = .readyToRecordSingleRoute
            case .readyToRecordSingleRoute:
                removeAllChildVCs()
                add(singleRouteChildVC)
                print("in readyToRecordState")
            case .recordingSingleRoute:
                print("in recording state")
                break
            case .teachTheNavigationOfASingleRoute:
                print("in teaching navigation state")
                break
            case .initializing:
                initialize()
            case .displayCongratsView:
                print("in display congrats view state")
            case .endTutorial:
                print("in end tutorial state")
                removeAllChildVCs()
//                phoneOrientationGIFChildVC.remove()
                NotificationCenter.default.post(name: Notification.Name("ClewTutorialCompleted"), object: nil)
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
    
    func allowRouteRating()->Bool {
        for child in children {
            if let delegate = child as? ClewDelegate {
                return delegate.allowRouteRating()
            }
        }
        return true
    }

    func allowRoutesList() -> Bool {
        for child in children {
            if let delegate = child as? ClewDelegate {
                return delegate.allowRoutesList()
            }
        }
        return true
    }
    
    func allowLandmarkProcedure() -> Bool {
        for child in children {
            if let delegate = child as? ClewDelegate {
                return delegate.allowLandmarkProcedure()
            }
        }
        return true
    }
    
    func allowSettingsPressed() -> Bool {
        for child in children {
            if let delegate = child as? ClewDelegate {
                return delegate.allowSettingsPressed()
            }
        }
        return true
    }

    func allowFeedbackPressed() -> Bool {
        for child in children {
            if let delegate = child as? ClewDelegate {
                return delegate.allowFeedbackPressed()
            }
        }
        return true
    }

    func allowHelpPressed() -> Bool {
        for child in children {
            if let delegate = child as? ClewDelegate {
                return delegate.allowHelpPressed()
            }
        }
        return true
    }

    func allowHomeButtonPressed() -> Bool {
        for child in children {
            if let delegate = child as? ClewDelegate {
                return delegate.allowHomeButtonPressed()
            }
        }
        return true
    }
    
    func allowPauseButtonPressed() -> Bool {
        for child in children {
            if let delegate = child as? ClewDelegate {
                return delegate.allowPauseButtonPressed()
            }
        }
        return true
    }
    
    func allowAnnouncements() -> Bool {
        for child in children {
            if let delegate = child as? ClewDelegate {
                return delegate.allowAnnouncements()
            }
        }
        return true
    }
    
    func allowFirstTimePopups() -> Bool {
        for child in children {
            if let delegate = child as? ClewDelegate {
                return delegate.allowFirstTimePopups()
            }
        }
        return true
    }
}
