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
    
    /// button for creating a new landmark
    var addLandmarkButton: UIButton!

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
                            y: 0,
                            width: UIConstants.buttonFrameWidth * 1,
                            height: UIConstants.buttonFrameWidth * 1.5)

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

        
        let recordPathButton = UIButton(type: .custom)
            recordPathButton.layer.cornerRadius = 0.5 * recordPathButton.bounds.size.width
            recordPathButton.clipsToBounds = true
            recordPathButton.translatesAutoresizingMaskIntoConstraints = false
            recordPathButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
            recordPathButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 2.5).isActive = true
            recordPathButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
            recordPathButton.imageView?.contentMode = .scaleAspectFit
            recordPathButton.setTitle("Single Use Route",for: .normal)
            recordPathButton.setTitleColor(.black, for: .normal)
            recordPathButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 35)!
        

        

        
        let addLandmarkButton = UIButton(type: .custom)
        addLandmarkButton.layer.cornerRadius = 0.75 * addLandmarkButton.bounds.size.width
        addLandmarkButton.clipsToBounds = true
        addLandmarkButton.translatesAutoresizingMaskIntoConstraints = false
        addLandmarkButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        addLandmarkButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 2.5).isActive = true
        addLandmarkButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        addLandmarkButton.imageView?.contentMode = .scaleAspectFit
        addLandmarkButton.setTitle("Save a Route",for: .normal)
        addLandmarkButton.setTitleColor(.black, for: .normal)
        addLandmarkButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 35)!
        
        let routesButton = UIButton(type: .custom)
        routesButton.layer.cornerRadius = 0.75 * addLandmarkButton.bounds.size.width
        routesButton.clipsToBounds = true
        routesButton.translatesAutoresizingMaskIntoConstraints = false
        routesButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        routesButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 2.5).isActive = true
        routesButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        routesButton.imageView?.contentMode = .scaleAspectFit
        routesButton.setTitle("Saved Routes List",for: .normal)
        routesButton.setTitleColor(.black, for: .normal)
        routesButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 35)!
        
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
        stackView.addArrangedSubview(addLandmarkButton)
        stackView.addArrangedSubview(recordPathButton)
        stackView.addArrangedSubview(routesButton)
        
        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 115).isActive = true
        
        if let parent: UIViewController = parent {
            routesButton.addTarget(parent,
                                          action: #selector(ViewController.routesButtonPressed),
                                          for: .touchUpInside)
            addLandmarkButton.addTarget(parent,
                                          action: #selector(ViewController.startCreateLandmarkProcedure),
                                          for: .touchUpInside)
            recordPathButton.addTarget(parent,
                                          action: #selector(ViewController.recordPath),
                                          for: .touchUpInside)
        }
    }
}
