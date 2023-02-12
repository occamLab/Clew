//
//  SoundEffectManager.swift
//  Clew
//
//  Created by Paul Ruvolo on 8/18/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import Foundation
import AVFoundation

class SoundEffectManager {
    public static var shared = SoundEffectManager()
    private var successSound: AVAudioPlayer?
    private var mehSound: AVAudioPlayer?
    private var errorSound: AVAudioPlayer?
    private var tambourineSound: AVAudioPlayer?

    /// audio players for playing system sounds through an `AVAudioSession` (this allows them to be audible even when the rocker switch is muted.
    var audioPlayers: [Int: AVAudioPlayer] = [:]

    private init() {
        loadSoundEffects()
    }
    
    private func loadSoundEffects() {
        if let successPath = Bundle.main.path(forResource: "ClewSuccessSound", ofType:"wav") {
            do {
                let url = URL(fileURLWithPath: successPath)
                successSound = try AVAudioPlayer(contentsOf: url)
                successSound?.prepareToPlay()
            } catch {
                print("error \(error)")
            }
        }
        if let errorPath = Bundle.main.path(forResource: "ClewErrorSound", ofType:"wav") {
            do {
                let url = URL(fileURLWithPath: errorPath)
                errorSound = try AVAudioPlayer(contentsOf: url)
                errorSound?.prepareToPlay()
            } catch {
                print("error \(error)")
            }
        }
        if let mehPath = Bundle.main.path(forResource: "ClewTutorialFeedback", ofType:"wav") {
            do {
                let url = URL(fileURLWithPath: mehPath)
                mehSound = try AVAudioPlayer(contentsOf: url)
                mehSound?.prepareToPlay()
            } catch {
                print("error \(error)")
            }
        }
        if let tambourinePath = Bundle.main.path(forResource: "tamb_tap_short", ofType:"wav") {
            do {
                let url = URL(fileURLWithPath: tambourinePath)
                tambourineSound = try AVAudioPlayer(contentsOf: url)
                tambourineSound?.prepareToPlay()
            } catch {
                print("error \(error)")
            }
        }
        /// Create the audio player objdcts for the various app sounds.  Creating them ahead of time helps reduce latency when playing them later.
        do {
            audioPlayers[1103] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/Tink.caf"))
            audioPlayers[1016] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/tweet_sent.caf"))
            audioPlayers[1050] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/ussd.caf"))
            audioPlayers[1025] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/New/Fanfare.caf"))
            audioPlayers[1108] = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/photoShutter.caf"))


            for p in audioPlayers.values {
                p.prepareToPlay()
            }
        } catch let error {
            print("count not setup audio players", error)
        }
    }
    
    func isWearingBinauralHeadphones()->Bool {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs.filter({output in Set([AVAudioSession.Port.headphones, AVAudioSession.Port.bluetoothA2DP]).contains(output.portType)}) {
            if let channels = output.channels, channels.count >= 2 {
                return true
            }
        }
        return false
    }
    
    private func overrideSilentMode() {
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    func success() {
        overrideSilentMode()
        successSound?.play()
    }
    
    func error() {
        overrideSilentMode()
        errorSound?.play()
    }
    
    func meh() {
        overrideSilentMode()
        mehSound?.play()
    }
    
    func tambourine() {
        overrideSilentMode()
        tambourineSound?.play()
    }
    
    /// Play the specified system sound.  If the system sound has been preloaded as an audio player, then play using the AVAudioSession.  If there is no corresponding player, use the `AudioServicesPlaySystemSound` function.
    ///
    /// - Parameter id: the id of the system sound to play
    func playSystemSound(id: Int) {
        overrideSilentMode()
        guard let player = audioPlayers[id] else {
            // fallback on system sounds
            AudioServicesPlaySystemSound(SystemSoundID(id))
            return
        }
        player.play()
    }
}
