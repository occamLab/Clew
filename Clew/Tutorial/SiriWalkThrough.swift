//
//  SiriWalkThrough.swift
//  Clew
//
//  Created by Paul Ruvolo on 8/23/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//


import SwiftUI
import Intents
import IntentsUI

class AddSiriShortcutViewControllerDelegate: NSObject, ObservableObject, INUIAddVoiceShortcutViewControllerDelegate {
    var shouldDismiss = false
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        shouldDismiss = true
        SiriShortcutsManager.shared.updateVoiceShortcuts(completion: nil)
        objectWillChange.send()
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        shouldDismiss = true
        objectWillChange.send()
    }
}

class EditSiriShortcutViewControllerDelegate: NSObject, INUIEditVoiceShortcutViewControllerDelegate, ObservableObject {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        shouldDismiss = true
        SiriShortcutsManager.shared.updateVoiceShortcuts(completion: nil)
        objectWillChange.send()
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        shouldDismiss = true
        SiriShortcutsManager.shared.updateVoiceShortcuts(completion: nil)
        objectWillChange.send()
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        shouldDismiss = true
        objectWillChange.send()
    }
    
    var shouldDismiss = false
}

struct SetNewShortcutWrapper: UIViewControllerRepresentable {
    let activity: NSUserActivity
    @Binding var showModal: Bool
    @StateObject var delegate = AddSiriShortcutViewControllerDelegate()
    
    func makeUIViewController(context: Context) -> INUIAddVoiceShortcutViewController {
        let shortcut = INShortcut(userActivity: activity)
        let controller = INUIAddVoiceShortcutViewController(shortcut:shortcut)
        controller.delegate = delegate
        return controller
    }

    func updateUIViewController(_ uiViewController: INUIAddVoiceShortcutViewController, context: Context) {
        if delegate.shouldDismiss {
            $showModal.wrappedValue = false
        }
    }
}

struct EditShortcutWrapper: UIViewControllerRepresentable {
    let voiceShortCut: INVoiceShortcut
    @Binding var showModal: Bool
    @StateObject var delegate = EditSiriShortcutViewControllerDelegate()
    
    func makeUIViewController(context: Context) -> INUIEditVoiceShortcutViewController {
        let controller = INUIEditVoiceShortcutViewController(voiceShortcut:voiceShortCut)
        controller.delegate = delegate
        return controller
    }
    
    func updateUIViewController(_ uiViewController: INUIEditVoiceShortcutViewController, context: Context) {
        if delegate.shouldDismiss {
            $showModal.wrappedValue = false
        }
    }
}


struct SetRecordShortcut: View{
    @State var presentPopup = false
    var body: some View {
        TutorialScreen{
            VStack {
                Text(NSLocalizedString("siriWalkthroughSetRecordRouteShortcutText", comment: "The page title for the Siri shortcut for recording a route")).padding()
                Button(action:{
                    presentPopup.toggle()
                }) {
                    TutorialButton {
                        Text(NSLocalizedString("setRecordRouteShortcut", comment: "Set the record route Siri shortcut"))
                    }
                }
            }.sheet(isPresented: $presentPopup) {
                if let voiceShortcut = SiriShortcutsManager.shared.findShortcut(persistentIdentifier: kNewSingleUseRouteType) {
                    EditShortcutWrapper(voiceShortCut: voiceShortcut, showModal: $presentPopup)
                } else {
                    SetNewShortcutWrapper(activity: SiriShortcutsController.newSingleUseRouteShortcut(), showModal: $presentPopup)
                }
            }
        }
        Spacer()
        TutorialNavLink(destination: SetEndRecordingShortcut()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
    }
}


struct SetEndRecordingShortcut: View{
    @State var presentPopup = false
    var body: some View {
        TutorialScreen{
            VStack {
                Text(NSLocalizedString("siriWalkthroughSetEndRecordingShortcutText", comment: "The page title for setting the Siri shortcut for ending the route recording")).padding()
                TutorialButton {
                    Button(action:{
                        presentPopup.toggle()
                    }) {
                        Text(NSLocalizedString("setEndRecordingShortcut", comment: "Set the record route Siri shortcut"))
                    }
                }
            }.sheet(isPresented: $presentPopup) {
                if let voiceShortcut = SiriShortcutsManager.shared.findShortcut(persistentIdentifier: kStopRecordingType) {
                    EditShortcutWrapper(voiceShortCut: voiceShortcut, showModal: $presentPopup)
                } else {
                    SetNewShortcutWrapper(activity: SiriShortcutsController.stopRecordingShortcut(), showModal: $presentPopup)
                }
            }
        }
        Spacer()
        TutorialNavLink(destination: SetNavigateBackShortcut()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
    }
}

struct SetNavigateBackShortcut: View{
    @State var presentPopup = false
    @ObservedObject var showPage = ShowTutorialPage.shared
    var body: some View {
        TutorialScreen{
            VStack {
                Text(NSLocalizedString("siriWalkthroughSetNavigateBackText", comment: "Set the Siri shortcut for ending the route recording")).padding()
                TutorialButton {
                    Button(action:{
                        presentPopup.toggle()
                    }) {
                        Text(NSLocalizedString("setNavigateBackShortcut", comment: "Set the Siri shortcut for navigating back"))
                    }
                }
            }.sheet(isPresented: $presentPopup) {
                if let voiceShortcut = SiriShortcutsManager.shared.findShortcut(persistentIdentifier: kStartNavigationType) {
                    EditShortcutWrapper(voiceShortCut: voiceShortcut, showModal: $presentPopup)
                } else {
                    SetNewShortcutWrapper(activity: SiriShortcutsController.startNavigationShortcut(), showModal: $presentPopup)
                }
            }
        }
        Spacer()

        if showPage.confineToSection {
            Button(action: {
                NotificationCenter.default.post(name: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil)
            }) {
                TutorialButton{
                    Text("Exit")
                }
            }
        } else {
            TutorialNavLink(destination: TutorialEndView()) {
                Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
            }
        }
    }
}
