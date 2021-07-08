//
//  SetTagController.swift
//  Clew
//
//  Created by Berwin Lan on 7/7/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import UIKit
import ARKit

/// A view controller for handling the route saving app clip code ID linking process.
class SetTagController: UIViewController, UITextFieldDelegate {
    
    /// button for finalizing the name of the app clip code
    var saveRouteButton: UIButton!
    
    /// Label for description of what to do to link your route
    var label: UILabel!
    
    /// Text Field for typing the app clip code ID you want to save your route to.
    var textField: UITextField!
    
    /// The ARWorldMap to associate with this route
    var worldMap: Any?
    
    override func viewDidAppear(_ animated: Bool){
        super.viewDidAppear(animated)
        
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        saveRouteButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
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
        
        /// Creating a button that can be used to save the name of your route
        saveRouteButton = UIButton(type: .custom)
        saveRouteButton.layer.cornerRadius = 0.5 * saveRouteButton.bounds.size.width
        saveRouteButton.clipsToBounds = true
        saveRouteButton.translatesAutoresizingMaskIntoConstraints = false
        saveRouteButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        saveRouteButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 2.5).isActive = true
        saveRouteButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        saveRouteButton.imageView?.contentMode = .scaleAspectFit
        saveRouteButton.setTitle(NSLocalizedString("saveARouteButtonText", comment: "This is the text which appears on the save a route buttton"),for: .normal)
        saveRouteButton.setTitleColor(.black, for: .normal)
        saveRouteButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 35)!
        saveRouteButton.accessibilityLabel = NSLocalizedString("saveARouteButtonAccessibilityLabel", comment: "A button that allows the user to save a path to a destination.")
        saveRouteButton.titleLabel?.textAlignment = .center
        saveRouteButton.titleLabel?.numberOfLines = 0
        saveRouteButton.titleLabel?.lineBreakMode = .byWordWrapping
        saveRouteButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        saveRouteButton.titleEdgeInsets.top = 0
        saveRouteButton.titleEdgeInsets.left = 5
        saveRouteButton.titleEdgeInsets.bottom = 0
        saveRouteButton.titleEdgeInsets.right = 5
        
        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let mainText = NSLocalizedString("nameSavedRouteLabel", comment: "Message displayed to the user when saving a route by name.")
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.preferredFont(forTextStyle: .title1)
        label.text = mainText
        label.tag = UIView.mainTextTag
        label.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        
    
        textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        textField.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 8).isActive = true
        textField.placeholder = NSLocalizedString("nameSavedRouteTextField", comment: "Message displayed to the user when typing to save a route by name.")
        textField.borderStyle = .roundedRect
        textField.font = UIFont.preferredFont(forTextStyle: .body)
    
    
        textField.delegate = self
        
        let scrollView = UIScrollView()

        /// allow for constraints to be applied to label, scrollview
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.indicatorStyle = .white;

        /// add scrollview height constraint
        scrollView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width/2.5).isActive = true
        scrollView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width).isActive = true


        /// create stack view for aligning and distributing bottom layer buttons
        let stackView   = UIStackView()
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
        stackView.addArrangedSubview(saveRouteButton)
    
        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 150).isActive = true
    
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    
    
        saveRouteButton.addTarget(parent,
                                  action: #selector(ViewController.saveRouteButtonPressed),
                           for: .touchUpInside)
    }
    
    
}

