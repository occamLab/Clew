//
//  TutorialTestViews.swift
//  Clew
//
//  Created by Declan Ketchum on 6/21/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI
import AVFoundation

//TODO: 1 add content to all pages  2 interactive practice on following a path  3 set up settings walk through  4 add localized strings to everything  5 make progress view?  6 add color cue to interactive practice

struct TutorialScreen<Content: View>: View {
    //format for all the tutorial and app set up screens. standarizes spacing and adds exit button to each page
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

//Colors:
let darkBlue = Color(red: 0.01, green: 0.15, blue: 1.05)
let skyBlue = Color(red: 0.4627, green: 0.8392, blue: 1.0)
//find our own clew colors



struct TutorialNavLink<Destination: View, Content: View>: View {
    //creates a button format for all the CLEW tutorial navigation links to use. only works for navigation links
  let content: Content
    let destination: Destination
    init(destination: Destination, @ViewBuilder content: () -> Content) {
        self.destination = destination
    self.content = content()
  }
    
    var body: some View {
        NavigationLink(destination: self.destination) {
            content
                //.textboarder(color: .black, lineWidth: 3)
                .frame(minWidth: 0, maxWidth: 300)
                .padding()
                .foregroundColor(.black)
                .background(Color.yellow)
                .cornerRadius(10)
                .font(.system(size: 18, weight: .regular))
        }
    }
  }




struct TutorialButton<Content: View>: View {
        //Format for tutorial and app set up buttons that are not navigation views. these look the same as navlinks, so anything changed in TutorialNavLink should also be changed here.
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            //.textboarder(color: .black, lineWidth: 3)
            .frame(minWidth: 0, maxWidth: 300)
            .padding()
            .foregroundColor(.black)
            .background(Color.yellow)
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
            
            Spacer()
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
            
            Spacer()
            TutorialNavLink(destination: FindingSavedRoutes())  {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
        }
    }
}

struct SingleUse: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "singleUseRouteTutorialButtonText", comment: "Title for the single use route part of the tutorial"))
            
            Text(NSLocalizedString( "singleUseRouteTutorialInstructionText", comment: "Instructions for using the single use route"))
            
            Spacer()
            TutorialNavLink(destination: SavedRoutes()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
        }
    }
}

