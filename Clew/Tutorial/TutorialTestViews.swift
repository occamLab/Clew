//
//  TutorialTestViews.swift
//  Clew
//
//  Created by Declan Ketchum on 6/21/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI
import AVFoundation
import Foundation

//TODO: 1 add content to all pages 4 add localized strings to everything

struct TutorialScreen<Content: View>: View {
    //format for all the tutorial and app set up screens. standarizes spacing and adds exit button to each page
  let content: Content
  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }
    var body: some View {
        ScrollView{
            VStack(spacing: 30) {
                content
                    .padding(.leading)
                    .padding(.trailing)
            }
        }

        .navigationBarItems(
            trailing:
                Button(NSLocalizedString("buttonTexttoExitTutorial", comment: "text of the button that dismisses the tutorial screens")) {
                    NotificationCenter.default.post(name: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil)
                    }
                .padding()
        )
    }
  }

//Colors:
let darkBlue = Color(red: 0.01, green: 0.15, blue: 1.05)
let skyBlue = Color(red: 0.4627, green: 0.8392, blue: 1.0)
//TODO: find our own clew colors



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
            .font(.system(size: 18, weight: .regular))
    }
}

struct TutorialTestView: View {
    @ObservedObject var settings = SettingsWrapper.shared
    @State var selection: String? = nil

    var body: some View {
        NavigationView{

            TutorialScreen{
                Text(NSLocalizedString("tutorialTitleText", comment: "Title of the Clew Tutorial Screen. Top of the first tutorial page"))
                        
                HStack{
                TutorialNavLink(destination: CLEWintro()) {
                    Text(NSLocalizedString("ClewIntroTutorialTitle", comment: "Intro to Clew Tutorial Title"))
                    }
                    if UserDefaults.standard.bool(forKey: "IntroTutorialCompleted") == true {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 30, height: 30)
                            
                    } else {
                        Circle()
                            .stroke(Color.gray, lineWidth: 1)
                            .frame(width: 30, height: 30)
                    }
                        
                    
                }
                
                HStack{
                TutorialNavLink(destination: OrientPhone()){
                    Text(NSLocalizedString("orientPhoneTutorialButtonText", comment: "Text for the tutorial screem for phone position"))
                }
                    if UserDefaults.standard.bool(forKey: "OrientPhoneTutorialCompleted") == true {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 30, height: 30)
                            
                    } else {
                        Circle()
                            .stroke(Color.gray, lineWidth: 1)
                            .frame(width: 30, height: 30)
                    }
                }
                    
                HStack{
                    //NavigationLink("FindPath", destination: FindPath(), tag: "FindPath", selection: $selection)
                TutorialNavLink(destination: FindPath()) {Text(NSLocalizedString( "findPathTutorialButtonText", comment: "Title for the finding and following path part of the tutorial"))
                }
                if UserDefaults.standard.bool(forKey: "FindPathTutorialCompleted") == true {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 30, height: 30)
                        
                } else {
                    Circle()
                        .stroke(Color.gray, lineWidth: 1)
                        .frame(width: 30, height: 30)
                }
                }
                
