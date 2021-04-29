//
//  StopNavigationController.swift
//  Clew
//
//  Created by Dieter Brehm on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.


import UIKit
import SwiftUI // for z-stack

extension UIBezierPath {
    func createArrow(omega: CGFloat) {

        let arrow_length = CGFloat(60)
        let x = arrow_length*sin(omega)
        let y = arrow_length*cos(omega)
        let centerX = UIConstants.buttonFrameWidth/2
        let centerY = UIConstants.buttonFrameHeight/2 - 100
        let start = CGPoint(x: centerX-x, y: centerY+y)
        let end = CGPoint(x: centerX+x, y: centerY-y)

        self.move(to: start)
        self.addLine(to: end)

        let pointerLineLength = CGFloat(35)      // length of arrow head
        let arrowAngle = CGFloat(Double.pi / 4) // angle of head to body
        let startEndAngle = atan((end.y - start.y) / (end.x - start.x)) + ((end.x - start.x) < 0 ? CGFloat(Double.pi) : 0)
        let arrowHeadSide1 = CGPoint(x: end.x + pointerLineLength * cos(CGFloat(Double.pi) - startEndAngle + arrowAngle), y: end.y - pointerLineLength * sin(CGFloat(Double.pi) - startEndAngle + arrowAngle))
        let arrowHeadSide2 = CGPoint(x: end.x + pointerLineLength * cos(CGFloat(Double.pi) - startEndAngle - arrowAngle), y: end.y - pointerLineLength * sin(CGFloat(Double.pi) - startEndAngle - arrowAngle))

        self.addLine(to: arrowHeadSide1)
        self.move(to: end)
        self.addLine(to: arrowHeadSide2)
    }
    
    func createInnerArrow(omega: CGFloat) {

        let arrow_height = CGFloat(75)
        let x = arrow_height*sin(omega)
        let y = arrow_height*cos(omega)
        let centerX = UIConstants.buttonFrameWidth/2
        let centerY = UIConstants.buttonFrameHeight/2
        let start = CGPoint(x: centerX-x, y: centerY+y)
        let end = CGPoint(x: centerX+x, y: centerY-y)

        let sideLength = CGFloat(50)      // length of triangle sides
        let arrowAngle = CGFloat(Double.pi / 4.5) // angle of triangle tip
        let arrowTipAngle = atan((end.y - start.y) / (end.x - start.x)) + ((end.x - start.x) < 0 ? CGFloat(Double.pi) : 0)
        let leftCorner = CGPoint(x: end.x + sideLength * cos(CGFloat(Double.pi) - arrowTipAngle + arrowAngle), y: end.y - sideLength * sin(CGFloat(Double.pi) - arrowTipAngle + arrowAngle))
        let rightCorner = CGPoint(x: end.x + sideLength * cos(CGFloat(Double.pi) - arrowTipAngle - arrowAngle), y: end.y - sideLength * sin(CGFloat(Double.pi) - arrowTipAngle - arrowAngle))

        self.move(to: leftCorner)
        self.addLine(to: end)
        self.addLine(to: rightCorner)
        self.addLine(to: leftCorner)
    }
}

/// A View Controller for handling the stop navigation state
class StopNavigationController: UIViewController {

    /// button for stopping route navigation
    var stopNavigationButton: UIButton!

    /// 2D arrow directing user to pathpoint
//    let imageView_arrow = UIImageView(image: UIImage(named: "Arrow"))

    /// BezierPath Arrow
    let arrow = UIBezierPath()

    func addArrowProperties(arrowLayer: CAShapeLayer) {
        arrowLayer.strokeColor = UIColor.red.cgColor
        arrowLayer.lineWidth = 25
        arrowLayer.path = arrow.cgPath
        arrowLayer.fillColor = UIColor.red.cgColor
        arrowLayer.lineJoin = CAShapeLayerLineJoin.round // joins arrow head and body
        arrowLayer.lineCap = CAShapeLayerLineCap.round   // rounds edges
        
//        arrowLayer.strokeColor = UIColor.red.cgColor
//        arrowLayer.lineWidth = 25
//        arrowLayer.path = arrow.cgPath
//        arrowLayer.fillColor = UIColor.clear.cgColor // clear area between head and body
//        arrowLayer.lineJoin = CAShapeLayerLineJoin.round
//        arrowLayer.lineCap = CAShapeLayerLineCap.round
    }

    /// called when view appears
    override func viewDidAppear(_ animated: Bool) {
        /// set stopnavigationbutton as initially active voiceover button
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self.stopNavigationButton)
    }

    /// called when the view has loaded.  We setup various app elements in here.
    override func viewDidLoad() {
        super.viewDidLoad()

        view.frame = CGRect(x: 0,
//                            y: UIConstants.yOriginOfButtonFrame+80,
                            y: UIConstants.yOriginOfButtonFrame,
                            width: UIConstants.buttonFrameWidth,
                            height: UIConstants.buttonFrameHeight)

        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
//        view.layer.cornerRadius = 150

        // Create black circular frame
//        let circlePath = UIBezierPath(arcCenter: CGPoint(x: view.frame.width/2, y: view.frame.height/2 + 140), radius: CGFloat(300), startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)
//        let frameLayer = CAShapeLayer()
//        frameLayer.path = circlePath.cgPath
//        frameLayer.fillColor = UIColor(white: 0.0, alpha: 0.4).cgColor
//        view.layer.insertSublayer(frameLayer, at: 1)

        stopNavigationButton = UIButton.makeConstraintButton(view,
                                                        alignment: UIConstants.ButtonContainerHorizontalAlignment.center,
                                                        appearance: UIConstants.ButtonAppearance.imageButton(image: UIImage(named: "StopNavigation")!),
                                                        label: NSLocalizedString("stopNavigationButtonAccessibilityLabel", comment: "The accessibility label of the button that allows user to stop navigating."))

        /// create stack view for aligning and distributing bottom layer buttons
        let buttonStackView = UIStackView()
        view.addSubview(buttonStackView)

        buttonStackView.translatesAutoresizingMaskIntoConstraints = false;

        /// define horizonal, centered, and equal alignment of elements
        /// inside the bottom stack
        buttonStackView.axis = NSLayoutConstraint.Axis.horizontal
        buttonStackView.distribution  = UIStackView.Distribution.equalSpacing
        buttonStackView.alignment = UIStackView.Alignment.center

        /// add elements to the stack
        buttonStackView.addArrangedSubview(stopNavigationButton)

        /// Add arrowLayer as sublayer
        let arrowLayer = CAShapeLayer()
        addArrowProperties(arrowLayer: arrowLayer)
        view.layer.insertSublayer(arrowLayer, at: 0)

        /// size the stack
        buttonStackView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.yButtonFrameMargin).isActive = true
        buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.yButtonFrameMargin).isActive = true
        buttonStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        if let parent: UIViewController = parent {
            stopNavigationButton.addTarget(parent,
                                            action: #selector(ViewController.stopNavigation),
                                            for: .touchUpInside)
        }
    }
}
