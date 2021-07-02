//
//  TutorialTestViews.swift
//  Clew
//
//  Created by Declan Ketchum on 6/21/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI
import AVFoundation

//TODO: 1 add content to all pages  3 interactive practice on following a path  4 set up settings walk through  5 add localized strings to everything  6 make progress view?

struct TutorialScreen<Content: View>: View {
  let content: Content
  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }
    
    var body: some View {
        VStack(spacing: 30) {
            content
        }
            
        //.navigationTitle("Clew Tutorial") //gives title, but title is the same on all the tutorial screens and the back button text only says Clew Tutorial.
        //.navigationBarTitleDisplayMode(.inline)
        
        .navigationBarItems(
            trailing:
                Button(NSLocalizedString("buttonTexttoExitTutorial", comment: "text of the button that dismisses the tutorial screens")) {
                    NotificationCenter.default.post(name: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil)
        
        })
    }
  }


struct TutorialNavLink<Destination: View, Content: View>: View {
    //creates a button format for all the CLEW tutorial navigation links to use
  let content: Content
    let destination: Destination
    init(destination: Destination, @ViewBuilder content: () -> Content) {
        self.destination = destination
    self.content = content()
  }
    
    var body: some View {
        NavigationLink(destination: self.destination) {
            content.textboarder(color: .black, lineWidth: 3)
                .frame(minWidth: 0, maxWidth: 300)
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
                .font(.system(size: 18, weight: .bold))
        }
    }
  }


struct TutorialButton<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content.textboarder(color: .black, lineWidth: 3)
            .frame(minWidth: 0, maxWidth: 300)
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(10)
            .font(.system(size: 18, weight: .bold))
    }
}


struct SettingOptions: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "settingOptionsTutorialButtonText", comment: "Title for the setting options part of the tutorial"))
            
            Text(NSLocalizedString( "settingOptionsTutorialInstructionText", comment: "Information about what the setting options are"))
            
            TutorialNavLink(destination: SettingWalkThrough()) {Text("Settings Walk Through")}
        }
    }
}

struct FindingSavedRoutes: View {
    var body: some View {
        TutorialScreen  {
            Text(NSLocalizedString( "findingSavedRoutesTutorialButtonText", comment: "Title for the finding saved route part of the tutorial"))
            
            Text(NSLocalizedString("findingSavedRoutesTutorialInstructionText", comment: "Instructions for finding saved routes"))
            
            TutorialNavLink(destination: SettingOptions()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
        }
    }
}

struct AnchorPoints: View {
    var body: some View {
        TutorialScreen  {
            Text(NSLocalizedString( "anchorPointTutorialButtonText", comment: "Title for the anchor point part of the tutorial"))
            
            Text(NSLocalizedString("anchorPointTutorialInstructionText", comment: "Instructions for setting anchor points"))
                
        }
    }
}

struct VoiceNotes: View {
    var body: some View {
        TutorialScreen  {
            Text(NSLocalizedString( "voiceNotesTutorialButtonText", comment: "Title for the voice notes part of the tutorial"))
            
            Text(NSLocalizedString("voiceNotesTutorialInstructionText", comment: "Instructions for leaving voice notes along a path"))
        }
    }
}

struct SavedRoutes: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "savedRoutesTutorialButtonText", comment: "Title for the saved route part of the tutorial"))
        
            Text(NSLocalizedString("savedRouteTutorialInstructionText", comment: "Instructions for using saved routes"))
            
            TutorialNavLink(destination: AnchorPoints()) {Text(NSLocalizedString( "anchorPointTutorialButtonText", comment: "Title for the anchor point part of the tutorial"))}
            
            TutorialNavLink(destination: VoiceNotes()) {Text(NSLocalizedString( "voiceNotesTutorialButtonText", comment: "Title for the voice notes part of the tutorial"))}
            
            TutorialNavLink(destination: FindingSavedRoutes())  {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
        }
    }
}

struct SingleUse: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "singleUseRouteTutorialButtonText", comment: "Title for the single use route part of the tutorial"))
            
            Text(NSLocalizedString( "singleUseRouteTutorialInstructionText", comment: "Instructions for using the single use route"))
            
            TutorialNavLink(destination: SavedRoutes()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
        }
    }
}

struct FindPath: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "findPathTutorialButtonText", comment: "Title for the finding and following path part of the tutorial"))
        
            Text(NSLocalizedString("findPathTutorialInstructionText", comment: "Text that explains what it sounds and feels like to be on the path and following the path"))
        
            TutorialNavLink(destination: SingleUse())  {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
            
            TutorialNavLink(destination: PracticeOrientPhone()) {Text(NSLocalizedString ("orientPhoneTutorialPracticeTitle", comment: "Title of the practice orienting your phone page"))}
        }
    }
}