struct FindPath: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "findPathTutorialButtonText", comment: "Title for the finding and following path part of the tutorial"))
        
            Text(NSLocalizedString("findPathTutorialInstructionText", comment: "Text that explains what it sounds and feels like to be on the path and following the path"))
            
            //TutorialNavLink(destination: PracticeOrientPhone()) {Text(NSLocalizedString ("orientPhoneTutorialPracticeTitle", comment: "Title of the practice orienting your phone page"))}
        
            Spacer()
            TutorialNavLink(destination: SingleUse())  {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
            
            
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
            
            Spacer()
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
                //Creates a text box that gives visual feedback by shifting from red to yellow to green as a user holds thier phone correctly
            let y = transform.columns.0.y
                //Text("y-component \(y)")
                if started {
                    if y < -0.9 {
                        Text("score \(self.score)")
                            .frame(minWidth: 0, maxWidth: 150)
                            .padding()
                            .foregroundColor(.black)
                            .background(Color.green)
                            .cornerRadius(10)
                            .font(.system(size: 18, weight: .bold))
                    }
                    else if y < -0.7 && y > -0.9 {
                        Text("score \(self.score)")
                            .frame(minWidth: 0, maxWidth: 150) //TODO: figure out how to not write all of this over and over again and be able to change the color
                            .padding()
                            .foregroundColor(.black)
                            .background(Color.yellow)
                            .cornerRadius(10)
                            .font(.system(size: 18, weight: .bold))
                    }
                    else {
                        Text("score \(self.score)")
                            .frame(minWidth: 0, maxWidth: 150)
                            .padding()
                            .foregroundColor(.black)
                            .background(Color.red)
                            .cornerRadius(10)
                            .font(.system(size: 18, weight: .bold))
                    }
                } else {
                    Text("score \(self.score)")
                        .frame(minWidth: 0, maxWidth: 150)
                        .padding()
                        .foregroundColor(.black)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .font(.system(size: 18, weight: .bold))
                }
            }
            
            
            
            if score >= 3 {
                //AudioServicesPlaySystemSound(SystemSoundID(1057))
                //Text("Yay!!!")
                Spacer()
                TutorialNavLink(destination: FindPath()) {Text("Next")} //change skip button to next button when score equals three because the user has completed the practice
            }
            
            if score == 3 {
                Text("Nice Job! You've completed orientation practice. You can keep practicing or go to the next section") //TODO: create audio anouncment
            }

            else if score < 3 {
                Spacer()
                TutorialNavLink(destination: FindPath()) {Text("Skip")}
            }
        
            
        }.onDisappear() {
            started = false //turn feedback off when exiting the practice page or hitting stop
        }
        .onReceive(self.arData.objectWillChange) {newARData in
            if started {
                    if let transform = arData.transform {
                    let y = transform.columns.0.y
                        if y < 0.5 && y > -0.7, -lastSuccessSound.timeIntervalSinceNow > 0.2 {
                            AudioServicesPlaySystemSound(SystemSoundID(1057))
                            //AudioServicesPlaySystemSound(SystemSoundID(4095)) //TODO: add haptics
                            lastSuccessSound = Date()
                            lastSuccess = Date()
                            resetPosition = true
                    }
                    if y < -0.7 && y > -0.9, -lastSuccessSound.timeIntervalSinceNow > 0.5 {
                            AudioServicesPlaySystemSound(SystemSoundID(1057))
                            //AudioServicesPlaySystemSound(SystemSoundID(4095))
                            lastSuccessSound = Date()
                            lastSuccess = Date()
                            resetPosition = true
                    }
                        if y < -0.9, -lastSuccessSound.timeIntervalSinceNow > 0.7 {
                            AudioServicesPlaySystemSound(SystemSoundID(1057))
                            //AudioServicesPlaySystemSound(SystemSoundID(4095))
                            lastSuccessSound = Date()
                    }
                    if y < -0.9, resetPosition,  -lastSuccess.timeIntervalSinceNow > 2{
                            //to get another point, users have to move thier phones out of the correct position and then hold thier phones in the correct position for 2 seconds
                        print(score)
                        score += 1
                        lastSuccess = Date()
                        resetPosition = false
                        AudioServicesPlaySystemSound(SystemSoundID(1025))
                        //AudioServicesPlaySystemSound(SystemSoundID(4095))
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
            
            Spacer()
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
                    
                        
                TutorialNavLink(destination: FindPath()) {Text(NSLocalizedString( "findPathTutorialButtonText", comment: "Title for the finding and following path part of the tutorial"))
                }
                
                TutorialNavLink(destination: SingleUse()) {Text(NSLocalizedString( "singleUseRouteTutorialButtonText", comment: "Title for the single use route part of the tutorial"))
                }
                
                TutorialNavLink(destination: SavedRoutes()) {Text(NSLocalizedString( "savedRoutesTutorialButtonText", comment: "Title for the saved route part of the tutorial"))
                }
                
                TutorialNavLink(destination: FindingSavedRoutes()) {Text(NSLocalizedString( "findingSavedRoutesTutorialButtonText", comment: "Title for the finding saved route part of the tutorial"))
                }
                
                TutorialNavLink(destination: SettingOptions()) {Text(NSLocalizedString( "settingOptionsTutorialButtonText", comment: "Title for the setting options part of the tutorial"))
                }
            }
        }
    }
}


/*struct TutorialTestViews_Previews: PreviewProvider {
    static var previews: some View {
        TutorialTestView()
    }
}*/
