//
//  StopNavigationController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

/// A View Controller for handling the stop navigation state
class StopNavigationController: UIViewController {

    /// button for stopping route navigation
    var stopNavigationButton: UIButton!
    
    /// button for returing to path from detour
    var returnToPathButton: UIButton!
    
    /// pause button during navigation
    var pauseButton: UIButton!
    
    /// called when view appears
    override func viewDidAppear(_ animated: Bool) {
        /// set stopnavigationbutton as initially active voiceover button
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.stopNavigationButton)
    }
    
    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()

        view.frame = CGRect(x: 0,
                            y: UIConstants.yOriginOfButtonFrame,
                            width: UIConstants.buttonFrameWidth,
                            height: UIConstants.buttonFrameHeight)

        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
 
        stopNavigationButton = UIButton.makeConstraintButton(view,
                                                        alignment: UIConstants.ButtonContainerHorizontalAlignment.left,
                                                        appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "StopNavigation")!),
                                                        label: NSLocalizedString("stopNavigationButtonAccessibilityLabel", comment: "The accessibility label of the button that allows user to stop navigating."))
        // label needs to be fixed to be it's own detour label
        returnToPathButton = UIButton.makeConstraintButton(view,
                                                        alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                        appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "StartNavigation")!),
                                                        label: NSLocalizedString("startNavigationButtonAccessibilityLabel", comment: "The accessibility label of the button that allows user to start navigating a detour."))
        //change later
        pauseButton = UIButton.makeConstraintButton(view,
                                                        alignment: UIConstants.ButtonContainerHorizontalAlignment.right,
                                                        appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Pause")!),
                                                        label: NSLocalizedString("pauseButtonAccessibilityLabel", comment: "The accesssibility label of the button that allows user to start navigating a detour."))
        
        
    
        /// create stack view for aligning and distributing bottom layer buttons
        let stackView   = UIStackView()
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        
        /// define horizonal, centered, and equal alignment of elements
        /// inside the bottom stack
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        
        /// add elements to the stack
        
        stackView.addArrangedSubview(stopNavigationButton)
        stackView.addArrangedSubview(returnToPathButton)
        stackView.addArrangedSubview(pauseButton)
        
        /// size the stack
        stackView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.yButtonFrameMargin).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.yButtonFrameMargin).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        
        
        if let parent: UIViewController = parent {
            stopNavigationButton.addTarget(parent,
                                            action: #selector(ViewController.stopNavigation),
                                            for: .touchUpInside)
            returnToPathButton.addTarget(parent,
                                            action: #selector(ViewController.startRerouting),
                                            for: .touchUpInside)
            pauseButton.addTarget(parent,
                                  action: #selector(ViewController.startPauseProcedure),
                                  for: .touchUpInside)
        }        
    }
}
