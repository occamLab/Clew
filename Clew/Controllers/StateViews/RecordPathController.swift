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
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.recordPathButton)
        addAnchorPointButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        routesButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        recordPathButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
    }
    
    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: 0,
                                                 width: UIConstants.buttonFrameWidth * 1,
                                                 height: UIConstants.buttonFrameWidth * 1.5))


        let label = UILabel(frame: CGRect(x: 15,
                                          y: UIScreen.main.bounds.size.height/5,
                                          width: UIScreen.main.bounds.size.width-30,
                                          height: UIScreen.main.bounds.size.height/2))
        
        var mainText: String?
        if let mainText: String = mainText {
            label.textColor = UIColor.white
            label.textAlignment = .center
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.font = label.font.withSize(20)
            label.text = mainText
            label.tag = UIView.mainTextTag
            view.addSubview(label)
        }
        
        addAnchorPointButton = UIButton(type: .custom)
        addAnchorPointButton.layer.cornerRadius = 0.5 * addAnchorPointButton.bounds.size.width
        addAnchorPointButton.clipsToBounds = true
        addAnchorPointButton.translatesAutoresizingMaskIntoConstraints = false
        addAnchorPointButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        addAnchorPointButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 2.5).isActive = true
        addAnchorPointButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        addAnchorPointButton.imageView?.contentMode = .scaleAspectFit
        addAnchorPointButton.setTitle(NSLocalizedString("Save a Route", comment:"Button that allows the user to save a path to a destination."),for: .normal)
        addAnchorPointButton.setTitleColor(.black, for: .normal)
        addAnchorPointButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 35)!
        addAnchorPointButton.accessibilityLabel = NSLocalizedString("Save a Route", comment: "A button that allows the user to save a path to a destination.")
        addAnchorPointButton.titleLabel?.textAlignment = .center
        addAnchorPointButton.titleLabel?.numberOfLines = 0
        addAnchorPointButton.titleLabel?.lineBreakMode = .byWordWrapping
        addAnchorPointButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        addAnchorPointButton.titleEdgeInsets.top = 0
        addAnchorPointButton.titleEdgeInsets.left = 5
        addAnchorPointButton.titleEdgeInsets.bottom = 0
        addAnchorPointButton.titleEdgeInsets.right = 5
        
        recordPathButton = UIButton(type: .custom)
        recordPathButton.layer.cornerRadius = 0.75 * addAnchorPointButton.bounds.size.width
        recordPathButton.clipsToBounds = true
        recordPathButton.translatesAutoresizingMaskIntoConstraints = false
        recordPathButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        recordPathButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 2.5).isActive = true
        recordPathButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        recordPathButton.imageView?.contentMode = .scaleAspectFit
        recordPathButton.setTitle("Single Use Route",for: .normal)
        recordPathButton.setTitleColor(.black, for: .normal)
        recordPathButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 35)!
        recordPathButton.accessibilityLabel = NSLocalizedString("Record a single use route", comment: "A button that allows the user to navigate a route one time.")
        recordPathButton.titleLabel?.textAlignment = .center
        recordPathButton.titleLabel?.numberOfLines = 0
        recordPathButton.titleLabel?.lineBreakMode = .byWordWrapping
        recordPathButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        recordPathButton.titleEdgeInsets.top = 0
        recordPathButton.titleEdgeInsets.left = 5
        recordPathButton.titleEdgeInsets.bottom = 0
        recordPathButton.titleEdgeInsets.right = 5

        
        routesButton = UIButton(type: .custom)
        routesButton.layer.cornerRadius = 0.75 * routesButton.bounds.size.width
        routesButton.clipsToBounds = true
        routesButton.translatesAutoresizingMaskIntoConstraints = false
        routesButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        routesButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 2.5).isActive = true
        routesButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        routesButton.imageView?.contentMode = .scaleAspectFit
        routesButton.setTitle("Saved Routes List",for: .normal)
        routesButton.setTitleColor(.black, for: .normal)
        routesButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 35)!
        routesButton.accessibilityLabel = NSLocalizedString("Saved Routes List", comment: "A button that opens a menu which displays all the saved routes created by the user.")
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
        stackView.addArrangedSubview(recordPathButton)
        stackView.addArrangedSubview(routesButton)

        
        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 115).isActive = true
        
        if let parent: UIViewController = parent {
            
            
            /// TODO: Fix the naming of the selectors
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
