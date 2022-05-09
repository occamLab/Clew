//
//  NameCodeIDController.swift
//  Clew
//
//  Created by Berwin Lan on 7/7/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

// DEPRECATED 7/2021, use NameCodeIDController instead.

import UIKit
import ARKit

/// A view controller for handling the route saving naming process.
class NameCodeIDController: UIViewController, UITextFieldDelegate {
    
    /// button for finalizing your saved route name
    var saveCodeIDButton: UIButton!
    
    /// Label for description of what to do to name your route
    var label: UILabel!
    
    /// Text Field for typing the name you want to save your route as.
    var textField: UITextField!
    
    /// The ARWorldMap to associate with this route
    var worldMap: Any?
    
    override func viewDidAppear(_ animated: Bool){
        super.viewDidAppear(animated)
        
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        saveCodeIDButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
    }
    
    
    @objc func dismissKeyboard(){
        view.endEditing(true)
    }

    /// Get keyboard to disappear
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.textField.endEditing(true)
        return true
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        /// Creating a view that allows buttons to be tapped through it.
        // we subtract one pixel from the height to prevent accessibility elements in the parent view from being hidden (Warning: this is not documented behavior, so we may need to revisit this down the road)
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.size.width,
                                                 height: UIScreen.main.bounds.size.height - 1))
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        func dismissKeyboard(){
            view.endEditing(true)
        }
        let scrollView = UIScrollView()

        /// allow for constraints to be applied to label, scrollview
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.indicatorStyle = .white;

        /// add scrollview height constraint
        scrollView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width/2.5).isActive = true
        scrollView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width).isActive = true


        /// create stack view for aligning and distributing bottom layer buttons
        let stackView = UIStackView()
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        
        
        /// define horizonal, centered, and equal alignment of elements
        /// inside the bottom stack
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        
        /// add elements to the stack and scroll views
        
        scrollView.addSubview(label)
        
        label.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8.0).isActive = true
        label.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 8.0).isActive = true
        label.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -8.0).isActive = true
        label.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8.0).isActive = true

        stackView.addArrangedSubview(scrollView)
        stackView.addArrangedSubview(textField)
        stackView.addArrangedSubview(saveCodeIDButton)
    
        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 150).isActive = true
    
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    
    
        saveCodeIDButton.addTarget(parent,
                                  action: #selector(ViewController.saveCodeIDButtonPressed),
                           for: .touchUpInside)
    }
    
    
}

