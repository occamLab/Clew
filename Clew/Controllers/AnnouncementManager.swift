//
//  SpeechManager.swift
//  Clew
//
//  Created by occamlab on 7/3/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import AVFoundation

class AnnouncementManager : UIViewController, AVSpeechSynthesizerDelegate {
    /// a banner that displays an announcement in the top quarter of the screen.
    /// This is used for displaying status updates or directions.
    /// This should only be used to display time-sensitive content.
    var announcementText: UILabel!
    
    /// times when an announcement should be removed.  These announcements are displayed on the `announcementText` label.
    var announcementRemovalTimer: Timer?
    
    /// The announcement that is currently being read.  If this is nil, that implies nothing is being read
    var currentAnnouncement: String?
    
    /// The announcement that should be read immediately after this one finishes
    var nextAnnouncement: String?
    
    /// An optional observer that wants to learn about speech events
    var observer: ClewObserver?
    
    /// When VoiceOver is not active, we use AVSpeechSynthesizer for speech feedback
    let synth = AVSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = TransparentTouchView(frame:CGRect(x: 0,
                                                 y: 0,
                                                 width: UIScreen.main.bounds.size.width,
                                                 height: UIScreen.main.bounds.size.height))
        
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
        
        synth.delegate = self
        
        // allow announcements to displayed through a notification
        NotificationCenter.default.addObserver(forName: Notification.Name("makeClewAnnouncement"), object: nil, queue:nil) { (notification) -> Void  in
            let delayInSeconds = notification.userInfo?["delayInSeconds"] as? Double
            if let announcementText = notification.userInfo?["announcementText"] as? String {
                self.announce(announcement: announcementText, delayInSeconds: delayInSeconds)
            }
        }
        
        // create listeners to ensure that the currentAnnouncement variable is reset
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { (notification) -> Void in
            self.currentAnnouncement = nil
        }
        
        NotificationCenter.default.addObserver(forName: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil, queue: nil) { (notification) -> Void in
            self.currentAnnouncement = nil
        }
        
        NotificationCenter.default.addObserver(forName: UIAccessibility.announcementDidFinishNotification, object: nil, queue: nil) { (notification) ->Void in
            self.observer?.finishAnnouncement(announcement: "not receiving announcement strings")
            self.currentAnnouncement = nil
            if let nextAnnouncement = self.nextAnnouncement {
                self.nextAnnouncement = nil
                self.announce(announcement: nextAnnouncement)
            }
        }
        view.addSubview(announcementText)
    }
    
    // MARK: - Speech Synthesizer Delegate
    
    /// Called when an utterance is finished.  We implement this function so that we can keep track of
    /// whether or not an announcement is currently being read to the user.
    ///
    /// - Parameters:
    ///   - synthesizer: the synthesizer that finished the utterance
    ///   - utterance: the utterance itself
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        observer?.finishAnnouncement(announcement: utterance.speechString)
        currentAnnouncement = nil
        if let nextAnnouncement = self.nextAnnouncement {
            self.nextAnnouncement = nil
            _ = announce(announcement: nextAnnouncement)
        }
    }
    
    /// Called when an utterance is canceled.  We implement this function so that we can keep track of
    /// whether or not an announcement is currently being read to the user.
    ///
    /// - Parameters:
    ///   - synthesizer: the synthesizer that finished the utterance
    ///   - utterance: the utterance itself
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didCancel utterance: AVSpeechUtterance) {
        currentAnnouncement = nil
        if let nextAnnouncement = self.nextAnnouncement {
            self.nextAnnouncement = nil
            _ = announce(announcement: nextAnnouncement)
        }
    }
    
    /// Communicates a message to the user via speech.  If VoiceOver is active, then VoiceOver is used to communicate the announcement, otherwise we use the AVSpeechEngine
    ///
    /// - Parameter announcement: the text to read to the user
    func announce(announcement: String, delayInSeconds: Double? = nil) {
        if let delayInSeconds = delayInSeconds {
            Timer.scheduledTimer(withTimeInterval: delayInSeconds, repeats: false) { timer in
                self.announce(announcement: announcement)
            }
            return
        }
        
        if let currentAnnouncement = currentAnnouncement {
            // don't interrupt current announcement, but if there is something new to say put it on the queue to say next.  Note that adding it to the queue in this fashion could result in the next queued announcement being preempted
            if currentAnnouncement != announcement {
                nextAnnouncement = announcement
            }
            return
        }

        announcementText.isHidden = false
        announcementText.text = announcement
        announcementRemovalTimer?.invalidate()
        announcementRemovalTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { timer in
            self.announcementText.isHidden = true
        }
        
        if UIAccessibility.isVoiceOverRunning {
            // use the VoiceOver API instead of text to speech
            print("halp")
            currentAnnouncement = announcement
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: announcement)
        } else if UserDefaults.standard.bool(forKey: "voiceFeedback") {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSession.Category.playback)
                try audioSession.setActive(true)
                let utterance = AVSpeechUtterance(string: announcement)
                utterance.rate = 0.6
                currentAnnouncement = announcement
                synth.speak(utterance)
            } catch {
                print("Unexpected error announcing something using AVSpeechEngine!")
            }
        }
    }
}
