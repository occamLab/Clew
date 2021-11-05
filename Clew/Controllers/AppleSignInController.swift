//
//  AppleSignInController.swift
//  Clew
//
//  Created by Jasper Katzban on 3/31/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import UIKit
import SwiftUI
import Firebase
import FirebaseAuth
import AuthenticationServices

/// A View Controller for signing user in with apple ID for logging purposes
class AppleSignInController: UIViewController {
    
    var authHelper: AuthenticationHelper?
    var signInTitle: UILabel!
    var signInDescription: UITextView!
    var signInButton: UIControl!
    
    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view = UIView(frame:CGRect(x: 0, y: UIScreen.main.bounds.size.height*0.15, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height*0.85))
    
        signInTitle = UILabel()
        let titleText = NSLocalizedString("signInWithAppleTitle", comment: "Title of the sign in window")
        signInTitle.textAlignment = .center
        signInTitle.numberOfLines = 0
        signInTitle.lineBreakMode = NSLineBreakMode.byWordWrapping
        signInTitle.lineBreakMode = .byWordWrapping
        signInTitle.font = UIFont.preferredFont(forTextStyle: .title1)
        signInTitle.text = titleText
        signInTitle.tag = UIView.mainTextTag
        signInTitle.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
                
        
        signInDescription = UITextView()

        var mainText:String

        mainText = NSLocalizedString("signInWithAppleDescription", comment: "A description of why we'd like the user to sign in with their Apple ID") + "\n\n" +
            NSLocalizedString("introClewsRoleTutorialTextParagraph1", comment: "Text for intro to Clew's role Page Paragraph 1") + "\n\n" +
            NSLocalizedString("introClewsRoleTutorialTextParagraph2", comment: "Text for intro to Clew's role Page Paragraph 2") + "\n\n" +
            NSLocalizedString("introClewsRoleTutorialTextParagraph3", comment: "Text for intro to Clew's role Page Paragraph 3") + "\n\n" +
            NSLocalizedString("introClewsRoleTutorialTextParagraph4", comment: "Text for intro to Clew's role Page Paragraph 4")
        
        signInDescription.textAlignment = .left
        signInDescription.font = UIFont.preferredFont(forTextStyle: .body)
        signInDescription.text = mainText
        signInDescription.tag = UIView.mainTextTag
        
        signInDescription.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        signInDescription.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 3).isActive = true
        switch view.traitCollection.userInterfaceStyle {
        case .dark:
            signInButton = ASAuthorizationAppleIDButton(type: .default, style: .white)
        default:
            signInButton = ASAuthorizationAppleIDButton(type: .default, style: .black)
        }
        signInButton.layer.cornerRadius = 0.5 * signInButton.bounds.size.width
        signInButton.clipsToBounds = true
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        signInButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        signInButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        
        /// create stack view for aligning and distributing bottom layer buttons
        let stackView = UIStackView()
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        
        /// define horizonal, centered, and equal alignment of elements
        /// inside the bottom stack
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        
        /// add elements to the stack
        stackView.addArrangedSubview(signInTitle)
        stackView.addArrangedSubview(signInDescription)
        stackView.addArrangedSubview(signInButton)

        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8.0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        
        /// add target action for sign in button
        signInButton.addTarget(parent,
                                       action: #selector(signInWithApple),
                                      for: .touchUpInside)
    }
        
    @objc private func signInWithApple() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        /// handle sign in flow using FirbaseAuthentication Apple ID
        authHelper = AuthenticationHelper(window: appDelegate.window! )
        authHelper?.startSignInWithAppleFlow()
        
    }
}
