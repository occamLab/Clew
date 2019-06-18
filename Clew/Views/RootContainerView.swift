//
//  RootContainerView.swift
//  Clew
//
//  Created by Dieter Brehm on 6/10/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO
import AVFoundation
import AudioToolbox
import MediaPlayer
import VectorMath
import Firebase
import FirebaseDatabase
import SRCountdownTimer

class RootContainerView: UIView {

    // MARK: - UIViews for all UI button containers
    
    /// button for getting directions to the next keypoint
    var getDirectionButton: UIButton!
    
    /// button for bringing up the settings menu
    var settingsButton: UIButton!
    
    /// button for bringing up the help menu
    var helpButton: UIButton!
    
    // MARK: recordPathButton
    /// Image, label, and target for start recording button.
    
    let recordPathButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "StartRecording")!),
                                                  label: "Record path",
                                                  targetSelector: Selector.recordPathButtonTapped,
                                                  alignment: .center,
                                                  tag: 0)
    
    // MARK: thumbsDownButton
    /// The button that the allows the user to indicate a negative navigation experience
    let thumbsDownButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "thumbs_down")!),
                                                  label: "Bad",
                                                  targetSelector: Selector.thumbsDownButtonTapped,
                                                  alignment: .leftcenter,
                                                  tag: 0)
    
    // MARK: thumbsUpButton
    /// The button that the allows the user to indicate a positive navigation experience
    let thumbsUpButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "thumbs_up")!),
                                                label: "Good",
                                                targetSelector: Selector.thumbsUpButtonTapped,
                                                alignment: .rightcenter,
                                                tag: 0)
    
    // MARK: resumeButton
    /// The button that the allows the user to resume a paused route
    let resumeButton = ActionButtonComponents(appearance: .textButton(label: "Resume"),
                                              label: "Resume",
                                              targetSelector: Selector.resumeButtonTapped,
                                              alignment: .center,
                                              tag: 0)
    
    // MARK: enterLandmarkDescriptionButton
    /// The button that allows the user to enter textual description of a route landmark
    let enterLandmarkDescriptionButton = ActionButtonComponents(appearance: .textButton(label: "Describe"),
                                                                label: "Enter text to help you remember this landmark",
                                                                targetSelector: Selector.enterLandmarkDescriptionButtonTapped,
                                                                alignment: .left,
                                                                tag: 0)
    
    // MARK: recordVoiceNoteButton
    /// The button that allows the user to record a voice description of a route landmark
    let recordVoiceNoteButton = ActionButtonComponents(appearance: .textButton(label: "Voice Note"),
                                                       label: "Record audio to help you remember this landmark",
                                                       targetSelector: Selector.recordVoiceNoteButtonTapped,
                                                       alignment: .right,
                                                       tag: 0)
    
    // MARK: confirmAlignmentButton
    /// The button that allows the user to start the alignment countdown
    let confirmAlignmentButton = ActionButtonComponents(appearance: .textButton(label: "Align"),
                                                        label: "Start \(ViewController.alignmentWaitingPeriod)-second alignment countdown",
        targetSelector: Selector.confirmAlignmentButtonTapped,
        alignment: .center,
        tag: 0)
    
    // MARK: readVoiceNoteButton
    /// The button that plays back the recorded voice note associated with a landmark
    let readVoiceNoteButton = ActionButtonComponents(appearance: .textButton(label: "Play Note"),
                                                     label: "Play recorded voice note", targetSelector: Selector.readVoiceNoteButtonTapped,
                                                     alignment: .left,
                                                     tag: UIView.readVoiceNoteButtonTag)
    
    // MARK: addLandmarkButton
    /// Image, label, and target for start recording button. TODO: need an image
    let addLandmarkButton = ActionButtonComponents(appearance: .textButton(label: "Landmark"),
                                                   label: "Create landmark",
                                                   targetSelector: Selector.landmarkButtonTapped,
                                                   alignment: .right,
                                                   tag: 0)
    
    // MARK: stopRecordingButton
    /// Image, label, and target for stop recording button.
    let stopRecordingButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "StopRecording")!),
                                                     label: "Stop recording", targetSelector: Selector.stopRecordingButtonTapped,
                                                     alignment: .center,
                                                     tag: 0)
    
    // MARK: startNavigationButton
    /// Image, label, and target for start navigation button.
    let startNavigationButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "StartNavigation")!),
                                                       label: "Start navigation", targetSelector: Selector.startNavigationButtonTapped,
                                                       alignment: .center,
                                                       tag: 0)
    
    // MARK: pauseButton
    /// Title, label, and target for the pause button
    let pauseButton = ActionButtonComponents(appearance: .textButton(label: "Pause"),
                                             label: "Pause session",
                                             targetSelector: Selector.pauseButtonTapped,
                                             alignment: .right,
                                             tag: UIView.pauseButtonTag)
    
    // MARK: stopNavigationButton
    /// Image, label, and target for stop navigation button.
    let stopNavigationButton = ActionButtonComponents(appearance: .imageButton(image: UIImage(named: "StopNavigation")!),
                                                      label: "Stop navigation",
                                                      targetSelector: Selector.stopNavigationButtonTapped,
                                                      alignment: .center,
                                                      tag: 0)
    
    // MARK: routesButton
    /// Image, label, and target for routes button.
    let routesButton = ActionButtonComponents(appearance: .textButton(label: "Routes"),
                                              label: "Saved routes list",
                                              targetSelector: Selector.routesButtonTapped,
                                              alignment: .left,
                                              tag: 0)

    
    /// a banner that displays an announcement in the top quarter of the screen.
    /// This is used for displaying status updates or directions.
    /// This should only be used to display time-sensitive content.
    var announcementText: UILabel!

    /// a timer that counts down during the alignment procedure
    /// (alignment is captured at the end of the time)
    var countdownTimer: SRCountdownTimer!
    
    /// the view on which the user can rate the quality of their navigation experience
    var routeRatingView: UIView!

    /// the view on which the user can pause tracking
    var pauseTrackingView: UIView!
    
    /// the view on which the user can initiate the tracking resume procedure
    var resumeTrackingView: UIView!
    
    /// the view on which the user can confirm the tracking resume procedure
    var resumeTrackingConfirmView: UIView!
    
    /// Button view container for stop recording button
    var stopRecordingView: UIView!
    
    /// Button view container for start recording button.
    var recordPathView: UIView!
    
    /// Button view container for start navigation button
    var startNavigationView: UIView!
    
    /// Button view container for stop navigation button
    var stopNavigationView: UIView!

    // required for non storyboard UIView
    // objects
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented.")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // MARK: Settings Button
        settingsButton = UIButton(frame: CGRect(x: 0,
                                                y: UIConstants.yOriginOfSettingsAndHelpButton,
                                                width: UIConstants.buttonFrameWidth/2,
                                                height: UIConstants.settingsAndHelpFrameHeight))
        settingsButton.isAccessibilityElement = true
        settingsButton.setTitle("Settings", for: .normal)
        settingsButton.accessibilityLabel = "Settings"
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 24.0)
        settingsButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        // MARK: Help Button
        helpButton = UIButton(frame: CGRect(x: UIConstants.buttonFrameWidth/2,
                                            y: UIConstants.yOriginOfSettingsAndHelpButton,
                                            width: UIConstants.buttonFrameWidth/2,
                                            height: UIConstants.settingsAndHelpFrameHeight))
        helpButton.isAccessibilityElement = true
        helpButton.setTitle("Help", for: .normal)
        helpButton.titleLabel?.font = UIFont.systemFont(ofSize: 24.0)
        helpButton.accessibilityLabel = "Help"
        helpButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        // MARK: Directions Button
        // an invisible button which can be pressed to get the directions
        // to the next waypoint.
        getDirectionButton = UIButton(frame: CGRect(x: 0,
                                                    y: 0,
                                                    width: UIConstants.buttonFrameWidth,
                                                    height: UIConstants.yOriginOfButtonFrame))
        getDirectionButton.isAccessibilityElement = true
        getDirectionButton.accessibilityLabel = "Get Directions"
        getDirectionButton.isHidden = true

        // MARK: Announcement Text
        announcementText = UILabel(frame: CGRect(x: 0,
                                                 y: UIConstants.yOriginOfAnnouncementFrame,
                                                 width: UIConstants.buttonFrameWidth,
                                                 height: UIConstants.buttonFrameHeight*(1/2)))
        announcementText.textColor = UIColor.white
        announcementText.textAlignment = .center
        announcementText.isAccessibilityElement = false
        announcementText.lineBreakMode = .byWordWrapping
        announcementText.numberOfLines = 2
        announcementText.font = announcementText.font.withSize(20)
        announcementText.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        announcementText.isHidden = true
        
        // MARK: countdown element
        countdownTimer = SRCountdownTimer(frame: CGRect(x: UIConstants.buttonFrameWidth*1/10,
                                                        y: UIConstants.yOriginOfButtonFrame/10,
                                                        width: UIConstants.buttonFrameWidth*8/10,
                                                        height: UIConstants.buttonFrameWidth*8/10))
        countdownTimer.labelFont = UIFont(name: "HelveticaNeue-Light", size: 100)
        countdownTimer.labelTextColor = UIColor.white
        countdownTimer.timerFinishingText = "End"
        countdownTimer.lineWidth = 10
        countdownTimer.lineColor = UIColor.white
        countdownTimer.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        countdownTimer.isHidden = true
        /// hide the timer as an accessibility element
        /// and announce through VoiceOver by posting appropriate notifications
        countdownTimer.accessibilityElementsHidden = true
        
