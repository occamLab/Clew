//
//  HeaderView.swift
//  Clew
//
//  Created by Timothy Novak on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import UIKit

///creates a class which describes what its delegate can do
protocol HeaderViewDelegate: class {
    func toggleSection(header: HeaderView, section: Int)
}

///creates the main header class
class HeaderView: UITableViewHeaderFooterView {
    
    ///creates a section in the Help Table
    var item: HelpViewModelItem? {
        didSet {
            ///if the item can't be created quit
            guard let item = item else {
                return
            }
            
            ///set the label on the header to be the section label from the HelpTable item
            titleLabel?.text = item.sectionTitle
            ///makes sure the default condition is collapsed
            setCollapsed(collapsed: item.isCollapsed)
        }
    }
    
    //MARK: Outlets
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var arrowLabel: UILabel?
    
    
    //MARK: Private Variables
    var section: Int = 0
    
    weak var delegate: HeaderViewDelegate?
    
    ///Creages a user iterface handle (references the xib file and retrieves the identifier and the bundle
    static var nib:UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    ///Finds the identifier tfor the Header View
    static var identifier: String {
        return String(describing: self)
    }
    
    ///Akin to on view did load()
    override func awakeFromNib() {
        ///call default functionality
        super.awakeFromNib()
        ///add a tap guesture recognizer to handle user interaction
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapHeader)))
        
        ///removes the accessability label form the arrow pointer because the autogenerated accessability label was having errors
        arrowLabel?.isAccessibilityElement = false
        ///sets the accessability label for the words to describe how they are both headinga and buttons
        titleLabel?.accessibilityTraits = [.header, .button]

    }
    
    ///what happens when the button is tapped
    @objc private func didTapHeader() {
        ///calls the delegate's togleSection method
        delegate?.toggleSection(header: self, section: section)
    }
    
    ///sets the visual state of the arrow to display collapsed and not collapsed states
    func setCollapsed(collapsed: Bool) {
        arrowLabel?.rotate(collapsed ? 0.0 : .pi)
    }
}

///handels the arrow rotation
extension UIView {
    
    func rotate(_ toValue: CGFloat, duration: CFTimeInterval = 0.2) {
        ///creates an animation
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        
        ///sets the properties of the animation
        animation.toValue = toValue
        animation.duration = duration
        
        ///whether or not the object dissapears on completion of animation
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        
        self.layer.add(animation, forKey: nil)
    }
    
}
