//
//  SiriShortcutsManager.swift
//  Clew
//
//  Created by Paul Ruvolo on 8/23/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import Foundation
import Intents
import IntentsUI

class SiriShortcutsManager: ObservableObject {
    public static var shared = SiriShortcutsManager()
    var voiceShortcuts: [INVoiceShortcut] = []

    private init() {
        updateVoiceShortcuts(completion: nil)
    }
    
    public func updateVoiceShortcuts(completion: (() -> Void)?) {
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { (voiceShortcutsFromCenter, error) in
            guard let voiceShortcutsFromCenter = voiceShortcutsFromCenter else {
                if let error = error {
                    print("Failed to fetch voice shortcuts with error: \(error.localizedDescription)")
                }
                return
            }
            self.voiceShortcuts = voiceShortcutsFromCenter
            DispatchQueue.main.async {
                self.objectWillChange.send()
                if let completion = completion {
                    completion()
                }
            }
        }
    }
    
    func findShortcut(persistentIdentifier: String)->INVoiceShortcut? {
        for currentSiriShortcut in voiceShortcuts {
            if currentSiriShortcut.shortcut.userActivity?.persistentIdentifier == persistentIdentifier {
                    return currentSiriShortcut
            }
        }
        return nil
    }
}
