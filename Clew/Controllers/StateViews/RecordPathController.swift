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
    /// button for starting the  experiment
    var experimentButton: UIButton!
    /// called when view appears (any time)
    override func viewDidAppear(_ animated: Bool) {
        /// set thumbsUpButton as initially active voiceover button
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.addAnchorPointButton)
        addAnchorPointButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        routesButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        recordPathButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        experimentButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
    }
    
    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPresentationStyle = .fullScreen
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

        /// Creating a button that can be used to start the creation of a single use route.
        recordPathButton = UIButton(type: .custom)
        recordPathButton.layer.cornerRadius = 0.75 * addAnchorPointButton.bounds.size.width
        recordPathButton.clipsToBounds = true
        recordPathButton.translatesAutoresizingMaskIntoConstraints = false
        recordPathButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        recordPathButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        recordPathButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        recordPathButton.imageView?.contentMode = .scaleAspectFit
        recordPathButton.setTitle(NSLocalizedString("singleUseRouteButtonText", comment: "This is the text which appears on the single use route buttton"),for: .normal)
        recordPathButton.setTitleColor(.black, for: .normal)
        recordPathButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 35)!
        recordPathButton.accessibilityLabel = NSLocalizedString("recordSingleUseRouteButtonAccessibilityLabel", comment: "A button that allows the user to navigate a route one time.")
        recordPathButton.titleLabel?.textAlignment = .center
        recordPathButton.titleLabel?.numberOfLines = 0
        recordPathButton.titleLabel?.lineBreakMode = .byWordWrapping
        recordPathButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        recordPathButton.titleEdgeInsets.top = 0
        recordPathButton.titleEdgeInsets.left = 5
        recordPathButton.titleEdgeInsets.bottom = 0
        recordPathButton.titleEdgeInsets.right = 5

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
        
        experimentButton = UIButton(type: .custom)
        experimentButton.layer.cornerRadius = 0.75 *  experimentButton.bounds.size.width
        experimentButton.clipsToBounds = true
        experimentButton.translatesAutoresizingMaskIntoConstraints = false
        experimentButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        experimentButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        experimentButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        experimentButton.imageView?.contentMode = .scaleAspectFit
       ///LOCALIZE
        experimentButton.setTitle("Experiment Route",for: .normal)
        experimentButton.setTitleColor(.black, for: .normal)
        experimentButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 35)!

        experimentButton.accessibilityLabel = "Experiment Route"
        experimentButton.titleLabel?.textAlignment = .center
        experimentButton.titleLabel?.numberOfLines = 0
        experimentButton.titleLabel?.lineBreakMode = .byWordWrapping
        experimentButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        experimentButton.titleEdgeInsets.top = 0
        experimentButton.titleEdgeInsets.left = 5
        experimentButton.titleEdgeInsets.bottom = 0
        experimentButton.titleEdgeInsets.right = 5
        
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
        stackView.addArrangedSubview(experimentButton)

        
        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        
        if let parent: UIViewController = parent {

            experimentButton.addTarget(parent,
                                          action: #selector(ViewController.experimentProcedure),
                                          for: .touchUpInside)
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
