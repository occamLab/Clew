//
//  AppDelegate.swift
//  Clew
//
//  Created by Chris Seonghwan Yoon on 8/3/17.
//  Copyright © 2017 OccamLab. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseAnalytics

/// This class handles various state changes for the app.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// A handle to the app's main window
    var window: UIWindow?
        
    /// view controller!
    var vc: UIViewController!
    
    
    /// Called when the app finishes launching.  Currently, this is where we setup Firebase and make sure the phone screen doesn't lock while we are using the app.
    ///
    /// - Parameters:
    /// - Parameter application: a handle the application object
    ///   - launchOptions: the launch options
    /// - Returns: a Boolean indicating whether the app can continue to handle user activity.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Use Firebase library to configure APIs
        let filePath = Bundle.main.path(forResource: "GoogleService-Info_dev", ofType: "plist")!
        let options = FirebaseOptions(contentsOfFile: filePath)
        FirebaseApp.configure(options: options!)
        logUserProperties()
        // use for testing sign-in flow try? Auth.auth().signOut()
        if #available(iOS 13.0, *) {
          
          
            if (Auth.auth().currentUser == nil) {
                #if IS_DEV_TARGET
                    Auth.auth().signInAnonymously() { (authResult, error) in
                        guard let authResult = authResult else {
                            print("login error", error!.localizedDescription)
                            return
                        }
                        print("successful login", Auth.auth().currentUser?.uid)
                        // Override point for customization after application launch.
                        self.vc = ViewController()
                        self.window = UIWindow(frame:UIScreen.main.bounds)
                        self.window?.rootViewController = self.vc
                        self.window?.makeKeyAndVisible()
                    }
                    return true
                #else
                    window = UIWindow(frame:UIScreen.main.bounds)
                    window?.makeKeyAndVisible()
                    window?.rootViewController = AppleSignInController()
                    UIApplication.shared.isIdleTimerDisabled = true
                    return true
                #endif
            }
            
            self.vc = ViewController()
            self.window = UIWindow(frame:UIScreen.main.bounds)
            self.window?.rootViewController = self.vc
            self.window?.makeKeyAndVisible()
            
            // TODO pop up the informed consent view if they have not submitted it yet (track whether or not they submit by checking firebase?
//            var consentFormController = UIHostingController(rootView: InformedConsentView(vc: self))
//            consentFormController.view.frame = CGRect(x: 0,
//                                                                           y: UIScreen.main.bounds.size.height*0.15,
//                                                                           width: UIConstants.buttonFrameWidth * 1,
//                                                                           height: UIScreen.main.bounds.size.height*0.75)
//            consentFormController.view.backgroundColor = .clear
//            
            return true
        }
        
        // Override point for customization after application launch.

        vc = ViewController()
        window = UIWindow(frame:UIScreen.main.bounds)
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
        UIApplication.shared.isIdleTimerDisabled = true
        return true
    }
    
    /// entry point for when a file is opened from outside the app
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        
        /// check imported file extension
        guard url.pathExtension == "crd" else { return false }
        
        
        /// import the file here
        (vc as? ViewController)?.dataPersistence.importData(from: url)
        
        return true
    }
    
    /// Tells the delegate that the data for continuing an activity is available (entry point for when the app is opened using a universal link) <3
    ///
    /// Returns: true to indicate that the app handled the activity or false to let iOS know that your app didn't handle the activity
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        print("consider your restoration... handled")
        return true
    }

    /// Sent when the application is about to move from active to inactive state.  In Clew's current implementation, this method doesn't do anything.
    ///
    /// - Parameter application: a handle the application object
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    /// This method is called when the app is entering the background.  This is where timerss should be invalidated and shared resources should be relinquished.  In Clew's current implementation, this method doesn't do anything.
    ///
    /// - Parameter application: a handle the application object
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    /// <#Description#>
    ///
    /// - Parameter application: <#application description#>
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    /// Called when the application becomes active.  In Clew's current implementation, this method doesn't do anything.
    ///
    /// - Parameter application: a handle the application object
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    /// Called when the application becomes is about to terminate.  In Clew's current implementation, this method doesn't do anything.
    ///
    /// - Parameter application: a handle the application object
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    /// Send user properties to Firebase
    func logUserProperties() {
        Analytics.setUserProperty(String(UIAccessibility.isVoiceOverRunning), forName: "isVoiceOverRunning")
    }
        
}
