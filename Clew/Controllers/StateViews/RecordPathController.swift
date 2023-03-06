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
    
    /// button for going into bus sotp mode
    var busStopButton: UIButton!
    
    /// button for going to second bus stop
    var busStopTwoButton: UIButton!
    
    /// called when view appears (any time)
    override func viewDidAppear(_ animated: Bool) {
        /// set thumbsUpButton as initially active voiceover button
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.addAnchorPointButton)
        addAnchorPointButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        routesButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        recordPathButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        busStopButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        busStopTwoButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
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
        addAnchorPointButton.layer.cornerRadius = 0.5 * addAnchorPointButton.bounds.size.width
        addAnchorPointButton.clipsToBounds = true
        addAnchorPointButton.translatesAutoresizingMaskIntoConstraints = false
        addAnchorPointButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        addAnchorPointButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        addAnchorPointButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        addAnchorPointButton.imageView?.contentMode = .scaleAspectFit
        addAnchorPointButton.addLargeTitle(NSLocalizedString("saveARouteButtonText", comment: "This is the text which appears on the save a route buttton"))
        addAnchorPointButton.accessibilityLabel = NSLocalizedString("saveARouteButtonAccessibilityLabel", comment: "A button that allows the user to save a path to a destination.")

        /// Creating a button that can be used to start the creation of a single use route.
        recordPathButton = UIButton(type: .custom)
        recordPathButton.layer.cornerRadius = 0.75 * addAnchorPointButton.bounds.size.width
        recordPathButton.clipsToBounds = true
        recordPathButton.translatesAutoresizingMaskIntoConstraints = false
        recordPathButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        recordPathButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        recordPathButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        recordPathButton.imageView?.contentMode = .scaleAspectFit
        recordPathButton.addLargeTitle(NSLocalizedString("singleUseRouteButtonText", comment: "This is the text which appears on the single use route buttton"))
        recordPathButton.accessibilityLabel = NSLocalizedString("recordSingleUseRouteButtonAccessibilityLabel", comment: "A button that allows the user to navigate a route one time.")

        /// Creating a button that can be used to access the saved routes list.
        routesButton = UIButton(type: .custom)
        routesButton.layer.cornerRadius = 0.75 * routesButton.bounds.size.width
        routesButton.clipsToBounds = true
        routesButton.translatesAutoresizingMaskIntoConstraints = false
        routesButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        routesButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        routesButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        routesButton.imageView?.contentMode = .scaleAspectFit
        routesButton.addLargeTitle(NSLocalizedString("savedRoutesListButtonText", comment: "This is the text which appears on the Saved routes List buttton"))
        routesButton.accessibilityLabel = NSLocalizedString("savedRoutesListButtonAccessibilityLabel", comment: "The accessibility tag for a button which opens a menu which displays all the saved routes created by the user.")
        
        /// Creating a button that can be used to navigate to a bus stop
        busStopButton = UIButton(type: .custom)
        busStopButton.layer.cornerRadius = 0.75 * routesButton.bounds.size.width
        busStopButton.clipsToBounds = true
        busStopButton.translatesAutoresizingMaskIntoConstraints = false
        busStopButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        busStopButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        busStopButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        busStopButton.imageView?.contentMode = .scaleAspectFit
        busStopButton.addLargeTitle(NSLocalizedString("busStopButtonText", comment: "This is the text which appears on the bust stop buttton"))
//        busStopButton.accessibilityLabel = NSLocalizedString("savedRoutesListButtonAccessibilityLabel", comment: "The accessibility tag for a button which opens a menu which displays all the saved routes created by the user.")
        
        /// Creating a button that can be used to navigate to a bus stop
        busStopTwoButton = UIButton(type: .custom)
        busStopTwoButton.layer.cornerRadius = 0.75 * routesButton.bounds.size.width
        busStopTwoButton.clipsToBounds = true
        busStopTwoButton.translatesAutoresizingMaskIntoConstraints = false
        busStopTwoButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        busStopTwoButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        busStopTwoButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        busStopTwoButton.imageView?.contentMode = .scaleAspectFit
        busStopTwoButton.addLargeTitle(NSLocalizedString("busStopTwoButtonText", comment: "This is the text which appears on the bus stop button"))
        
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
        stackView.addArrangedSubview(busStopButton)
//        stackView.addArrangedSubview(busStopTwoButton)

        
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
            busStopButton.addTarget(parent, action: #selector(ViewController.findBusStopPressed), for: .touchUpInside)
            //busStopTwoButton.addTarget(parent, action: #selector(ViewController.findBusStop), for: .touchUpInside)

        }
    }

//    @objc func showBusStopView(_ sender: UIButton) {
//        if let button = sender as? UIButton {
//            if button == busStopButton {
//                let busStopViewController = BusStopViewController()
//                busStopViewController.modalTransitionStyle = .flipHorizontal
//                present(busStopViewController, animated: true, completion: nil)
//            }
//        }
//    }
}