                HStack{
                TutorialNavLink(destination: SingleUse()) {Text(NSLocalizedString( "singleUseRouteTutorialButtonText", comment: "Title for the single use route part of the tutorial"))
                }
                if UserDefaults.standard.bool(forKey: "SingleUseTutorialCompleted") == true {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 30, height: 30)
                        
                } else {
                    Circle()
                        .stroke(Color.gray, lineWidth: 1)
                        .frame(width: 30, height: 30)
                }
                }
                
                HStack{
                TutorialNavLink(destination: SavedRoutes()) {Text(NSLocalizedString( "savedRoutesTutorialButtonText", comment: "Title for the saved route part of the tutorial"))
                }
                if UserDefaults.standard.bool(forKey: "SavedRoutesTutorialCompleted") == true {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 30, height: 30)
                        
                } else {
                    Circle()
                        .stroke(Color.gray, lineWidth: 1)
                        .frame(width: 30, height: 30)
                }
                }
                
                HStack{
                TutorialNavLink(destination: FindingSavedRoutes()) {Text(NSLocalizedString( "findingSavedRoutesTutorialButtonText", comment: "Title for the finding saved route part of the tutorial"))
                }
                if UserDefaults.standard.bool(forKey: "FindingSavedRoutesTutorialCompleted") {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 30, height: 30)
                        
                } else {
                    Circle()
                        .stroke(Color.gray, lineWidth: 1)
                        .frame(width: 30, height: 30)
                }
                }
                
                HStack{
                TutorialNavLink(destination: SettingOptions()) {Text(NSLocalizedString( "settingOptionsTutorialButtonText", comment: "Title for the setting options part of the tutorial"))
                }
                if UserDefaults.standard.bool(forKey: "SettingsOptionsTutorialCompleted") == true {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 30, height: 30)
                        
                } else {
                    Circle()
                        .stroke(Color.gray, lineWidth: 1)
                        .frame(width: 30, height: 30)
                    }
                }
            }
        }
    }
}

