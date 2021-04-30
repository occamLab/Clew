//
//  AppleSignInController.swift
//  Clew
//
//  Created by Jasper Katzban on 3/31/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import UIKit
import SwiftUI
import AuthenticationServices

/// A View Controller for signing user in with apple ID for logging purposes
@available(iOS 13.0, *)
class AppleSignInController: UIViewController {
    @State var appleSignInDelegates: SignInWithAppleDelegates! = nil
    @Environment(\.window) var window: UIWindow?

    /// called when view appears (any time)
    override func viewDidAppear(_ animated: Bool) {
        /// TODO: set sign-in button as active voiceover component and configure other VO funcs
//        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.appleIdSignIn)
//        addAnchorPointButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
//        routesButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
//        recordPathButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
    }
    
    var addAnchorPointButton: UIButton!

    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        print("appleSignInViewLoading")
        
        self.performExistingAccountSetupFlows()
        
        view = TransparentTouchView(frame:CGRect(x: 0,
                                           y: UIScreen.main.bounds.size.height*0.15,
                                           width: UIConstants.buttonFrameWidth * 1,
                                           height: UIScreen.main.bounds.size.height*0.75))

        addAnchorPointButton = UIButton(type: .custom)
        addAnchorPointButton.layer.cornerRadius = 0.5 * addAnchorPointButton.bounds.size.width
        addAnchorPointButton.clipsToBounds = true
        addAnchorPointButton.translatesAutoresizingMaskIntoConstraints = false
        addAnchorPointButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        addAnchorPointButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        addAnchorPointButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        addAnchorPointButton.imageView?.contentMode = .scaleAspectFit
        addAnchorPointButton.setTitle(NSLocalizedString("saveARouteButtonText", comment: "This is the text which appears on the save a route buttton"),for: .normal)
        addAnchorPointButton.setTitleColor(.black, for: .normal)
        addAnchorPointButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 35)!
        addAnchorPointButton.accessibilityLabel = NSLocalizedString("saveARouteButtonAccessibilityLabel", comment: "A button that allows the user to save a path to a destination.")
        addAnchorPointButton.titleLabel?.textAlignment = .center
        addAnchorPointButton.titleLabel?.numberOfLines = 0
        addAnchorPointButton.titleLabel?.lineBreakMode = .byWordWrapping
        addAnchorPointButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        addAnchorPointButton.titleEdgeInsets.top = 0
        addAnchorPointButton.titleEdgeInsets.left = 5
        addAnchorPointButton.titleEdgeInsets.bottom = 0
        addAnchorPointButton.titleEdgeInsets.right = 5
        
        /// create stack view for aligning and distributing bottom layer buttons
        let stackView   = UIStackView()
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        
        /// define horizonal, centered, and equal alignment of elements
        /// inside the bottom stack
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        
        /// add elements to the stack

        stackView.addArrangedSubview(addAnchorPointButton)
        
        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        
        
        addAnchorPointButton.addTarget(parent,
                                       action: #selector(showAppleLogin),
                                      for: .touchUpInside)
        
    }
        
    @objc private func showAppleLogin() {
    print("showAppleLogin")
      let request = ASAuthorizationAppleIDProvider().createRequest()
      request.requestedScopes = [.fullName, .email]

      performSignIn(using: [request])
    self.transitionToMainApp()
    }

    // was private
    /// Prompts the user if an existing iCloud Keychain credential or Apple ID credential is found.
    private func performExistingAccountSetupFlows() {
      #if !targetEnvironment(simulator)
      // Note that this won't do anything in the simulator.  You need to
      // be on a real device or you'll just get a failure from the call.
      let requests = [
        ASAuthorizationAppleIDProvider().createRequest(),
//        ASAuthorizationPasswordProvider().createRequest()
      ]

      performSignIn(using: requests)
      print("requests:", requests.capacity)
      #endif
    }

    private func performSignIn(using requests: [ASAuthorizationRequest]) {
      appleSignInDelegates = SignInWithAppleDelegates(window: window) { success in
        if success {
          // update UI
            print("signed in!")
//            a = SignInWithAppleDelegates(window: window)
    
        } else {
          // show the user an error
            print("error signing in")
//            self.transitionToMainApp()
        }
        
      }

      let controller = ASAuthorizationController(authorizationRequests: requests)
      controller.delegate = appleSignInDelegates
      controller.presentationContextProvider = appleSignInDelegates
      controller.performRequests()
        
    }
    
    func transitionToMainApp() {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window?.rootViewController?.dismiss(animated: false)
            appDelegate.window = UIWindow(frame:UIScreen.main.bounds)
            appDelegate.window?.makeKeyAndVisible()
            appDelegate.window?.rootViewController = ViewController()
        }
}
