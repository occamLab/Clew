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

    var label: UILabel!

    /// called when view appears (any time)
    override func viewDidAppear(_ animated: Bool) {
        
        var mainText : String = "nil"
        if recordingSingleUseRoute{
            mainText = NSLocalizedString("singleUsePlayPauseViewText", comment: "Information displayed to the user on the play pause screen after they have recorded a single use route. This describes the functionality of the play and pause buttons.")
        } else {
            if isAutomaticAlignment {
                mainText = NSLocalizedString("automaticAlignmentPlayPauseViewText", comment: "Information displayed to the user on the play pause screen after they have sucessfully aligned to their route automatically.")
            }else {
                mainText = NSLocalizedString("multipleUseRoutePlayPauseViewText", comment: "Information displayed to the user on the play pause screen after they have just recorded a multiple use route. This describes the functionality of the play and pause buttons.")
            }
            
        }
        
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = mainText
        label.tag = UIView.mainTextTag
        label.font = UIFont.preferredFont(forTextStyle: .body)

        /// set thumbsUpButton as initially active voiceover button
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.startNavigationButton)
    }
    
    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// create a main view which passes touch events down the hierarchy
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.size.width,
                                                 height: UIScreen.main.bounds.size.height))
        
        /// create a label, and a scrollview for it to live in
        label = UILabel()
        let scrollView = UIScrollView()
        
        /// allow for constraints to be applied to label, scrollview
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.indicatorStyle = .white;
        label.translatesAutoresizingMaskIntoConstraints = false
        
        /// darken background of view
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        var mainText : String = "nil"
        if recordingSingleUseRoute{
            mainText = NSLocalizedString("singleUsePlayPauseViewText", comment: "Information displayed to the user on the play pause screen after they have recorded a single use route. This describes the functionality of the play and pause buttons.")
        } else {
            if isAutomaticAlignment {
                mainText = NSLocalizedString("automaticAlignmentPlayPauseViewText", comment: "Information displayed to the user on the play pause screen after they have sucessfully aligned to their route automatically.")
            }else {
                mainText = NSLocalizedString("multipleUseRoutePlayPauseViewText", comment: "Information displayed to the user on the play pause screen after they have just recorded a multiple use route. This describes the functionality of the play and pause buttons.")
            }
            
        }
        
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
        startNavigationButton = UIButton.makeConstraintButton(view,
                                                         alignment: UIConstants.ButtonContainerHorizontalAlignment.left,
                                                         appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "StartNavigation")!),
                                                         label: NSLocalizedString("startReturnNavigationButtonAccessabilityLabel", comment: "The accessability label for the button that allows user to start navigating back along their route."))
        
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
        stackView.addArrangedSubview(fillerSpace)
        stackView.addArrangedSubview(startNavigationButton)
        
        scrollView.flashScrollIndicators()
        
        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8.0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UIConstants.buttonFrameWidth/7 * 2).isActive = true

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
