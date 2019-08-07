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

        recordPathButton = UIButton.makeConstraintButton(view,
                                                    alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                    appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Record")!),
                                                    label: NSLocalizedString("Save a route", comment: "A button that allows user to video save a path to a destination"))
        
        addAnchorPointButton = UIButton.makeConstraintButton(view,
                                                     alignment: UIConstants.ButtonContainerHorizontalAlignment.right,
                                                     appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "Landmark")!),
                                                     label: NSLocalizedString("Record a single use route", comment: "A button that allows the user to navigate a route one time."))
        
        routesButton = UIButton.makeConstraintButton(view,
                                                alignment: UIConstants.ButtonContainerHorizontalAlignment.left,
                                                appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "route")!),
                                                label: NSLocalizedString("Saved routes list", comment: "A button that opens a menu which displays all the saved routes created by the user"))
        
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
        stackView.addArrangedSubview(routesButton)
        stackView.addArrangedSubview(recordPathButton)
        stackView.addArrangedSubview(addAnchorPointButton)
        
        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.yButtonFrameMargin).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.yButtonFrameMargin).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12).isActive = true
        
        if let parent: UIViewController = parent {
            routesButton.addTarget(parent,
                                          action: #selector(ViewController.routesButtonPressed),
                                          for: .touchUpInside)
            addAnchorPointButton.addTarget(parent,
                                          action: #selector(ViewController.startCreateAnchorPointProcedure),
                                          for: .touchUpInside)
            recordPathButton.addTarget(parent,
                                          action: #selector(ViewController.recordPath),
                                          for: .touchUpInside)
        }
    }
}
