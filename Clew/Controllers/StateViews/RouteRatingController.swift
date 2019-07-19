//
//  RouteRatingController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

/// A View Controller for handling rating the app
/// functionality and route that was just navigated
class RouteRatingController: UIViewController {

    /// a button for rating a path navigation positively
    var thumbsDownButton: UIButton!

    /// a button for rating a path navigation negatively
    var thumbsUpButton: UIButton!
    
    /// text label for the state
    var label: UILabel!
    
    /// called when the view loads (any time)
    override func viewDidAppear(_ animated: Bool) {
        /// update label font
        /// TODO: is this a safe implementation? Might crash if label has no body, unclear.
        label.font = UIFont.preferredFont(forTextStyle: .body)
        
        /// set thumbsUpButton as initially active voiceover button
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.thumbsUpButton)

    }
    
    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()

        view.frame = CGRect(x: 0,
                            y: 0,
                            width: UIConstants.buttonFrameWidth,
                            height: UIScreen.main.bounds.size.height)
        
//        let label = UILabel(frame: CGRect(x: 15,
//                                          y: UIScreen.main.bounds.size.height/5,
//                                          width: UIScreen.main.bounds.size.width-30,
//                                          height: UIScreen.main.bounds.size.height/2))
        
        label = UILabel()
        let scrollView = UIScrollView()

        /// allow for constraints to be applied to label, scrollview
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.indicatorStyle = .white;
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        let mainText = NSLocalizedString("Please rate your service.", comment: "Message for user")
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
        
        
        thumbsDownButton = UIButton.makeConstraintButton(view,
                                                    alignment: UIConstants.ButtonContainerHorizontalAlignment.leftcenter,
                                                    appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "thumbs_down")!),
                                                    label: NSLocalizedString("Bad", comment: "Unsatisfactory service"))
        thumbsUpButton = UIButton.makeConstraintButton(view,
                                                  alignment: UIConstants.ButtonContainerHorizontalAlignment.rightcenter,
                                                  appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "thumbs_up")!),
                                                  label: NSLocalizedString("Good", comment: "Satisfactory service"))
        
        let fillerSpace = UIView()
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
//        stackView.distribution = UIStackView.Distribution.fillEqually
        stackView.alignment = UIStackView.Alignment.center
        
        /// add elements to the stack
        stackView.addArrangedSubview(thumbsDownButton)
        stackView.addArrangedSubview(fillerSpace)
        stackView.addArrangedSubview(thumbsUpButton)
        
        /// size the stack
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIScreen.main.bounds.size.height * (2/3)).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.yButtonFrameMargin).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.yButtonFrameMargin).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UIConstants.buttonFrameWidth/7 * 2).isActive = true
        

        if let parent: UIViewController = parent {
            thumbsUpButton.addTarget(parent,
                                     action: #selector(ViewController.sendLogData),
                                     for: .touchUpInside)
            thumbsDownButton.addTarget(parent,
                                       action: #selector(ViewController.sendDebugLogData),
                                       for: .touchUpInside)
        }
    }
}
