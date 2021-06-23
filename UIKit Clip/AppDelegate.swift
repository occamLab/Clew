//
//  AppDelegate.swift
//  Clew App Clip
//
//  Created by occamlab on 6/23/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseAnalytics

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var vc: UIViewController!


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        #if IS_DEV_TARGET
            let filePath = Bundle.main.path(forResource: "GoogleService-Info_dev", ofType: "plist")!
            let options = FirebaseOptions(contentsOfFile: filePath)
            FirebaseApp.configure(options: options!)
        #else
            FirebaseApp.configure()
        #endif
        
        self.vc = ViewController()
        self.window = UIWindow(frame:UIScreen.main.bounds)
        self.window?.rootViewController = self.vc
        self.window?.makeKeyAndVisible()
        UIApplication.shared.isIdleTimerDisabled = true

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        var config =  UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

