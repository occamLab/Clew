//
//  ChooseAnchorMethodController.swift
//  Clew
//
//  Created by Paul Ruvolo on 11/9/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import UIKit

enum AnchorType {
    case beginRouteAnchorPoint
    case endRouteAnchorPoint
    case pauseRouteAnchorPoint
}

/// A View Controller for handling the pause route state
/// also handles associated buttons
class ChooseAnchorMethodController: UIViewController, UIScrollViewDelegate {

    /// button for choosing visual alignment
    var visualAlignment: UIButton!
    
    /// button for choosing physical (legacy) alignment
    var physicalAlignment: UIButton!
    
    /// anchor type
    var anchorType: AnchorType!
    
    /// text label for the state
    var label: UILabel!
    
    /// called when the view loads (any time)
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// label details
        var mainText : String
    
        switch anchorType {
        case .beginRouteAnchorPoint:
            mainText = NSLocalizedString("chooseAlignmentMethodStartAnchor", comment: "This text explains the choice of visual versus conventional alignment in the context of recording the starting anchor point")
        case .endRouteAnchorPoint:
            mainText = NSLocalizedString("chooseAlignmentMethodEndAnchor", comment: "This text explains the choice of visual versus conventional alignment in the context of recording the ending anchor point")
        case .pauseRouteAnchorPoint:
            mainText = NSLocalizedString("chooseAlignmentMethodPauseAnchor", comment: "This text explains the choice of visual versus conventional alignment in the context of recording a pause anchor point")
        case .none:
            mainText = ""
            break
        }
        
        label.text = mainText
        
        /// set confirm alignment button as initially active voiceover button
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: label)
    }
    
    /// called when the view has loaded the first time.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// create a main view which passes touch events down the hierarchy
        // we subtract one pixel from the height to prevent accessibility elements in the parent view from being hidden (Warning: this is not documented behavior, so we may need to revisit this down the road)
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.size.width,
                                                 height: UIScreen.main.bounds.size.height - 1))
        
        /// create a label, and a scrollview for it to live in
        label = UILabel()
        let scrollView = UIScrollView()
        
        /// allow for constraints to be applied to label, scrollview
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.indicatorStyle = .white;
        label.translatesAutoresizingMaskIntoConstraints = false
        
        /// darken background of view
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.tag = UIView.mainTextTag
        
        /// place label inside of the scrollview
        scrollView.addSubview(label)
        view.addSubview(scrollView)

        /// set top, left, right constraints on scrollView to
        /// "main" view + 8.0 padding on each side
        scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIScreen.main.bounds.size.height*0.2+30).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8.0).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8.0).isActive = true
        
        /// set the height constraint on the scrollView to 0.25 * the main view height
        scrollView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.25).isActive = true
        
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

        /// Creating a button that can be used to select visual alignment
        visualAlignment = UIButton(type: .custom)
        visualAlignment.layer.cornerRadius = 0.75 * visualAlignment.bounds.size.width
        visualAlignment.clipsToBounds = true
        visualAlignment.translatesAutoresizingMaskIntoConstraints = false
        visualAlignment.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        visualAlignment.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 10).isActive = true
        visualAlignment.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        visualAlignment.imageView?.contentMode = .scaleAspectFit
        visualAlignment.addLargeTitle("Visual Anchor")
        
       // visualAlignment.setImage(UIImage(named: "visualAlignment"), for: .normal)
        /*visualAlignment.imageEdgeInsets =  UIEdgeInsets(top: UIScreen.main.bounds.size.height/40, left: UIScreen.main.bounds.size.height/40, bottom: UIScreen.main.bounds.size.height/40, right: UIScreen.main.bounds.size.height/40)*/
        visualAlignment.accessibilityLabel = NSLocalizedString("createVisualAnchorPointButtonAccessibilityLabel", comment: "This is the accessibility label for the button that starts the creation of a physical anchor point.")
        
        /// Creating a button that can be used to select visual alignment
        physicalAlignment = UIButton(type: .custom)
        physicalAlignment.layer.cornerRadius = 0.75 * visualAlignment.bounds.size.width
        physicalAlignment.clipsToBounds = true
        physicalAlignment.translatesAutoresizingMaskIntoConstraints = false
        physicalAlignment.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        physicalAlignment.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 10).isActive = true
        physicalAlignment.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        physicalAlignment.imageView?.contentMode = .scaleAspectFit
        physicalAlignment.addLargeTitle("Physical Anchor")

        
//        physicalAlignment.setImage(UIImage(named: "physicalAlignment"), for: .normal)
//        physicalAlignment.imageEdgeInsets =  UIEdgeInsets(top: UIScreen.main.bounds.size.height/40, left: UIScreen.main.bounds.size.height/40, bottom: UIScreen.main.bounds.size.height/40, right: UIScreen.main.bounds.size.height/40)
        physicalAlignment.accessibilityLabel = NSLocalizedString("createPhysicalAnchorPointButtonAccessibilityLabel", comment: "This is the accessibility label for the button that starts the creation of a physical anchor point.")
        
        /// create stack view for aligning and distributing bottom layer buttons
        let stackView = UIStackView()
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        
        /// define horizonal, centered, and equal alignment of elements
        /// inside the bottom stack
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.fillEqually
        stackView.alignment = UIStackView.Alignment.center
        stackView.spacing = UIScreen.main.bounds.size.height/30
        
        /// add elements to the stack
        stackView.addArrangedSubview(visualAlignment)
        stackView.addArrangedSubview(physicalAlignment)
        
        scrollView.flashScrollIndicators()

        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.yButtonFrameMargin).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.yButtonFrameMargin).isActive = true
        stackView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 10).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.topAnchor, constant: UIConstants.yOriginOfButtonFrame + UIConstants.buttonFrameHeight - UIConstants.yButtonFrameMargin).isActive = true
        /// set function targets for the functions in this state
        if let parent = parent as? ViewController {
            visualAlignment.addTarget(parent, action: #selector(ViewController.setVisualAlignment), for: .touchUpInside)
            physicalAlignment.addTarget(parent, action: #selector(ViewController.setPhysicalAlignment), for: .touchUpInside)
        }
    }
}