struct CLEWintro: View {
    //@EnvironmentObject var completed: status
    //@StateObject var completed = status()
    var body: some View {
        TutorialScreen{
            Text("Introduction to Clew")
            
            //ScrollView{
            Text(NSLocalizedString("ClewIntroTutorialText1", comment: "Text on the first page of the tutorial that describes Clew"))
            Text(NSLocalizedString("ClewIntroTutorialText2", comment: "Text on the first page of the tutorial that describes Clew"))
            Text(NSLocalizedString("ClewIntroTutorialText3", comment: "Text on the first page of the tutorial that describes Clew"))

                //.fixedSize(horizontal: false, vertical: true)
               // .lineLimit(100)//added these lines because text was being truncated and this fixed it, not sure why
                //.minimumScaleFactor(0.5)
                //.fixedSize()
                //.frame(width: 50, height: 70, alignment: .topLeading)
            //}
            
            Button(action:{
                UserDefaults.standard.setValue(false, forKey: "IntroTutorialCompleted")
                UserDefaults.standard.setValue(false, forKey: "OrientPhoneTutorialCompleted")
                UserDefaults.standard.setValue(false, forKey: "FindPathTutorialCompleted")
                UserDefaults.standard.setValue(false, forKey: "FindPathPractice1Completed")
                UserDefaults.standard.setValue(false, forKey: "FindPathPractice2Completed")
                UserDefaults.standard.setValue(false, forKey: "SingleUseTutorialCompleted")
                UserDefaults.standard.setValue(false, forKey: "SavedRoutesTutorialCompleted")
                UserDefaults.standard.setValue(false, forKey: "FindingSavedRoutesTutorialCompleted")
                UserDefaults.standard.setValue(false, forKey: "SettingsOptionsTutorialCompleted")
            }) {Text("Reset Tutorial Progress")}
                
            }.onDisappear() {
                UserDefaults.standard.setValue(true, forKey: "IntroTutorialCompleted")
    
        }
        Spacer()
        TutorialNavLink(destination: OrientPhone()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
    }
}


struct OrientPhone: View {
    var body: some View {
        TutorialScreen {
            Text(NSLocalizedString("orientPhoneTutorialButtonText", comment: "Title for the setting options part of the tutorial"))
        
            ScrollView{
            Text(NSLocalizedString("orientPhoneTutorialInstructionText", comment: "Text that explains how to orient the phone for the best experience using Clew"))
                //.fixedSize(horizontal: false, vertical: true)
            }
            
            TutorialNavLink(destination: OrientPhoneTips()) {Text(NSLocalizedString("tipTutorialTitle", comment: "text on button to tips page"))}
            
            TutorialNavLink(destination: PracticeOrientPhone()) {Text(NSLocalizedString("orientPhoneTutorialPracticeTitle", comment: "Title for holding phone practice"))}
            
            
        }
        Spacer()
            TutorialNavLink(destination: FindPath()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}

struct OrientPhoneTips: View {
    var body: some View {
        TutorialScreen {
            Text(NSLocalizedString("orientPhoneTutorialTipsTitle", comment: "Tips for holding phone title"))
            
            //ScrollView{
            Text(NSLocalizedString("orientPhoneTutorialTip1", comment: "Tip for holding phone against chest"))
            
            Text(NSLocalizedString("orientPhoneTutorialTip2", comment: "Tip for using Clew with cane or guide dog"))
            
        }
        Spacer()
        TutorialNavLink(destination: PracticeOrientPhone()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}


struct PracticeOrientPhone: View {
    //TODO: 1 can't exit right now bc the var arData is being updated constantly. 2 give haptic feedback  3 add success notification when activity is complete
    @State private var started = false
    //@State private var successAlert = false
    @State private var score = 0
    @State var lastSuccessSound = Date()
    @State var lastSuccess = Date()
    @State var playSuccess = true
    @State var resetPosition = true
    @State var successSound: AVAudioPlayer?
    @State var sound: AVAudioPlayer?
    @ObservedObject private var arData = ARData.shared
    let impactLight = UIImpactFeedbackGenerator(style: .light)
    let generator = UINotificationFeedbackGenerator()
    var body: some View{
        TutorialScreen {
            
            Text(NSLocalizedString("orientPhoneTutorialPracticeTitle", comment: "Title for holding phone practice"))
            
            //ScrollView{
            Text(NSLocalizedString("orientPhoneTutorialPracticeInstructions", comment: "Instructions for practicing holding phone activity"))
                //.fixedSize(horizontal: false, vertical: true)
            //}
            
            Button(action:{
                started.toggle()
                NotificationCenter.default.post(name: Notification.Name("StartARSession"), object: nil)
            }){
                if started {
                    TutorialButton{
                        Text(NSLocalizedString("orientPhoneTutorialPracticeStop", comment: "stop orient phone practice"))}
                } else {
                    TutorialButton{
                        Text(NSLocalizedString("orientPhoneTutorialPracticeStart", comment: "start orient phone practice"))}
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
                Text("Nice Job! You've completed orientation practice. You can keep practicing or go to the next section")
            }
            
        }.onDisappear() {
            started = false //turn feedback off when exiting the practice page or hitting stop
            
            UserDefaults.standard.setValue(true, forKey: "OrientPhoneTutorialCompleted")
            
        }.onReceive(self.arData.objectWillChange) {newARData in
            if started {
                    if let transform = arData.transform {
                    let y = transform.columns.0.y
                    let path1 = Bundle.main.path(forResource: "ClewTutorialFeedback", ofType:"wav")!
                    let url1 = URL(fileURLWithPath: path1)
                        if y < 0.9 && y > -0.7, -lastSuccessSound.timeIntervalSinceNow > 0.2 {
                            do {
                                sound = try AVAudioPlayer(contentsOf: url1)
                                sound?.play()
                            } catch {
                                // couldn't load file :(
                            }
                            //AudioServicesPlaySystemSound(SystemSoundID(1057))
                            self.generator.notificationOccurred(.warning)
                            lastSuccessSound = Date()
                            lastSuccess = Date()
                            resetPosition = true
                        }
                        if y < -0.7 && y > -0.9, -lastSuccessSound.timeIntervalSinceNow > 0.5 {
                            do {
                                sound = try AVAudioPlayer(contentsOf: url1)
                                sound?.play()
                            } catch {
                                // couldn't load file :(
                            }
                                //AudioServicesPlaySystemSound(SystemSoundID(1057))
                                self.generator.notificationOccurred(.warning)
                                lastSuccessSound = Date()
                                lastSuccess = Date()
                                resetPosition = true
                        }
                        if y < -0.9, -lastSuccessSound.timeIntervalSinceNow > 0.7 {
                            do {
                                sound = try AVAudioPlayer(contentsOf: url1)
                                sound?.play()
                            } catch {
                                // couldn't load file :(
                            }
                            //AudioServicesPlaySystemSound(SystemSoundID(1057))
                            impactLight.impactOccurred()
                            lastSuccessSound = Date()
                        }
                        //Version where there is more feedback when youre holding the phone correctly
                        /*if y < 0.5 && y > -0.7, -lastSuccessSound.timeIntervalSinceNow > 0.7 {
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
                        if y < -0.9, -lastSuccessSound.timeIntervalSinceNow > 0.2 {
                            AudioServicesPlaySystemSound(SystemSoundID(1057))
                            //AudioServicesPlaySystemSound(SystemSoundID(4095))
                            lastSuccessSound = Date()
                        }*/
                    if y < -0.9, resetPosition,  -lastSuccess.timeIntervalSinceNow > 2{
                            //to get another point, users have to move thier phones out of the correct position and then hold thier phones in the correct position for 2 seconds
                        score += 1
                        lastSuccess = Date()
                        resetPosition = false
                        self.generator.notificationOccurred(.success)
                        let path = Bundle.main.path(forResource: "ClewSuccessSound", ofType:"wav")!
                        let url = URL(fileURLWithPath: path)
                        do {
                            successSound = try AVAudioPlayer(contentsOf: url)
                            successSound?.play()
                        } catch {
                            // couldn't load file :(
                        }
                    }
                        
                    
                        
                    if score == 3, playSuccess {
                        playSuccess = false
                        UIAccessibility.post(notification: .announcement, argument: "Nice Job! You've completed phone orientation practice. You can keep practicing or go to the next section")
                    }
                }
            }
        }
        if score >= 3 {
            Spacer()
            TutorialNavLink(destination: FindPath()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))} //change skip button to next button when score equals three because the user has completed the practice
        }
        
        else if score < 3 {
            Spacer()
            TutorialNavLink(destination: FindPath()) {Text(NSLocalizedString("buttonTexttoSkip", comment: "Text on skip button"))}
        }
    }
}


struct FindPath: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "findPathTutorialButtonText", comment: "Title for the finding and following path part of the tutorial"))
        
