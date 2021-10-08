//
//  StopNavigationController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.


import UIKit

/// A View Controller for handling the stop navigation state
class StopNavigationController: UIViewController {

    /// button for stopping route navigation
    var stopNavigationButton: UIButton!

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
                                                        alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                        appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "StopNavigation")!),
                                                        label: NSLocalizedString("stopNavigationButtonAccessibilityLabel", comment: "The accessibility label of the button that allows user to stop navigating."))

        /// create stack view for aligning and distributing bottom layer buttons
        let buttonStackView = UIStackView()
        view.addSubview(buttonStackView)

        buttonStackView.translatesAutoresizingMaskIntoConstraints = false;

        /// define horizonal, centered, and equal alignment of elements
        /// inside the bottom stack
        buttonStackView.axis = NSLayoutConstraint.Axis.horizontal
        buttonStackView.distribution  = UIStackView.Distribution.equalSpacing
        buttonStackView.alignment = UIStackView.Alignment.center

        /// add elements to the stack
        buttonStackView.addArrangedSubview(stopNavigationButton)

        /// size the stack
        buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.yButtonFrameMargin).isActive = true
        buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.yButtonFrameMargin).isActive = true
        
        buttonStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIConstants.yButtonFrameMargin).isActive = true
        buttonStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UIConstants.yButtonFrameMargin).isActive = true
        
        if let parent: UIViewController = parent {
            stopNavigationButton.addTarget(parent,
                                            action: #selector(ViewController.stopNavigation),
                                            for: .touchUpInside)
        }
    }
}
