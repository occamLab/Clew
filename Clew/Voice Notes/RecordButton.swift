//
//  RecordButton.swift
//  RecordButtonTest
//
//  Created by Mark Alldritt on 2016-12-19.
//  Copyright © 2016 Late Night Software Ltd. All rights reserved.
//

import UIKit
import AVFoundation
import PRTween

/// a button that can initiate an audio recording
@IBDesignable
class RecordButton: UIButton {
    
    
    private weak var tweenOperation : PRTweenOperation?
    private var startPlayer : AVAudioPlayer?
    private var stopPlayer : AVAudioPlayer?
    private var isRecordingScale : CGFloat = 1.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// true if various sound effects (e.g., record start and stop) should be played, false otherwise
    @IBInspectable open var playSounds = true
    
    /// the color of the frame around the record button
    @IBInspectable open var frameColor : UIColor = RecordButtonKit.recordFrameColor {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// true if the recording is active, and false otherwise.  By changing the value of this attribute, an animation will be presented that communicates that the recording state is changing.
    @IBInspectable open var isRecording : Bool = false {
        didSet {
            #if !TARGET_INTERFACE_BUILDER
            //  Stop any running animation
            if let tweenOperation = tweenOperation {
                PRTween.sharedInstance().remove(tweenOperation)
            }
            
            //  Animate from one state to another (either 0 -> 1 or 1 -> 0)
            let period = PRTweenPeriod.period(withStartValue: isRecordingScale,
                                              endValue: isRecording ? 0.0 : 1.0,
                                              duration: 0.5) as! PRTweenPeriod
            
            tweenOperation = PRTween.sharedInstance().add(period, update: { (p) in
                self.isRecordingScale = p!.tweenedValue
            }, completionBlock: nil)
            setAccessibilityLabel()
            #else
            //  Don't animate in IB as the changes will not be shown
            isRecordingScale = isRecording ? 0.0 : 1.0
            #endif
        }
    }
    
    /// Track touch events
    ///
    /// - Parameters:
    ///   - touch: the touch event
    ///   - event: a description of the event
    /// - Returns: true if the control should continue tracking touch events or false if it should stop.  Currently, we defer this to the super class implementation.
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let result = super.beginTracking(touch, with: event)
        
        if playSounds && startPlayer == nil {
            DispatchQueue.main.async { [weak self] in
                let startURL = Bundle.main.url(forResource: "StartRecording", withExtension: "aiff")!
                let stopURL = Bundle.main.url(forResource: "StopRecording", withExtension: "aiff")!
                
                self?.startPlayer = try? AVAudioPlayer(contentsOf: startURL)
                self?.startPlayer?.prepareToPlay()
                self?.stopPlayer = try? AVAudioPlayer(contentsOf: stopURL)
                self?.stopPlayer?.prepareToPlay()
            }
        }
        return result
    }
    
    /// Send action override to toggle button state
    ///
    /// - Parameters:
    ///   - action: the action being sent
    ///   - target: the target of the action
    ///   - event: the event description
    override func sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        if playSounds {
            if isRecording {
                stopPlayer?.play()
            }
            else {
                startPlayer?.play()
            }
        }
        isRecording = !isRecording
        super.sendAction(action, to: target, for: event)
    }
    
    /// specifies the accessibility label to be reflective of the current button state.
    fileprivate func setAccessibilityLabel() {
        if isRecording {
            self.accessibilityLabel = NSLocalizedString("stopRecordingVoiceNoteAccessibilityLabel", comment: "This is the accessibility label which is played when a user with voice over selects the button to stop their voice recording")
        } else {
            self.accessibilityLabel = NSLocalizedString("startRecordingVoiceNoteAccessibilityLabel", comment: "This is the accessibility label which is played when a user with voice over selects the button to record a voice recording in the voice recorder view")
        }
    }

    /// draw the record button to the specified rectangle.
    ///
    /// - Parameter rect: where to draw the button
    override func draw(_ rect: CGRect) {
        let buttonFrame = bounds
        let pressed = isHighlighted || isTracking
        
        RecordButtonKit.drawRecordButton(frame: buttonFrame,
                                         recordButtonFrameColor:frameColor,
                                         isRecording: isRecordingScale,
                                         isPressed: pressed)
    }
    
    /// computes whether the button is highlighted
    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            super.isHighlighted = newValue
            setNeedsDisplay()
        }
    }
}