            Text(NSLocalizedString("findPathTutorialInstructionText", comment: "Text that explains what it sounds and feels like to be on the path and following the path"))
                //.fixedSize(horizontal: false, vertical: true)
        
            TutorialNavLink(destination: FindPathPractice1())  {Text("Practice")}
            //TutorialNavLink(destination: TutorialEndView())  {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
            
        }
        Spacer()
        TutorialNavLink(destination: SingleUse())  {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}

struct FindPathPractice1: View {
    var body: some View {
        TutorialScreen{
            Text("Practice Path 1")
            
            Text("Here you will practice following a Clew Route. Make sure you are in a familiar place with some open space around you.")
            
            /*Button("Start") {
                NotificationCenter.default.post(name: Notification.Name("StartTutorialPath"), object: nil)
                NotificationCenter.default.post(name: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil)}*/
                
            Button(action:{
                NotificationCenter.default.post(name: Notification.Name("StartTutorialPath"), object: nil)
                NotificationCenter.default.post(name: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil)
                NotificationCenter.default.post(name: Notification.Name("BurgerMenuReadyToDismiss"), object: nil)
                UserDefaults.standard.setValue(false, forKey: "FindPathPractice1Completed")
            }){TutorialButton{
                Text("Practice 1")}}
            
        }
        Spacer()
            TutorialNavLink(destination: FindPathPractice2()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}


struct FindPathPractice2: View {
    var body: some View {
        TutorialScreen{
            Text("Practice Path 2")
            
            Text("Here you will practice following a Clew Route. Make sure you are in a familiar place with some open space around you.")
            
            Button(action:{
                NotificationCenter.default.post(name: Notification.Name("StartTutorialPath2"), object: nil)
                    NotificationCenter.default.post(name: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil)})
            {TutorialButton{
                Text("Start Practice")}}
            
        }.onDisappear(){
            UserDefaults.standard.setValue(true, forKey: "FindPathTutorialCompleted")
        }
        
        Spacer()
            TutorialNavLink(destination: SingleUse()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}


struct PracticeSuccess: View {
    @State var successSound: AVAudioPlayer?
    var body: some View {
        TutorialScreen{
            Text("Congradulations!")
            
            if UserDefaults.standard.bool(forKey: "FindPathPractice1Complete") == true {
                Text("You've completed the route practices. You can continue through the tutorial or go try out recording and praticing some of our own routes in a familiar space using Single Use Routes on the Clew home page.")
                
            }else {
                Text("You've completed the first route practice. Continue to the next practice to try another short route.")
            }
        }.onAppear()
        {let path1 = Bundle.main.path(forResource: "ClewSuccessSound", ofType:"wav")!
        let url1 = URL(fileURLWithPath: path1)
        do {
            successSound = try AVAudioPlayer(contentsOf: url1)
            successSound?.play()
        } catch {
            // couldn't load file :(
        }
        }.onDisappear() {
            if UserDefaults.standard.bool(forKey: "FindPathPractice1Complete") == true {
                UserDefaults.standard.setValue(true, forKey: "FindPathPractice2Completed")
            }else {
                UserDefaults.standard.setValue(true, forKey: "FindPathPractice1Completed")
            }
        }
        
        Spacer()
        if UserDefaults.standard.bool(forKey: "FindPathPractice1Complete") == true {
            TutorialNavLink(destination: FindPathPractice2()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
        }else {
            TutorialNavLink(destination: SingleUse()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
        }
    }
}


struct SingleUse: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "singleUseRouteTutorialButtonText", comment: "Title for the single use route part of the tutorial"))
            
            //ScrollView{
            Text(NSLocalizedString( "singleUseRouteTutorialInstructionText", comment: "Instructions for using the single use route"))
                //.fixedSize(horizontal: false, vertical: true)
            //}
            
        }.onDisappear(){
            UserDefaults.standard.setValue(true, forKey: "SingleUseTutorialCompleted")
        }
        
        Spacer()
        TutorialNavLink(destination: SavedRoutes()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}

struct RecordingSingleUse: View {
    var body: some View {
        TutorialScreen{
            
        TutorialNavLink(destination: AnchorPoints()) {Text(NSLocalizedString( "anchorPointTutorialButtonText", comment: "Title for the anchor point part of the tutorial"))}
        }
            
        Spacer()
        TutorialNavLink(destination: SavedRoutes()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}


struct SavedRoutes: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString("savedRoutesTutorialButtonText", comment: "Title for the saved route part of the tutorial"))
        
            Text(NSLocalizedString("savedRouteTutorialInstructionText", comment: "Instructions for using saved routes"))
                    //.fixedSize(horizontal: false, vertical: true)
        
        }.onDisappear(){
            UserDefaults.standard.setValue(true, forKey: "SavedRoutesTutorialCompleted")
        }
        Spacer()
        TutorialNavLink(destination: RecordSavedRoutes())  {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}

struct RecordSavedRoutes: View {
    var body: some View {
        TutorialScreen {
            Text(NSLocalizedString( "recordSavedRoutesTutorialButtonText", comment: "Title for the recording saved routes part of the tutorial"))
            
        //ScrollView{
        Text(NSLocalizedString("recordSavedRoutesTutorialInstructionText", comment: "Instructions for recording saved routes"))
            //.fixedSize(horizontal: false, vertical: true)
            
        TutorialNavLink(destination: AnchorPoints()) {Text(NSLocalizedString( "anchorPointTutorialButtonText", comment: "Title for the anchor point part of the tutorial"))}
        
        TutorialNavLink(destination: VoiceNotes()) {Text(NSLocalizedString( "voiceNotesTutorialButtonText", comment: "Title for the voice notes part of the tutorial"))}
            
        }
        
        Spacer()
        TutorialNavLink(destination: FindingSavedRoutes())  {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}

struct AnchorPoints: View {
    var body: some View {
        TutorialScreen  {
            Text(NSLocalizedString( "anchorPointTutorialButtonText", comment: "Title for the anchor point part of the tutorial"))
            
            //ScrollView{
            Text(NSLocalizedString("anchorPointTutorialInstructionText", comment: "Instructions for setting anchor points"))
                //.fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            TutorialNavLink(destination: VoiceNotes())  {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
                
    }
}

struct VoiceNotes: View {
    var body: some View {
        TutorialScreen  {
            Text(NSLocalizedString( "voiceNotesTutorialButtonText", comment: "Title for the voice notes part of the tutorial"))
            
            //ScrollView{
            Text(NSLocalizedString("voiceNotesTutorialInstructionText", comment: "Instructions for leaving voice notes along a path"))
                //.fixedSize(horizontal: false, vertical: true)
        }
            
            Spacer()
            TutorialNavLink(destination: FindingSavedRoutes())  {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}


struct FindingSavedRoutes: View {
    var body: some View {
        TutorialScreen  {
            Text(NSLocalizedString("findingSavedRoutesTutorialButtonText", comment: "Title for the finding saved route part of the tutorial"))
            
            //ScrollView{
            Text(NSLocalizedString("findingSavedRoutesTutorialInstructionText", comment: "Instructions for finding saved routes"))
                //.fixedSize(horizontal: false, vertical: true)
            }.onDisappear(){
                UserDefaults.standard.setValue(true, forKey: "FindingSavedRoutesTutorialCompleted")
            }
        Spacer()
        TutorialNavLink(destination: SettingOptions()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}


struct SettingOptions: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "settingOptionsTutorialButtonText", comment: "Title for the setting options part of the tutorial"))
            
            //ScrollView{
            Text(NSLocalizedString( "settingOptionsTutorialInstructionText", comment: "Information about what the setting options are"))
                //.fixedSize(horizontal: false, vertical: true)
        }.onDisappear(){UserDefaults.standard.setValue(true, forKey: "SettingsOptionsTutorialCompleted")}
        
        Spacer()
        TutorialNavLink(destination: SettingWalkThrough()) {Text(NSLocalizedString("settingsWalkThroughTitle", comment: "Title for the Settings Walk Through"))}
        
    }
}


struct TutorialEndView: View {
    var body: some View {
        TutorialScreen{
            Text("End of Tutorial")
            
            Text("Nice Job! You've completed the Clew tutorial. You can come back to this information at anytime through the menu options or by pressing the help button on the Clew main screens.")
        }
    }
}






/*struct Practice2Success: View {
    @State var successSound: AVAudioPlayer?
    var body: some View {
        TutorialScreen{
            Text("Congradulations!")
            
            Text("You've completed the route practices. You can continue through the tutorial or go try out recording and praticing some of our own routes in a familiar space using Single Use Routes on the Clew home page.")
        }.onAppear()
            {let path1 = Bundle.main.path(forResource: "ClewSuccessSound", ofType:"wav")!
            let url1 = URL(fileURLWithPath: path1)
            do {
                successSound = try AVAudioPlayer(contentsOf: url1)
                successSound?.play()
            } catch {
                // couldn't load file :(
            }
            }
        Spacer()
            TutorialNavLink(destination: SingleUse()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}*/

/*struct HapticTesting: View {
    let generator = UINotificationFeedbackGenerator()
    var body: some View{
        TutorialScreen{
            Button(action: {
                self.generator.notificationOccurred(.success)
            }) {
                Text("Success")
            }
            
            Button(action: {
                self.generator.notificationOccurred(.error)
            }) {
                Text("Error")
            }
            
            Button(action: {
                self.generator.notificationOccurred(.warning)
            }) {
                Text("Warning")
            }
            
            Button(action: {
                let impactLight = UIImpactFeedbackGenerator(style: .light)
                impactLight.impactOccurred()
            }) {
                Text("Light")
            }
            
            Button(action: {
                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()
            }) {
                Text("Medium")
            }
            
            Button(action: {
                let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                impactHeavy.impactOccurred()
            }) {
                Text("Heavy")
            }
            
            Button(action: {
                let selectionFeedback = UISelectionFeedbackGenerator()
                selectionFeedback.selectionChanged()
            }) {
                Text("Selection Feedback Changed")
            }
        .padding(.all, 30.0)
            
        }
    }
}*/
            