//        rootContainerView.settingsButton.addTarget(self,
//                                                   action: #selector(settingsButtonPressed),
//                                                   for: .touchUpInside)

        recordPathView = UIView(frame: CGRect(x: 0,
                                              y: UIConstants.yOriginOfButtonFrame,
                                              width: UIConstants.buttonFrameWidth,
                                              height: UIConstants.buttonFrameHeight))
        
        stopRecordingView = UIView(frame: CGRect(x: 0,
                                                 y: UIConstants.yOriginOfButtonFrame,
                                                 width: UIConstants.buttonFrameWidth,
                                                 height: UIConstants.buttonFrameHeight))

        startNavigationView = UIView(frame: CGRect(x: 0,
                                                   y: UIConstants.yOriginOfButtonFrame,
                                                   width: UIConstants.buttonFrameWidth,
                                                   height: UIConstants.buttonFrameHeight))

        pauseTrackingView = UIView(frame: CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.size.width,
                                                 height: UIScreen.main.bounds.size.height))

        resumeTrackingView = UIView(frame: CGRect(x: 0,
                                                  y: 0,
                                                  width: UIScreen.main.bounds.size.width,
                                                  height: UIScreen.main.bounds.size.height))

        resumeTrackingConfirmView = UIView(frame: CGRect(x: 0,
                                                         y: 0,
                                                         width: UIScreen.main.bounds.size.width,
                                                         height: UIScreen.main.bounds.size.height))

        stopNavigationView = UIView(frame: CGRect(x: 0,
                                                  y: UIConstants.yOriginOfButtonFrame,
                                                  width: UIConstants.buttonFrameWidth,
                                                  height: UIConstants.buttonFrameHeight))

        routeRatingView = UIView(frame: CGRect(x: 0,
                                               y: 0,
                                               width: UIConstants.buttonFrameWidth,
                                               height: UIScreen.main.bounds.size.height))

        
        /// add all sub views
        addSubview(recordPathView)
        addSubview(stopRecordingView)
        addSubview(startNavigationView)
        addSubview(pauseTrackingView)
        addSubview(resumeTrackingView)
        addSubview(resumeTrackingConfirmView)
        addSubview(stopNavigationView)
        addSubview(announcementText)
        addSubview(getDirectionButton)
        addSubview(settingsButton)
        addSubview(helpButton)
        addSubview(routeRatingView)
        addSubview(countdownTimer)
    }
}
