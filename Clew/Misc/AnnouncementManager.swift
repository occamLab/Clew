//
//  AnnouncementManager.swift
//  Clew-More
//
//  Created by Paul Ruvolo on 7/27/22.
//  Copyright © 2022 OccamLab. All rights reserved.
//

import Foundation

class AnnouncementManager: NSObject, AVSpeechSynthesizerDelegate {
    public static var shared = AnnouncementManager()

    /// The announcement that is currently being read.  If this is nil, that implies nothing is being read
    var currentAnnouncement: String?
    
    /// When VoiceOver is not active, we use AVSpeechSynthesizer for speech feedback
    let synth = AVSpeechSynthesizer()
    
    /// The announcement that should be read immediately after this one finishes
    var nextAnnouncement: String?
    
    /// times when an announcement should be removed.  These announcements are displayed on the `announcementText` label.
    var announcementRemovalTimer: Timer?
    
    /// a handle to the root container view to allow announcement banners to be displayed
    var rootContainerView: RootContainerView?
    
    /// whether or not voiceFeedback has been enabled by the user
    var voiceFeedback: Bool?

    private override init() {
        super.init()
        synth.delegate = self
        NotificationCenter.default.addObserver(forName: UIAccessibility.announcementDidFinishNotification, object: nil, queue: nil) { (notification) -> Void in
            self.currentAnnouncement = nil
            if let nextAnnouncement = self.nextAnnouncement {
                self.nextAnnouncement = nil
                self.announce(announcement: nextAnnouncement)
            }
        }
        
        // create listeners to ensure that the isReadingAnnouncement flag is reset properly
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { (notification) -> Void in
            self.currentAnnouncement = nil
        }
        
        NotificationCenter.default.addObserver(forName: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil, queue: nil) { (notification) -> Void in
            self.currentAnnouncement = nil
        }
      
    }

    /// Communicates a message to the user via speech.  If VoiceOver is active, then VoiceOver is used to communicate the announcement, otherwise we use the AVSpeechEngine
    ///
    /// - Parameter announcement: the text to read to the user
    func announce(announcement: String) {
        if let currentAnnouncement = currentAnnouncement {
            // don't interrupt current announcement, but if there is something new to say put it on the queue to say next.  Note that adding it to the queue in this fashion could result in the next queued announcement being preempted
            if currentAnnouncement != announcement {
                nextAnnouncement = announcement
            }
            return
        }
        
        rootContainerView?.announcementText.isHidden = false
        rootContainerView?.announcementText.text = announcement
        announcementRemovalTimer?.invalidate()
        announcementRemovalTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { timer in
            self.rootContainerView?.announcementText.isHidden = true
        }
        if UIAccessibility.isVoiceOverRunning {
            // use the VoiceOver API instead of text to speech
            currentAnnouncement = announcement
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: announcement)
        } else if voiceFeedback == true {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSession.Category.playback)
                try audioSession.setActive(true)
                let utterance = AVSpeechUtterance(string: announcement)
                utterance.rate = 0.5
                currentAnnouncement = announcement
                synth.speak(utterance)
            } catch {
                print("Unexpected error announcing something using AVSpeechEngine!")
            }
        }
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
        currentAnnouncement = nil
        if let nextAnnouncement = self.nextAnnouncement {
            self.nextAnnouncement = nil
            announce(announcement: nextAnnouncement)
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
            announce(announcement: nextAnnouncement)
        }
    }
}
