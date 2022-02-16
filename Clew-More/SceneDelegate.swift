//
//  SceneDelegate.swift
//  Clew More
//
//  Created by Esme Abbot on 7/14/21.
//

import UIKit
import SwiftUI
import Firebase
import Foundation
import FirebaseStorage
import FirebaseAuth
import ARDataLogger

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var observers: [Any] = []
    var vc: ViewController?
    var route: SavedRoute?
    
    var startMenuController: UIViewController?
    var enterCodeIDController: UIViewController?
    var loadFromAppClipController: UIViewController?
    static var disableConsentForm = true
    
    func createScene(_ scene: UIScene) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        window?.frame = UIScreen.main.bounds

        ARDataLogger.ARLogger.shared.dataDir = "appClipTest"
        
        UIApplication.shared.isIdleTimerDisabled = true
        if UserDefaults.standard.value(forKey: "hasconsented") as? Bool == true || SceneDelegate.disableConsentForm {
            vc = ViewController()
            self.window?.rootViewController = vc
        } else {
            let consentFormController = UIHostingController(rootView: InformedConsentView())
            consentFormController.view.frame = CGRect(x: 0,
                                                                           y: 0,
                                                                           width: UIConstants.buttonFrameWidth * 1,
                                                                           height: UIScreen.main.bounds.size.height)
            self.window?.rootViewController = consentFormController
        }
        
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously() { (authResult, error) in
                self.window?.backgroundColor = .white
                self.window?.makeKeyAndVisible()
            }
        } else {
            window?.backgroundColor = .white
            window?.makeKeyAndVisible()
        }
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let userActivity = connectionOptions.userActivities.first, userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL  {
            vc?.populateSceneFromAppClipURL(scene: scene, url: url)
        } else {
            createScene(scene)
        }
    }
    
    /// handles invocations in the App Clip
    /// return: Boolean value representing whether or not there is a userActivity object
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL else {
            return
        }
        createScene(scene)
        vc?.populateSceneFromAppClipURL(scene: scene, url: url)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

