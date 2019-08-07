//
//  ResumeTrackingController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

/// A View Controller for handling resuming a route navigation
class ResumeTrackingController: UIViewController {
    
    /// button for resuming navigation
    var resumeButton: UIButton!
    
    /// text label for the state
    var label: UILabel!
    
    /// called when the view loads (any time)
    override func viewDidAppear(_ animated: Bool) {
        /// update label font
        /// TODO: is this a safe implementation? Might crash if label has no body, unclear.
        label.font = UIFont.preferredFont(forTextStyle: .body)
        
        /// set resumeButton as initially active voiceover button
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.resumeButton)
    }

    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()

        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.size.width,
                                                 height: UIScreen.main.bounds.size.height))

        label = UILabel()
        let scrollView = UIScrollView()
        
        /// allow for constraints to be applied to label, scrollview
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.indicatorStyle = .white;
        label.translatesAutoresizingMaskIntoConstraints = false
        
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        let mainText = NSLocalizedString("resumeRouteViewText", comment: "A message displayed to the user when they have paused the route")
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = mainText
        label.tag = UIView.mainTextTag

        /// place label inside of the scrollview
        scrollView.addSubview(label)
        view.addSubview(scrollView)
        
        /// set top, left, right constraints on scrollView to
        /// "main" view + 8.0 padding on each side
        scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100.0).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8.0).isActive = true
        
        /// set the height constraint on the scrollView to 0.5 * the main view height
        scrollView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5).isActive = true
        
        /// set top, left, right AND bottom constraints on label to
        /// scrollView + 8.0 padding on each side
        label.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8.0).isActive = true
        label.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 8.0).isActive = true
        label.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -8.0).isActive = true
        label.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8.0).isActive = true
        
        /// set the width of the label to the width of the scrollView (-16 for 8.0 padding on each side)
        label.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -16.0).isActive = true
        
        /// configure label: Zero lines + Word Wrapping
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping

        
        /// The button that the allows the user to resume a paused route
        resumeButton = UIButton.makeConstraintButton(view,
                                                alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Resume")!),
                                                label: NSLocalizedString("resumePausedRouteBUttonAccessabilityLabel", comment: "Accesability label for button allowing the user to resume a paused route"))
        
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
        stackView.addArrangedSubview(resumeButton)
        
        scrollView.flashScrollIndicators()
        
        /// size the stack
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIScreen.main.bounds.size.height * (2/3)).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8.0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UIConstants.buttonFrameWidth/7 * 2).isActive = true
        
        if let parent: UIViewController = parent {
            resumeButton.addTarget(parent,
                                     action: #selector(ViewController.confirmResumeTracking),
                                     for: .touchUpInside)
        }
    }
}
