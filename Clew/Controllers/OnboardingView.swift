//
//  OnboardingView.swift
//  Clew
//
//  Created by Jasper Katzban on 3/30/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import UIKit
import SwiftUI
import AuthenticationServices
/*
@available(iOS 13.0, *)
class OnboardingView: UIView {
      @Environment(\.window) override var window: UIWindow?
  @State var appleSignInDelegates: SignInWithAppleDelegates! = nil

  var body: some View {
    ZStack {
      VStack {
        SignInWithApple()
          .frame(width: 280, height: 60)
          .onTapGesture(perform: showAppleLogin)
      }
    }
    .onAppear {
      self.performExistingAccountSetupFlows()
    }
  }
    
    @objc func showAppleLogin() {
        print("showAppleLogin()")
      let request = ASAuthorizationAppleIDProvider().createRequest()
      request.requestedScopes = [.fullName, .email]
      
      performSignIn(using: [request])
    }

    private func performSignIn(using requests: [ASAuthorizationRequest]) {
      appleSignInDelegates = SignInWithAppleDelegates(window: window) { success in
        if success {
            print("sign in worked!")
            print(requests)
        } else {
          // show the user an error
        }
      }

      let controller = ASAuthorizationController(authorizationRequests: requests)
      controller.delegate = appleSignInDelegates
      controller.presentationContextProvider = appleSignInDelegates


      controller.performRequests()
    }
    
    private func performExistingAccountSetupFlows() {
      // 1
      #if !targetEnvironment(simulator)

      // 2
      let requests = [
        ASAuthorizationAppleIDProvider().createRequest(),
        ASAuthorizationPasswordProvider().createRequest()
      ]

      // 2
      performSignIn(using: requests)
      #endif
    }
}


*/
