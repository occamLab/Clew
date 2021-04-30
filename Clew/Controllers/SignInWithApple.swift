//
//  SignInWithApple.swift
//  Clew
//
//  Created by Jasper Katzban on 3/30/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//
//  Allows user to sign-in with Apple ID which enables
//  usage logging tied to their account

import SwiftUI
import AuthenticationServices

@available(iOS 13.0, *)
final class SignInWithApple: UIViewRepresentable {
    
  func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
    
    return ASAuthorizationAppleIDButton()
  }
  
  func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
  }
}
