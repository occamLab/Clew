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
    }
    
    func success() {
        successSound?.play()
    }
    
    func error() {
        errorSound?.play()
    }
    
    func meh() {
        mehSound?.play()
    }
}
