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
    
    /// Button for snapping to route
    var snapToRouteButton: UIButton!

    /// A view to act as filler to make the stack view layout look good
    var fillerSpace: UIView!
    
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
 
        stopNavigationButton = UIButton.makeConstraintButton(view,
                                                        alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                        appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "StopNavigation")!),
                                                        label: NSLocalizedString("Stop navigation", comment: "The name of the button that allows user to stop navigating."))
        
        
        snapToRouteButton = UIButton.makeConstraintButton(view,
                                                     alignment: UIConstants.ButtonContainerHorizontalAlignment.right,
                                                     appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Align")!),
                                                     label: NSLocalizedString("Snap to route", comment: "The name of the button that allows user to snap to route."))
        
        fillerSpace = UIView()
        fillerSpace.translatesAutoresizingMaskIntoConstraints = false
        /// set width of button and constaint height to be equal to width
        fillerSpace.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 3.50).isActive = true
        fillerSpace.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 3.50).isActive = true
        
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
        stackView.addArrangedSubview(fillerSpace)
        stackView.addArrangedSubview(stopNavigationButton)
        stackView.addArrangedSubview(snapToRouteButton)

        /// size the stack
        stackView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.yButtonFrameMargin).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.yButtonFrameMargin).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        if let parent: UIViewController = parent {
            stopNavigationButton.addTarget(parent,
                                            action: #selector(ViewController.stopNavigation),
                                            for: .touchUpInside)
        }
        
        if let parent: UIViewController = parent {
            snapToRouteButton.addTarget(parent,
                                        action: #selector(ViewController.snapToRoute),
                                        for: .touchUpInside)
        }
    }
}
