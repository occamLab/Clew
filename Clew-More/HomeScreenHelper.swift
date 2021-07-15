//
//  NavigateAppClipRouteHelper.swift
//  Clew-More
//
//  Created by occamlab on 7/13/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//
import UIKit
import SwiftUI
import Firebase
import Foundation
import FirebaseStorage

class HomeScreenHelper {
    
    var vc: ViewController
    var sceneDelegate: SceneDelegate

    
    var enterCodeIDController: UIViewController?
    var popoverController: UIViewController?
    var loadFromAppClipController: UIViewController?
    
    init(vc: ViewController, sceneDelegate: SceneDelegate) {
        self.vc = vc
        self.sceneDelegate = sceneDelegate
        //self.sceneDelegate = vc.view.window?.windowScene.delegate
    }
    
    
    func NavigateAppClipRouteHelper() {
        /// User enters their appClipCodeID
        var enterCodeIDController = UIHostingController(rootView: EnterCodeIDView(vc: self.vc))
        enterCodeIDController.modalPresentationStyle = .fullScreen
        self.sceneDelegate.window?.rootViewController!.present(enterCodeIDController, animated: false)

        /// listener
        NotificationCenter.default.addObserver(forName: NSNotification.Name("shouldDismissCodeIDPopover"), object: nil, queue: nil) { (notification) -> Void in
            enterCodeIDController.dismiss(animated: true)
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name("firebaseLoaded"), object: nil, queue: nil) { (notification) -> Void in
                var popoverController = UIHostingController(rootView: StartNavigationPopoverView(vc: self.vc))
                popoverController.modalPresentationStyle = .fullScreen
                self.vc.present(popoverController, animated: true)
                print("popover successful B)")
                // create listeners to ensure that the isReadingAnnouncement flag is reset properly
                NotificationCenter.default.addObserver(forName: NSNotification.Name("shouldDismissRoutePopover"), object: nil, queue: nil) { (notification) -> Void in
                    popoverController.dismiss(animated: true)
                    self.loadRoute()
                }
            }
            self.getFirebaseRoutesList()
        }


    }
    
    func RecordAppClipRouteHelper() {
        self.vc.recordPath()
    }
    
    func RouteDisplayHelper() {
        self.vc.routesButtonPressed()
    }
    
    func loadRoute() {
            //vc?.imageAnchoring = true
        //self.vc.recordPathController.remove()
        self.vc.handleStateTransitionToNavigatingExternalRoute()
    }
    
    func getFirebaseRoutesList() {
            let routeRef = Storage.storage().reference().child("AppClipRoutes")
        let appClipRef = routeRef.child("\(self.vc.appClipCodeID).json")
            
            /// attempt to download .json file from Firebase
            appClipRef.getData(maxSize: 100000000000) { appClipJson, error in
                do {
                    if let appClipJson = appClipJson {
                        /// unwrap NSData, if it exists, to a list, and set equal to existingRoutes
                        let routesFile = try JSONSerialization.jsonObject(with: appClipJson, options: [])
                        print("File: \(routesFile)")
                        if let routesFile = routesFile as? [[String: String]] {
                            self.vc.availableRoutes = routesFile
                            print("List: \(self.vc.availableRoutes)")
                            print("æ")
                            NotificationCenter.default.post(name: NSNotification.Name("firebaseLoaded"), object: nil)
                        }
                    }
                } catch {
                    print("Failed to download Firebase data due to error \(error)")
                }
            }
        }
    
}

    

    