struct OrientPhone: View {
    var body: some View {
        TutorialScreen {
            Text(NSLocalizedString("orientPhoneTutorialButtonText", comment: "Title for the setting options part of the tutorial"))
        
            Text(NSLocalizedString("orientPhoneTutorialInstructionText", comment: "Text that explains how to orient the phone for the best experience using Clew"))
            
            TutorialNavLink(destination: PracticeOrientPhone()) {Text("Practice Holding Phone")}
            
            TutorialNavLink(destination: OrientPhoneTips()) {Text("Tips")}
            
            TutorialNavLink(destination: FindPath()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
        }
    }
}

struct OrientPhoneTips: View {
    var body: some View {
        TutorialScreen {
            Text("Tips for holding your phone")
            
            Text(NSLocalizedString("orientPhoneTutorialTip1", comment: "Tip for holding phone against chest"))
            
            Text(NSLocalizedString("orientPhoneTutorialTip2", comment: "Tip for using Clew with cane or guide dog"))
        }
    }
}


struct PracticeOrientPhone: View {
    //TODO: 1 can't exit right now bc the var arData is being updated constantly. 2 give haptic feedback  3 add success notification when activity is complete
    @State private var started = false
    @State private var successAlert = false
    @State private var score = 0
    @State var lastSuccessSound = Date()
    @State var lastSuccess = Date()
    @State var resetPosition = true
    @ObservedObject private var arData = ARData.shared
    var body: some View{
        TutorialScreen {
            Text(NSLocalizedString("orientPhoneTutorialPracticeInstructions", comment: "Instructions for practicing holding phone activity"))
            
            Text("score \(self.score)")
            
            Button(action:{
                started.toggle()
                NotificationCenter.default.post(name: Notification.Name("StartARSession"), object: nil)
            }){
                if started {
                    TutorialButton{
                        Text("Stop")}
                } else {
                    TutorialButton{
                        Text("Start")}
                }
            }
            
            if let transform = arData.transform {
                let y = transform.columns.0.y
                Text("y-component \(y)")
                if y < -0.9 {
                    Text("correct")
                }
            }
            
            if score >= 3 {
                //AudioServicesPlaySystemSound(SystemSoundID(1057))
                Text("Yay!!!")
                TutorialNavLink(destination: FindPath()) {Text("Next")}
            }
            
            if score == 3 {
                Text("Nice Job! You've completed orientation practice. You can keep practicing or go to the next section")
            }

            else if score < 3 {
                TutorialNavLink(destination: FindPath()) {Text("Skip")}
            }
        
            
        }.onDisappear() {
            started = false
        }
        .onReceive(self.arData.objectWillChange) { newARData in
            if started {
                    if let transform = arData.transform {
                    let y = transform.columns.0.y
                        if y < 0.5 && y > -0.7, -lastSuccessSound.timeIntervalSinceNow > 0.2 {
                            AudioServicesPlaySystemSound(SystemSoundID(1057))
                            AudioServicesPlaySystemSound(SystemSoundID(4095))
                            lastSuccessSound = Date()
                            lastSuccess = Date()
                            resetPosition = true
                            //UIAccessibility.post(notification: .announcement, argument: "Almost")
                    }
                    if y < -0.7 && y > -0.9, -lastSuccessSound.timeIntervalSinceNow > 0.5 {
                            AudioServicesPlaySystemSound(SystemSoundID(1057))
                            AudioServicesPlaySystemSound(SystemSoundID(4095))
                            lastSuccessSound = Date()
                            lastSuccess = Date()
                            resetPosition = true
                            //UIAccessibility.post(notification: .announcement, argument: "Almost")
                    }
                        if y < -0.9, -lastSuccessSound.timeIntervalSinceNow > 0.7 {
                            AudioServicesPlaySystemSound(SystemSoundID(1057))
                            AudioServicesPlaySystemSound(SystemSoundID(4095))
                            lastSuccessSound = Date()
                            //UIAccessibility.post(notification: .announcement, argument: "WAY TO GO!")
                    }
                    if y < -0.9, resetPosition,  -lastSuccess.timeIntervalSinceNow > 2 {
                        print(score)
                        score += 1
                        lastSuccess = Date()
                        resetPosition = false
                        AudioServicesPlaySystemSound(SystemSoundID(1025))
                        AudioServicesPlaySystemSound(SystemSoundID(4095))
                        //UIAccessibility.post(notification: .announcement, argument: "Great")
                    }
                        
                    
                        
                    /*if score == 3, playsuccess {
                        successAlert = true
                        UIAccessibility.post(notification: .announcement, argument: "Nice Job! You've completed phone orientation practice. You can keep practicing or go to the next section")
                    }*/
                }
            }
        }
    }
}

struct CLEWintro: View {
    var body: some View {
        TutorialScreen{
            Text("CLEW is a navigation app that is meant for indoor use. It is not a replacement for mobility stratigies such as a white cane or guide dog. It is meant to be a supplimentary tool to help with indoor navigation of shorter routes.")
            
            TutorialNavLink(destination: OrientPhone()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
        }
    }
}
            


struct TutorialTestView: View {    
    var body: some View {
        NavigationView{

            TutorialScreen{
                Text(NSLocalizedString("tutorialTitleText", comment: "Title of the Clew Tutorial Screen. Top of the first tutorial page"))
                        
                TutorialNavLink(destination: CLEWintro()) {
                    Text("Intro to Clew")
                    }
                        
                TutorialNavLink(destination: OrientPhone()){
                    Text(NSLocalizedString("orientPhoneTutorialButtonText", comment: "Text for the tutorial screem for phone position"))
                    }
                    
                        
                    TutorialNavLink(destination: FindPath()) {Text(NSLocalizedString( "findPathTutorialButtonText", comment: "Title for the finding and following path part of the tutorial"))}
                    
                    TutorialNavLink(destination: SingleUse()) {Text(NSLocalizedString( "singleUseRouteTutorialButtonText", comment: "Title for the single use route part of the tutorial"))}
                    
                    TutorialNavLink(destination: SavedRoutes()) {Text(NSLocalizedString( "savedRoutesTutorialButtonText", comment: "Title for the saved route part of the tutorial"))}
                    
                    TutorialNavLink(destination: FindingSavedRoutes()) {Text(NSLocalizedString( "findingSavedRoutesTutorialButtonText", comment: "Title for the finding saved route part of the tutorial"))}
                    
                    TutorialNavLink(destination: SettingOptions()) {Text(NSLocalizedString( "settingOptionsTutorialButtonText", comment: "Title for the setting options part of the tutorial"))}
            }
        }
    }
}


struct TutorialTestViews_Previews: PreviewProvider {
    static var previews: some View {
        TutorialTestView()
    }
}
