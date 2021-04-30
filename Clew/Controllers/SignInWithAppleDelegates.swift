//
//  SignInWithAppleDelegates.swift
//  Clew
//
//  Created by Jasper Katzban on 3/30/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//
//  Delegates apple ID sign-in functions

import UIKit
import AuthenticationServices
import Contacts

class SignInWithAppleDelegates: NSObject {
  private let signInSucceeded: (Bool) -> Void
  private weak var window: UIWindow!
  
  init(window: UIWindow?, onSignedIn: @escaping (Bool) -> Void) {
    self.window = window
    self.signInSucceeded = onSignedIn
  }
}

@available(iOS 13.0, *)
extension SignInWithAppleDelegates: ASAuthorizationControllerDelegate {
//    make private again:
   func registerNewAccount(credential:  ASAuthorizationAppleIDCredential) {
    // 1
    let userData = UserData(email: credential.email!,
                            name: credential.fullName!,
                            identifier: credential.user)

    // 2
    let keychain = UserDataKeychain()
    print(keychain)
    do {
        print("trying to store userData")
        
      try keychain.store(userData)
        print(userData)
        print(keychain)
    } catch {
      self.signInSucceeded(false)
    }

    // 3
    do {
        let success = try
//        print(userData.email)
////        WebApi.Register(user: userData,
////                                        identityToken: credential.identityToken,
////                                        authorizationCode: credential.authorizationCode)
      self.signInSucceeded(true)
        print(userData.email)
    } catch {
      self.signInSucceeded(false)
    }
  }

  func signInWithExistingAccount(credential: ASAuthorizationAppleIDCredential) {
    // You *should* have a fully registered account here.  If you get back an error from your server
    // that the account doesn't exist, you can look in the keychain for the credentials and rerun setup

    // if (WebAPI.Login(credential.user, credential.identityToken, credential.authorizationCode)) {
    //   ...
    // }
    
    let keychain = UserDataKeychain()
    
    do {
      let userData = try keychain.retrieve()
      try WebApi.Register(user: userData,
                                        identityToken: credential.identityToken,
                                        authorizationCode: credential.authorizationCode)
      self.signInSucceeded(true)
    } catch {
      self.signInSucceeded(false)
    }
    
    print("signInWithExistingAccount")
    print(credential)
    print(credential.email, credential.fullName, credential.identityToken)
    self.signInSucceeded(true)
  }
    

  func signInWithUserAndPassword(credential: ASPasswordCredential) {
    // You *should* have a fully registered account here.  If you get back an error from your server
    // that the account doesn't exist, you can look in the keychain for the credentials and rerun setup

    // if (WebAPI.Login(credential.user, credential.password)) {
    //   ...
    // }
    print("signinwithuserandpassword")
    print(credential)
    print(credential.user, credential.password)
    self.signInSucceeded(true)
  }
  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

    switch authorization.credential {
    case let appleIdCredential as ASAuthorizationAppleIDCredential:
        print("line87:")
        print(appleIdCredential.email!)
      if let _ = appleIdCredential.email, let _ = appleIdCredential.fullName {
        registerNewAccount(credential: appleIdCredential)
      } else {
        signInWithExistingAccount(credential: appleIdCredential)
      }

      break
      
    case let passwordCredential as ASPasswordCredential:
      signInWithUserAndPassword(credential: passwordCredential)

      break
      
    default:
      break
    }
  }

  
  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    // Handle error.
  }
    
}

@available(iOS 13.0, *)
extension SignInWithAppleDelegates: ASAuthorizationControllerPresentationContextProviding {
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return self.window
  }
}
