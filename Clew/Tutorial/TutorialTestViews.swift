//
//  TutorialTestViews.swift
//  Clew
//
//  Created by Declan Ketchum on 6/21/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI
import AVFoundation

struct TutorialScreen<Content: View>: View {
  let content: Content
  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }
  var body: some View {
    content
        //.navigationTitle("CLEW Tutorial")
        .navigationBarItems(
            trailing:
                Button(NSLocalizedString("buttonTexttoExitTutorial", comment: "text of the button that dismisses the tutorial screens")) {
                    NotificationCenter.default.post(name: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil)
        })
  }
}

struct SettingOptions: View {
    var body: some View {
        TutorialScreen{
            VStack{
                Text(NSLocalizedString( "settingOptionsTutorialButtonText", comment: "Title for the setting options part of the tutorial"))
                
                Text(NSLocalizedString( "settingOptionsTutorialInstructionText", comment: "Information about what the setting options are"))
            }
        }
    }
}

struct FindingSavedRoutes: View {
    var body: some View {
        TutorialScreen  {
            VStack{
                Text(NSLocalizedString( "findingSavedRoutesTutorialButtonText", comment: "Title for the finding saved route part of the tutorial"))
                
                Text(NSLocalizedString("findingSavedRoutesTutorialInstructionText", comment: "Instructions for finding saved routes"))
                
                NavigationLink(destination: SettingOptions()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
            }
        }
    }
}

struct AnchorPoints: View {
    var body: some View {
        TutorialScreen  {
            VStack{
                Text(NSLocalizedString( "anchorPointTutorialButtonText", comment: "Title for the anchor point part of the tutorial"))
                
                Text(NSLocalizedString("anchorPointTutorialInstructionText", comment: "Instructions for setting anchor points"))
                
            }
        }
    }
}

struct VoiceNotes: View {
    var body: some View {
        TutorialScreen  {
            VStack{
                Text(NSLocalizedString( "voiceNotesTutorialButtonText", comment: "Title for the voice notes part of the tutorial"))
                
                Text(NSLocalizedString("voiceNotesTutorialInstructionText", comment: "Instructions for leaving voice notes along a path"))
            }
        }
    }
}

struct SavedRoutes: View {
    var body: some View {
        TutorialScreen{
            VStack{
                Text(NSLocalizedString( "savedRoutesTutorialButtonText", comment: "Title for the saved route part of the tutorial"))
            
                Text(NSLocalizedString("savedRouteTutorialInstructionText", comment: "Instructions for using saved routes"))
                
                NavigationLink(destination: AnchorPoints()) {Text(NSLocalizedString( "anchorPointTutorialButtonText", comment: "Title for the anchor point part of the tutorial"))}
                
                NavigationLink(destination: VoiceNotes()) {Text(NSLocalizedString( "voiceNotesTutorialButtonText", comment: "Title for the voice notes part of the tutorial"))}
                
                NavigationLink(destination: FindingSavedRoutes())  {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
            }
        }
    }
}

struct SignleUse: View {
    var body: some View {
        TutorialScreen{
            VStack{
                Text(NSLocalizedString( "singleUseRouteTutorialButtonText", comment: "Title for the single use route part of the tutorial"))
                
                Text(NSLocalizedString( "singleUseRouteTutorialInstructionText", comment: "Instructions for using the single use route"))
                
                NavigationLink(destination: SavedRoutes()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
            }
        }
    }
}

struct FindPath: View {
    var body: some View {
        TutorialScreen{
            VStack{
                Text(NSLocalizedString( "findPathTutorialButtonText", comment: "Title for the finding and following path part of the tutorial"))
            
                Text(NSLocalizedString("findPathTutorialInstructionText", comment: "Text that explains what it sounds and feels like to be on the path and following the path"))
            
                NavigationLink(destination: SignleUse())  {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
                
                NavigationLink(destination: PracticeOrientPhone()) {Text("Practice Holding Phone")}
            }
        }
    }
}

struct OrientPhone: View {
    var body: some View {
        TutorialScreen {
            VStack{
                Text(NSLocalizedString("orientPhoneTutorialButtonText", comment: "Title for the setting options part of the tutorial"))
            
                Text(NSLocalizedString("orientPhoneTutorialInstructionText", comment: "Text that explains how to orient the phone for the best experience using Clew"))
                
                NavigationLink(destination: PracticeOrientPhone()) {Text("Practice Holding Phone")}
                
                NavigationLink(destination: OrientPhoneTips()) {Text("Tips")}
                
                NavigationLink(destination: FindPath()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
            
            }
        }
    }
}

struct OrientPhoneTips: View {
    var body: some View {
        TutorialScreen {
            VStack{
                Text("tips go here")
            }
        }
    }
}

struct PracticeOrientPhone: View {
    //TODO: 1 can't exit right now bc the var arData is being updated constantly. 2 turn off warning when practicing. 3 turn on AR when practicing
    @State private var score = 0
    @State var lastSuccessSound = Date()
    @State var lastSuccess = Date()
    @ObservedObject private var arData = ARData.shared
    var body: some View{
        TutorialScreen {
            Text("score \(self.score)")
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
                NavigationLink(destination: FindPath()) {Text("Next")}
            }
            
            if score == 3 {
                Text("Nice Job! You've completed orientation practice. You can keep practicing or go to the next section")
            }

            if score < 3 {
                NavigationLink(destination: FindPath()) {Text("Skip")}
            }
                
        }.onReceive(self.arData.objectWillChange) { newARData in
                    if let transform = arData.transform {
                    let y = transform.columns.0.y
                    if y < -0.4 && y > -0.7, -lastSuccessSound.timeIntervalSinceNow > 0.7 {
                            AudioServicesPlaySystemSound(SystemSoundID(1057))
                            lastSuccessSound = Date()
                            //UIAccessibility.post(notification: .announcement, argument: "Almost")
                    }
                    if y < -0.7 && y > -0.9, -lastSuccessSound.timeIntervalSinceNow > 0.5 {
                            AudioServicesPlaySystemSound(SystemSoundID(1057))
                            lastSuccessSound = Date()
                            //UIAccessibility.post(notification: .announcement, argument: "Almost")
                    }
                    if y < -0.9, -lastSuccessSound.timeIntervalSinceNow > 0.2 {
                            AudioServicesPlaySystemSound(SystemSoundID(1057))
                            lastSuccessSound = Date()
                            //UIAccessibility.post(notification: .announcement, argument: "WAY TO GO!")
                    }
                    if y < -0.9, -lastSuccess.timeIntervalSinceNow > 5 {
                        print(score)
                        score += 1
                        AudioServicesPlaySystemSound(SystemSoundID(1043))
                        lastSuccess = Date()
                        //UIAccessibility.post(notification: .announcement, argument: "Great")
                    }
                        
                    if score == 2 {
                        UIAccessibility.post(notification: .announcement, argument: "Nice Job! You've completed orientation practice. You can keep practicing or go to the next section")
                    }
                    }
        }
    }
}
            


struct TutorialTestView: View {    
    var body: some View {
        NavigationView{

            TutorialScreen{
                    VStack (spacing: 30){
                        Text(NSLocalizedString("tutorialTitleText", comment: "Title of the Clew Tutorial Screen. Top of the first tutorial page"))
                        
                        NavigationLink(destination: OrientPhone()) {Text(NSLocalizedString("orientPhoneTutorialButtonText", comment: "Text for the tutorial screem for phone position"))}
                        
                        NavigationLink(destination: FindPath()) {Text(NSLocalizedString( "findPathTutorialButtonText", comment: "Title for the finding and following path part of the tutorial"))}
                        
                        NavigationLink(destination: SignleUse()) {Text(NSLocalizedString( "singleUseRouteTutorialButtonText", comment: "Title for the single use route part of the tutorial"))}
                        
                        NavigationLink(destination: SavedRoutes()) {Text(NSLocalizedString( "savedRoutesTutorialButtonText", comment: "Title for the saved route part of the tutorial"))}
                        
                        NavigationLink(destination: FindingSavedRoutes()) {Text(NSLocalizedString( "findingSavedRoutesTutorialButtonText", comment: "Title for the finding saved route part of the tutorial"))}
                        
                        NavigationLink(destination: SettingOptions()) {Text(NSLocalizedString( "settingOptionsTutorialButtonText", comment: "Title for the setting options part of the tutorial"))}
                }
            }
        }
    }
}


struct TutorialTestViews_Previews: PreviewProvider {
    static var previews: some View {
        TutorialTestView()
    }
}
