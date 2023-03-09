//
//  BusStopViewController.swift
//  Clew
//
//  Created by Olin Candidate on 3/2/23.
//  Copyright © 2023 OccamLab. All rights reserved.
//

import UIKit
import ARKit
import ARCoreGeospatial

class BusStopViewController: UIViewController, ARSessionManagerObserver {
    var closestStops: [BusStop] = []
    
//    required init?(coder decoder: NSCoder, closestStops: [BusStop]) {
//            self.closestStops = closestStops
//            super.init(coder: decoder)
//            print("BUS STOP VIEW CONTROLLER \(self.closestStops)")
//
//        }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    

    
    /// button for closest bus stop
    var busStopOneButton: UIButton!
    
    /// button for second closest bus stop
    var busStopTwoButton: UIButton!
    
    let busStopDataModel = BusStopDataModel.shared
    
    /// This function is called by the ARSessionManager whenever the geo location is updated
    /// - Parameter cameraGeoSpatialTransform: this provides lat, long, heading, altitude as well as confidence bands
    func locationDidUpdate(cameraGeoSpatialTransform: GARGeospatialTransform) {
        let currentLatLon = cameraGeoSpatialTransform.coordinate
        print("got a new lat lon in the bus stop view controller \(currentLatLon)")
    }

    
    override func viewWillAppear(_ animated: Bool) {
        // listen for to the ARSessionManager
        ARSessionManager.shared.observer = self
    }
    
    /// called when view appears (any time)
    override func viewDidAppear(_ animated: Bool) {
        /// set thumbsUpButton as initially active voiceover button
        busStopOneButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        busStopTwoButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //view.backgroundColor = .white
        self.modalPresentationStyle = .fullScreen
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: UIScreen.main.bounds.size.height*0.2+30,
                                                 width: UIConstants.buttonFrameWidth * 1,
                                                 height: UIScreen.main.bounds.size.height*0.7-30))
        
        busStopOneButton = UIButton(type: .custom)
        busStopOneButton.layer.cornerRadius = 0.75 * busStopOneButton.bounds.size.width
        busStopOneButton.clipsToBounds = true
        busStopOneButton.translatesAutoresizingMaskIntoConstraints = false
        busStopOneButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        busStopOneButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        busStopOneButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        busStopOneButton.imageView?.contentMode = .scaleAspectFit
        busStopOneButton.addLargeTitle(NSLocalizedString("busStopOneButtonText", comment: "This is the text which appears on the bus stop one buttton"))
        // add tag so we can send over to ViewController
        busStopOneButton.tag = 0
        
        busStopTwoButton = UIButton(type: .custom)
        busStopTwoButton.layer.cornerRadius = 0.75 * busStopTwoButton.bounds.size.width
        busStopTwoButton.clipsToBounds = true
        busStopTwoButton.translatesAutoresizingMaskIntoConstraints = false
        busStopTwoButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        busStopTwoButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        busStopTwoButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        busStopTwoButton.imageView?.contentMode = .scaleAspectFit
        busStopTwoButton.addLargeTitle(NSLocalizedString("busStopTwoButtonText", comment: "This is the text which appears on the bus stop two buttton"))
        // add tag so we can send over to ViewController
        busStopTwoButton.tag = 1
        //busStopTwoButton.setTitle(closestBusStops[1].Stop_name)
        
        let stackView   = UIStackView()
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        
        /// define horizonal, centered, and equal alignment of elements
        /// inside the bottom stack
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        
        /// add elements to the stack
        stackView.addArrangedSubview(busStopOneButton)
        stackView.addArrangedSubview(busStopTwoButton)
        
        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        
        
        if let parent: UIViewController = parent {
            
            busStopOneButton.addTarget(parent, action: #selector(ViewController.navigateToBusStop), for: .touchUpInside)
            busStopTwoButton.addTarget(parent, action: #selector(ViewController.navigateToBusStop), for: .touchUpInside)
        }
        
    }
    
//    func updateButtonText(closestStops: [BusStop]) {
    func updateButtonText(text: String) {
        busStopOneButton.addLargeTitle(text)
    }
}
