//
//  RecordPathController.swift
//  Clew-More
//
//  Created by Esme Abbot on 7/16/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import UIKit

/// A View Controller for handling the recording path/route state
class RecordPathController: UIViewController {
    
    /// button for creating a new Anchor Point
    var addAnchorPointButton: UIButton!

    /// button for accessing saved routes
    var routesButton: UIButton!
    
    //var enterCodeButton: UIButton!

    var testAccuracyButton: UIButton!

    /// called when view appears (any time)
    override func viewDidAppear(_ animated: Bool) {
        /// set thumbsUpButton as initially active voiceover button
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.addAnchorPointButton)
        addAnchorPointButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        routesButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        // recordPathButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        // enterCodeButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)

        testAccuracyButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
    }
    
    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: UIScreen.main.bounds.size.height*0.15,
                                                 width: UIConstants.buttonFrameWidth * 1,
                                                 height: UIScreen.main.bounds.size.height*0.75))
        
        /// Creating a button that can be used to start the creation of a saved route.
        addAnchorPointButton = UIButton(type: .custom)
        addAnchorPointButton.layer.cornerRadius = 0.5 * addAnchorPointButton.bounds.size.width
        addAnchorPointButton.clipsToBounds = true
        addAnchorPointButton.translatesAutoresizingMaskIntoConstraints = false
        addAnchorPointButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        addAnchorPointButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        addAnchorPointButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        addAnchorPointButton.imageView?.contentMode = .scaleAspectFit
        /*addAnchorPointButton.setTitle(NSLocalizedString("saveARouteButtonText", comment: "This is the text which appears on the save a route buttton"),for: .normal)*/
        addAnchorPointButton.setTitle(NSLocalizedString("saveARouteButtonText", comment: "The text that appears on the button to save a path to a destination"), for: .normal)
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

        
        /// Creating a button that can be used to start the creation of a single use route.
//        enterCodeButton = UIButton(type: .custom)
//        enterCodeButton.layer.cornerRadius = 0.75 * addAnchorPointButton.bounds.size.width
//        enterCodeButton.clipsToBounds = true
//        enterCodeButton.translatesAutoresizingMaskIntoConstraints = false
//        enterCodeButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
//        enterCodeButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
//        enterCodeButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
//        enterCodeButton.imageView?.contentMode = .scaleAspectFit
//        enterCodeButton.setTitle(NSLocalizedString("enterCodeButtonText", comment: "This is the text which appears on the enter an App Clip Code button"),for: .normal)
//        enterCodeButton.setTitleColor(.black, for: .normal)
//        enterCodeButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 35)!
//        enterCodeButton.accessibilityLabel = NSLocalizedString("enterCodeButtonAccessibilityLabel", comment: "A button that allows the user to navigate a route one time.")
//        enterCodeButton.titleLabel?.textAlignment = .center
//        enterCodeButton.titleLabel?.numberOfLines = 0
//        enterCodeButton.titleLabel?.lineBreakMode = .byWordWrapping
//        enterCodeButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
//        enterCodeButton.titleEdgeInsets.top = 0
//        enterCodeButton.titleEdgeInsets.left = 5
//        enterCodeButton.titleEdgeInsets.bottom = 0
//        enterCodeButton.titleEdgeInsets.right = 5
//
        
        testAccuracyButton = UIButton(type: .custom)
        testAccuracyButton.layer.cornerRadius = 0.75 * addAnchorPointButton.bounds.size.width
        testAccuracyButton.clipsToBounds = true
        testAccuracyButton.translatesAutoresizingMaskIntoConstraints = false
        testAccuracyButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        testAccuracyButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        testAccuracyButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        testAccuracyButton.imageView?.contentMode = .scaleAspectFit
        testAccuracyButton.setTitle("Test Location Accuracy", for: .normal)
        testAccuracyButton.setTitleColor(.black, for: .normal)
        testAccuracyButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 35)!
        testAccuracyButton.accessibilityLabel = "Test Location Accuracy"
        testAccuracyButton.titleLabel?.textAlignment = .center
        testAccuracyButton.titleLabel?.numberOfLines = 0
        testAccuracyButton.titleLabel?.lineBreakMode = .byWordWrapping
        testAccuracyButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        testAccuracyButton.titleEdgeInsets.top = 0
        testAccuracyButton.titleEdgeInsets.left = 5
        testAccuracyButton.titleEdgeInsets.bottom = 0
        testAccuracyButton.titleEdgeInsets.right = 5
 
        

        /// Creating a button that can be used to access the saved routes list.
        routesButton = UIButton(type: .custom)
        routesButton.layer.cornerRadius = 0.75 * routesButton.bounds.size.width
        routesButton.clipsToBounds = true
        routesButton.translatesAutoresizingMaskIntoConstraints = false
        routesButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        routesButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        routesButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        routesButton.imageView?.contentMode = .scaleAspectFit
        ///LOCALIZE
        routesButton.setTitle(NSLocalizedString("savedRoutesListButtonText", comment: "This is the text which appears on the Saved routes List buttton"),for: .normal)
        routesButton.setTitleColor(.black, for: .normal)
        routesButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 35)!

        routesButton.accessibilityLabel = NSLocalizedString("savedRoutesListButtonAccessibilityLabel", comment: "The accessibility tag for a button which opens a menu which displays all the saved routes created by the user.")
        routesButton.titleLabel?.textAlignment = .center
        routesButton.titleLabel?.numberOfLines = 0
        routesButton.titleLabel?.lineBreakMode = .byWordWrapping
        routesButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        routesButton.titleEdgeInsets.top = 0
        routesButton.titleEdgeInsets.left = 5
        routesButton.titleEdgeInsets.bottom = 0
        routesButton.titleEdgeInsets.right = 5
        
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
        stackView.addArrangedSubview(testAccuracyButton)
        stackView.addArrangedSubview(routesButton)

        
        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        
        if let parent: UIViewController = parent {

            routesButton.addTarget(parent,
                                          action: #selector(ViewController.manageRoutesButtonPressed),
                                          for: .touchUpInside)
            addAnchorPointButton.addTarget(parent,
                                          action: #selector(ViewController.recordPath),
                                          for: .touchUpInside)
            testAccuracyButton.addTarget(parent,
                                          action: #selector(ViewController.testAccuracy),
                                          for: .touchUpInside)
        }
    }
}
