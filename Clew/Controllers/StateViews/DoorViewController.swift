//
//  DoorViewController.swift
//  Clew
//
//  Created by Olin Candidate on 3/24/23.
//  Copyright © 2023 OccamLab. All rights reserved.
//

import UIKit
import ARKit
import ARCoreGeospatial

class DoorViewController: UIViewController, ARSessionManagerObserver {
    var closestDoors: [Door] = []
    
    
    /// button for closest bus stop
    var doorOneButton: UIButton!
    
    /// button for second closest bus stop
    var doorTwoButton: UIButton!
    
    let doorDataModel = DoorDataModel.shared
    
    var buttonsHaveNames = false
    
    /// This function is called by the ARSessionManager whenever the geo location is updated
    /// - Parameter cameraGeoSpatialTransform: this provides lat, long, heading, altitude as well as confidence bands
    func locationDidUpdate(cameraGeoSpatialTransform: GARGeospatialTransform) {
        let currentLatLon = cameraGeoSpatialTransform.coordinate
//        print("got a new lat lon in the bus stop view controller \(currentLatLon)")
        if !buttonsHaveNames {
            AnnouncementManager.shared.announce(announcement: "Localized")
            let closestTwoDoors = doorDataModel.getClosestDoors(to: currentLatLon)
            doorOneButton.addLargeTitle(closestTwoDoors[0].name)
            doorTwoButton.addLargeTitle(closestTwoDoors[1].name)
            buttonsHaveNames = true
        }
    
    }

    
    override func viewWillAppear(_ animated: Bool) {
        // listen for to the ARSessionManager
        ARSessionManager.shared.observer = self
    }
    
    /// called when view appears (any time)
    override func viewDidAppear(_ animated: Bool) {
        /// set thumbsUpButton as initially active voiceover button
        doorOneButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        doorTwoButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AnnouncementManager.shared.announce(announcement: "Localizing")
        
        //view.backgroundColor = .white
        self.modalPresentationStyle = .fullScreen
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: UIScreen.main.bounds.size.height*0.2+30,
                                                 width: UIConstants.buttonFrameWidth * 1,
                                                 height: UIScreen.main.bounds.size.height*0.7-30))
        
        doorOneButton = UIButton(type: .custom)
        doorOneButton.layer.cornerRadius = 0.75 * doorOneButton.bounds.size.width
        doorOneButton.clipsToBounds = true
        doorOneButton.translatesAutoresizingMaskIntoConstraints = false
        doorOneButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        doorOneButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        doorOneButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        doorOneButton.imageView?.contentMode = .scaleAspectFit
        doorOneButton.addLargeTitle(NSLocalizedString("Localizing...", comment: "This is the text which appears on the door one buttton"))
        // add tag so we can send over to ViewController
        doorOneButton.tag = 0
        
        doorTwoButton = UIButton(type: .custom)
        doorTwoButton.layer.cornerRadius = 0.75 * doorTwoButton.bounds.size.width
        doorTwoButton.clipsToBounds = true
        doorTwoButton.translatesAutoresizingMaskIntoConstraints = false
        doorTwoButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width / 1.1).isActive = true
        doorTwoButton.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.height / 5).isActive = true
        doorTwoButton.setBackgroundImage(UIImage(named: "WhiteButtonBackground"), for: .normal)
        doorTwoButton.imageView?.contentMode = .scaleAspectFit
        doorTwoButton.addLargeTitle(NSLocalizedString("Localizing...", comment: "This is the text which appears on the door two buttton"))
        // add tag so we can send over to ViewController
        doorTwoButton.tag = 1
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
        stackView.addArrangedSubview(doorOneButton)
        stackView.addArrangedSubview(doorTwoButton)
        
        /// size the stack
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        
        
        if let parent: UIViewController = parent {
            
            doorOneButton.addTarget(parent, action: #selector(ViewController.navigateToDoor), for: .touchUpInside)
            doorTwoButton.addTarget(parent, action: #selector(ViewController.navigateToDoor), for: .touchUpInside)
        }
        
    }
    
}

