//
//  StartNavigationController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

/// A View Controller for the starting navigation state
class StartNavigationController: UIViewController {

    /// button for beginning navigation along a route
    var startNavigationButton: UIButton!
    
    /// button for pausing navigation
    var pauseButton: UIButton!
    
    var stackView: UIStackView!
    
    var fillerSpace: UIView!

    /// called when view appears (any time)
    override func viewDidAppear(_ animated: Bool) {
        /// set thumbsUpButton as initially active voiceover button
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.startNavigationButton)
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
        
        var mainText : String?
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
        
        startNavigationButton = UIButton.makeConstraintButton(view,
                                                         alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                         appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "StartNavigation")!),
                                                         label: NSLocalizedString("Start navigation", comment: "The name of the button that allows user to start navigating."))
        
        pauseButton = UIButton.makeConstraintButton(view,
                                               alignment: UIConstants.ButtonContainerHorizontalAlignment.right,
                                               appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Pause")!),
                                               label: "Pause session")
        
        fillerSpace = UIView()
        fillerSpace.translatesAutoresizingMaskIntoConstraints = false
        /// set width of button and constaint height to be equal to width
        fillerSpace.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 3.50).isActive = true
        fillerSpace.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 3.50).isActive = true
        
        /// create stack view for aligning and distributing bottom layer buttons
        stackView = UIStackView()
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        
        /// define horizonal, centered, and equal alignment of elements
        /// inside the bottom stack
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        
        /// add elements to the stack
        stackView.addArrangedSubview(pauseButton)
        stackView.addArrangedSubview(startNavigationButton)
        stackView.addArrangedSubview(fillerSpace)
        
        /// size the stack
        stackView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.yButtonFrameMargin).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.yButtonFrameMargin).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        if let parent: UIViewController = parent {
            startNavigationButton.addTarget(parent,
                                   action: #selector(ViewController.startNavigation),
                                   for: .touchUpInside)
            pauseButton.tag = 0
            pauseButton.addTarget(parent,
                                        action: #selector(ViewController.startPauseProcedure),
                                        for: .touchUpInside)
        }
    }
}
