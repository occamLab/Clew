//
//  RecordPathController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

/// A View Controller for handling the recording path/route state
class RecordPathController: UIViewController {

    /// Button for recording a route
    var recordPathButton: UIButton!
    
    /// button for creating a new Anchor Point
    var addAnchorPointButton: UIButton!

    /// button for accessing saved routes
    var routesButton: UIButton!

    /// called when view appears (any time)
    override func viewDidAppear(_ animated: Bool) {
        /// set thumbsUpButton as initially active voiceover button
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.addAnchorPointButton)
        addAnchorPointButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        routesButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        recordPathButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
    }
    
    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPresentationStyle = .fullScreen
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: UIScreen.main.bounds.size.height*0.2+30,
                                                 width: UIConstants.buttonFrameWidth * 1,
                                                 height: UIScreen.main.bounds.size.height*0.7-30))
        
        /// Creating a button that can be used to start the creation of a saved route.
        addAnchorPointButton = UIButton(type: .custom)
        addAnchorPointButton.layer.cornerRadius = 0.075 * UIConstants.buttonFrameWidth
        addAnchorPointButton.clipsToBounds = true
        addAnchorPointButton.layer.borderWidth = UIConstants.buttonFrameWidth * 0.05
        addAnchorPointButton.layer.borderColor = CGColor(red: 102.0/255.0, green: 188.0/255.0, blue: 71.0/255.0, alpha: 1.0)
        addAnchorPointButton.translatesAutoresizingMaskIntoConstraints = false
        addAnchorPointButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        addAnchorPointButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        addAnchorPointButton.backgroundColor = .systemBackground
        addAnchorPointButton.addLargeTitle(NSLocalizedString("saveARouteButtonText", comment: "This is the text which appears on the save a route buttton"))
        addAnchorPointButton.accessibilityLabel = NSLocalizedString("saveARouteButtonAccessibilityLabel", comment: "A button that allows the user to save a path to a destination.")

        /// Creating a button that can be used to start the creation of a single use route.
        recordPathButton = UIButton(type: .custom)
        recordPathButton.layer.cornerRadius = 0.075 * UIConstants.buttonFrameWidth
        recordPathButton.clipsToBounds = true
        recordPathButton.layer.borderWidth = UIConstants.buttonFrameWidth * 0.05
        recordPathButton.layer.borderColor = CGColor(red: 102.0/255.0, green: 188.0/255.0, blue: 71.0/255.0, alpha: 1.0)
        recordPathButton.translatesAutoresizingMaskIntoConstraints = false
        recordPathButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        recordPathButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        recordPathButton.backgroundColor = .systemBackground
        recordPathButton.addLargeTitle(NSLocalizedString("singleUseRouteButtonText", comment: "This is the text which appears on the single use route buttton"))
        recordPathButton.accessibilityLabel = NSLocalizedString("recordSingleUseRouteButtonAccessibilityLabel", comment: "A button that allows the user to navigate a route one time.")

        /// Creating a button that can be used to access the saved routes list.
        routesButton = UIButton(type: .custom)
        routesButton.layer.cornerRadius = 0.075 * UIConstants.buttonFrameWidth
        routesButton.clipsToBounds = true
        routesButton.layer.borderWidth = UIConstants.buttonFrameWidth * 0.05
        routesButton.layer.borderColor = CGColor(red: 102.0/255.0, green: 188.0/255.0, blue: 71.0/255.0, alpha: 1.0)
        routesButton.translatesAutoresizingMaskIntoConstraints = false
        routesButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        routesButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        routesButton.backgroundColor = .systemBackground
        routesButton.addLargeTitle(NSLocalizedString("savedRoutesListButtonText", comment: "This is the text which appears on the Saved routes List buttton"))
        routesButton.accessibilityLabel = NSLocalizedString("savedRoutesListButtonAccessibilityLabel", comment: "The accessibility tag for a button which opens a menu which displays all the saved routes created by the user.")
        
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
        stackView.addArrangedSubview(recordPathButton)
        stackView.addArrangedSubview(addAnchorPointButton)
        stackView.addArrangedSubview(routesButton)

        
        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        
        if let parent: UIViewController = parent {

            routesButton.addTarget(parent,
                                          action: #selector(ViewController.routesButtonPressed),
                                          for: .touchUpInside)
            addAnchorPointButton.addTarget(parent,
                                          action: #selector(ViewController.recordPath),
                                          for: .touchUpInside)
            recordPathButton.addTarget(parent,
                                          action: #selector(ViewController.startCreateAnchorPointProcedure),
                                          for: .touchUpInside)
        }
    }
}
