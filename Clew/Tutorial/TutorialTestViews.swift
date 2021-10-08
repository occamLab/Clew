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
import SRCountdownTimer
import Intents
import IntentsUI

// TODOs
// Stop AR session when needed based on the tutorial state
// Maybe add a warning if the user turns off the feedback options.
// Go into Clew Initial Setup (or other suitable screen) on first app launch.

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
                .frame(minWidth: 0, maxWidth: 300)
                .padding()
                .foregroundColor(.black)
                .background(Color.yellow)
                .cornerRadius(10)
                .font(.system(size: 18, weight: .regular))
        }
    }
}


struct TutorialNavLinkWithProgress<Destination: View, Content: View>: View {
    //creates a button format for all the CLEW tutorial navigation links to use. only works for navigation links
    let content: Content
    let destination: Destination
    let tag: String
    
    init(destination: Destination, tag: String, @ViewBuilder content: () -> Content) {
        self.destination = destination
        self.tag = tag
        self.content = content()
    }
    
    var body: some View {
        NavigationLink(destination: self.destination) {
            content
                .frame(minWidth: 0, maxWidth: 300)
                .padding()
                .foregroundColor(.black)
                .background(Color.yellow)
                .cornerRadius(10)
                .font(.system(size: 18, weight: .regular))
                .accessibility(hint: UserDefaults.standard.bool(forKey: tag + "TutorialCompleted") ? Text(NSLocalizedString("moduleCompleted", comment: "played as the accessibility hint in the tutorial to indicate that the current module has been completed")) : Text(NSLocalizedString("moduleNotCompleted", comment: "played as the accessibility hint in the tutorial to indicate that the current module has not been completed")) )
            if UserDefaults.standard.bool(forKey: tag + "TutorialCompleted") {
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


struct TutorialButton<Content: View>: View {
    //Format for tutorial and app set up buttons that are not navigation views. these look the same as navlinks, so anything changed in TutorialNavLink should also be changed here.
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .frame(minWidth: 0, maxWidth: 300)
            .padding()
            .foregroundColor(.black)
            .background(Color.yellow)
            .cornerRadius(10)
            .font(.system(size: 18, weight: .regular))
    }
}

class ShowTutorialPage: ObservableObject {
    @Published var confineToSection: Bool = false
    public static var shared = ShowTutorialPage()
    
    private init() {
    }
}

struct TutorialTestView: View {
    @ObservedObject var settings = SettingsWrapper.shared
    @ObservedObject var showPage = ShowTutorialPage.shared
    var body: some View {
        NavigationView {
            TutorialScreen{
                Text(NSLocalizedString("tutorialTitleText", comment: "Title of the Clew Tutorial Screen. Top of the first tutorial page"))
                
                HStack {
                    TutorialNavLinkWithProgress(destination: CLEWintro(), tag: "CLEWintro") {
                        Text(NSLocalizedString("ClewIntroTutorialTitle", comment: "Intro to Clew Tutorial Title"))
                    }
                }
                
                HStack {
                    TutorialNavLinkWithProgress(destination: OrientPhone(), tag: "OrientPhone") {
                        Text(NSLocalizedString("orientPhoneTutorialButtonText", comment: "Text for the tutorial screem for phone position"))
                    }
                }
                
                HStack {
                    TutorialNavLinkWithProgress(destination: FindPath(), tag: "FindPath") {
                        Text(NSLocalizedString( "findPathTutorialButtonText", comment: "Title for the finding and following path part of the tutorial"))
                    }
                }
                
                HStack {
                    TutorialNavLinkWithProgress(destination: SingleUse(), tag: "SingleUse") {
                        Text(NSLocalizedString( "singleUseRouteTutorialButtonText", comment: "Title for the single use route part of the tutorial"))
                    }
                }
                
                HStack {
                    TutorialNavLinkWithProgress(destination: AnchorPoints(), tag: "AnchorPoints") {
                        Text(NSLocalizedString("anchorPointsTutorialTitle", comment: "this is the title of the anchor points tutorial section"))
                    }
                }
                
                HStack {
                    TutorialNavLinkWithProgress(destination: SavedRoutes(), tag: "SavedRoutes") {Text(NSLocalizedString( "savedRoutesTutorialButtonText", comment: "Title for the saved route part of the tutorial"))
                    }
                }
                
                HStack {
                    TutorialNavLinkWithProgress(destination: SettingOptions(), tag: "SettingsOptions") {
                        Text(NSLocalizedString( "settingOptionsTutorialButtonText", comment: "Title for the setting options part of the tutorial"))
                    }
                }
                
                HStack {
                    TutorialNavLinkWithProgress(destination: SiriWalkthrough(), tag: "SiriWalkthrough") {
                        Text(NSLocalizedString( "siriWalkthroughTutorialButtonText", comment: "Title for the siri walkthrough part of the tutorial"))
                    }
                }
            }
        }
    }
}

struct CLEWintro: View {
    //TODO: Hide or Delete reset button
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString("ClewIntroTutorialTitle", comment: "Title for Clew Intro"))
            
            //ScrollView{
            Text(NSLocalizedString("ClewIntroTutorialText", comment: "Text on the first page of the tutorial that describes Clew"))
            // Disabled for now
//            Button(action:{
//                UserDefaults.standard.setValue(false, forKey: "CLEWintroTutorialCompleted")
//                UserDefaults.standard.setValue(false, forKey: "OrientPhoneTutorialCompleted")
//                UserDefaults.standard.setValue(false, forKey: "FindPathTutorialCompleted")
//                UserDefaults.standard.setValue(false, forKey: "FindPathPractice1Completed")
//                UserDefaults.standard.setValue(false, forKey: "FindPathPractice2Completed")
//                UserDefaults.standard.setValue(false, forKey: "AnchorPointsTutorialCompleted")
//                UserDefaults.standard.setValue(false, forKey: "SingleUseTutorialCompleted")
//                UserDefaults.standard.setValue(false, forKey: "SavedRoutesTutorialCompleted")
//                UserDefaults.standard.setValue(false, forKey: "FindingSavedRoutesTutorialCompleted")
//                UserDefaults.standard.setValue(false, forKey: "SettingsOptionsTutorialCompleted")
//                UserDefaults.standard.setValue(false, forKey: "SiriWalkthroughTutorialCompleted")
//            }) {
//                Text("Reset Tutorial Progress")
//            }
            
            
        }
        Spacer()
        TutorialNavLink(destination: UsingClew()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct UsingClew: View {
    var body: some View {
        TutorialScreen {
            
            Text(NSLocalizedString("introUsingClewTitle", comment: "Title for intro to Using Clew Page"))
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("introUsingClewTextParagraph1", comment: "Text for intro to Using Clew Page Paragraph 1"))
            
                Text(NSLocalizedString("introUsingClewTextParagraph2", comment: "Text for intro to Using Clew Page Paragraph 2"))
            }

            //Add link to examples of Clew's use?
        }
        Spacer()
        TutorialNavLink(destination: ClewsRole()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct ClewsRole: View {
    var body: some View {
        TutorialScreen {
            
            Text(NSLocalizedString("introClewsRoleTutorialTitle", comment: "Title for intro to Clew's role Page"))
            VStack(alignment: .leading, spacing: 20) {

                Text(NSLocalizedString("introClewsRoleTutorialTextParagraph1", comment: "Text for intro to Clew's role Page Paragraph 1"))
                Text(NSLocalizedString("introClewsRoleTutorialTextParagraph2", comment: "Text for intro to Clew's role Page Paragraph 2"))
                Text(NSLocalizedString("introClewsRoleTutorialTextParagraph3", comment: "Text for intro to Clew's role Page Paragraph 3"))
                Text(NSLocalizedString("introClewsRoleTutorialTextParagraph4", comment: "Text for intro to Clew's role Page Paragraph 4"))
            }
        }
        Spacer()
        TutorialNavLink(destination: UsingClewTutorial()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct UsingClewTutorial: View {
    var body: some View {
        TutorialScreen {
            
            Text(NSLocalizedString("introUsingClewTutorialTitle", comment: "Title for intro to Using Clew Tutorial Page"))
            
            Text(NSLocalizedString("introUsingClewTutorialText", comment: "Text for intro to Using Clew Tutorial Page"))
            
        }.onDisappear() {
            UserDefaults.standard.setValue(true, forKey: "CLEWintroTutorialCompleted")
        }
        Spacer()
        TutorialNavLink(destination: OrientPhone()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}
//
//struct ClewExamples: View {
//    //Not in Tutorial at the moment
//    var body: some View {
//        TutorialScreen {
//            Text("What Can I Use Clew For?")
//            
//            Text("Clew is a versitile tool for traveling from point A to B. Below are some examples of what situations current users find Clew helpful.")
//            
//            Text("You could use Clew when visting a hotel, by saving a Clew route from the front door to the elevator and then save a route from the elevator to your room. Then you could use Clew to navigate those routes whenever you like.")
//            
//            Text("You could use Clew to navigate between your table and the restroom in a resturant.")
//            
//        }
//    }
//}


struct OrientPhone: View {
    var body: some View {
        TutorialScreen {
            Text(NSLocalizedString("orientPhoneTutorialButtonText", comment: "Title for the setting options part of the tutorial"))
            
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("orientPhoneTutorialInstructionTextParagraph1", comment: "Text that explains how to orient the phone for the best experience using Clew Paragraph 1"))
                Text(NSLocalizedString("orientPhoneTutorialInstructionTextParagraph2", comment: "Text that explains how to orient the phone for the best experience using Clew Paragraph 2"))
                Text(NSLocalizedString("orientPhoneTutorialInstructionTextParagraph3", comment: "Text that explains how to orient the phone for the best experience using Clew Paragraph 3"))
            }
            
            TutorialNavLink(destination: PracticeOrientPhone()) {
                Text(NSLocalizedString("practiceTutorialTitle", comment: "button for practicing a skill in the tutorial"))
            }.padding()
            
            
        }
        Spacer()
        TutorialNavLink(destination: FindPath()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
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
        TutorialNavLink(destination: FindPath()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct PracticeOrientPhoneSubComponent: View {
    let didCompleteActivity: Binding<Bool>
    @ObservedObject private var arData = ARData.shared
    @State var lastSuccessSound = Date()
    @State var lastSuccess = Date()
    @State private var started = false
    @State private var score = 0
    @State var resetPosition = true
    @State var playSuccess = true
    let generator = UINotificationFeedbackGenerator()
    let impactLight = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        Text(NSLocalizedString("orientPhoneTutorialPracticeTitle", comment: "Title for holding phone practice"))
        
        VStack(alignment: .leading, spacing: 20) {
            Text(NSLocalizedString("orientPhoneTutorialPracticeInstructionsParagraph1", comment: "Instructions for practicing holding phone activity paragraph 1"))
            Text(NSLocalizedString("orientPhoneTutorialPracticeInstructionsParagraph2", comment: "Instructions for practicing holding phone activity paragraph 2"))
            Text(NSLocalizedString("orientPhoneTutorialPracticeInstructionsParagraph3", comment: "Instructions for practicing holding phone activity paragraph 3"))
        }
        
        Button(action:{
            started.toggle()
            NotificationCenter.default.post(name: Notification.Name("StartARSessionForTutorialModule"), object: nil)
        }){
            if started {
                TutorialButton{
                    Text(NSLocalizedString("orientPhoneTutorialPracticeStop", comment: "stop orient phone practice"))
                }
            } else {
                TutorialButton {
                    Text(NSLocalizedString("orientPhoneTutorialPracticeStart", comment: "start orient phone practice"))
                }
            }
        }
        
        if let transform = arData.transform {
            //Creates a text box that gives visual feedback by shifting from red to yellow to green as a user holds thier phone correctly
            let y = transform.columns.0.y
            Text("\(NSLocalizedString("score", comment: "used to define the score of the user when practicing a skill")) \(self.score)").applyStylingForOrientationTutorial(started: started, xDeviceOnGlobalY: y)
        }
        
        if score >= 3 {
            Text(NSLocalizedString("orientPhoneTutorialPracticeSuccess", comment: "Text when user has completed the phone position practice"))
        }
        Spacer()
            .frame(height: 50)
            .onReceive(self.arData.objectWillChange) { newARData in
            if started {
                if let transform = arData.transform {
                    let y = transform.columns.0.y
                    if y < -0.9 {
                        if resetPosition, -lastSuccess.timeIntervalSinceNow > 2 {
                            score += 1
                            lastSuccess = Date()
                            resetPosition = false
                            self.generator.notificationOccurred(.success)
                            SoundEffectManager.shared.success()
                        }
                    } else {
                        let desiredInterval = y > -0.7 ? 0.2 : 0.5
                        resetPosition = y > -0.7 || resetPosition
                        if -lastSuccessSound.timeIntervalSinceNow > desiredInterval {
                            SoundEffectManager.shared.error()
                            impactLight.impactOccurred()
                            lastSuccessSound = Date()
                        }
                    }
                
                    if score == 3, playSuccess {
                        playSuccess = false
                        UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("orientPhoneTutorialPracticeSuccess", comment: "Text when user has completed the phone position practice"))
                        didCompleteActivity.wrappedValue.toggle()
                    }
                }
            }
        }.onDisappear() {
            started = false //turn feedback off when exiting the practice page or hitting stop
            
            UserDefaults.standard.setValue(true, forKey: "OrientPhoneTutorialCompleted")
        }
    }
}

extension Text {
    func applyStylingForOrientationTutorial(started: Bool, xDeviceOnGlobalY: Float)->some View {
        if started {
            if xDeviceOnGlobalY < -0.9 {
                return self
                .frame(minWidth: 0, maxWidth: 150)
                .padding()
                .foregroundColor(.black)
                .background(Color.green)
                .cornerRadius(10)
                .font(.system(size: 18, weight: .bold))
            } else if xDeviceOnGlobalY < -0.7 {
                return self
                    .frame(minWidth: 0, maxWidth: 150) //TODO: figure out how to not write all of this over and over again and be able to change the color
                    .padding()
                    .foregroundColor(.black)
                    .background(Color.yellow)
                    .cornerRadius(10)
                    .font(.system(size: 18, weight: .bold))
            } else {
                return self
                    .frame(minWidth: 0, maxWidth: 150)
                    .padding()
                    .foregroundColor(.black)
                    .background(Color.red)
                    .cornerRadius(10)
                    .font(.system(size: 18, weight: .bold))
            }
        } else {
            return self
                .frame(minWidth: 0, maxWidth: 150)
                .padding()
                .foregroundColor(.black)
                .background(Color.blue)
                .cornerRadius(10)
                .font(.system(size: 18, weight: .bold))
        }
    }
}


struct PracticeOrientPhone: View {
    //TODO: 1 add notification to remind people that they have to move their phone out of the correct position and back to get another point.
    @State var successSound: AVAudioPlayer?
    @State var didCompleteActivity: Bool = false
    var body: some View {
        TutorialScreen {
            // we nest the AR interactive component inside of a view component to prevent the constant AR session updates from invalidating the exit button
            PracticeOrientPhoneSubComponent(didCompleteActivity: $didCompleteActivity)
        }
        if didCompleteActivity {
            Spacer()
            TutorialNavLink(destination: OrientPhoneTips()) {
                Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
            }.padding() //change skip button to next button when score equals three because the user has completed the practice
        } else {
            Spacer()
            TutorialNavLink(destination: OrientPhoneTips()) {
                Text(NSLocalizedString("buttonTexttoSkip", comment: "Text on skip button"))
            }.padding()
        }
    }
}


struct FindPath: View {
    // TODO: when called contextually, we don't want to launch into the test routes
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "findPathTutorialButtonText", comment: "Title for the finding and following path part of the tutorial"))
            
            Text(NSLocalizedString("findPathTutorialInstructionText", comment: "Text that explains what it sounds and feels like to be on the path and following the path"))
        }
        Spacer()
        TutorialNavLink(destination: MovingOnCorrectPath())  {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct MovingOnCorrectPath: View {
    // TODO: when called contextually, we don't want to launch into the test routes
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "movingOnCorrectPathTitleText", comment: "Title for the moving on the correfct path"))
            
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("movingOnCorrectPathInstructionTextParagraph1", comment: "Text that explains how to move on the correfct path paragraph 1"))
                Text(NSLocalizedString("movingOnCorrectPathInstructionTextParagraph2", comment: "Text that explains how to move on the correfct path paragraph 2"))
            }
        }
        Spacer()
        TutorialNavLink(destination: Waypoints())  {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct Waypoints: View {
    // TODO: when called contextually, we don't want to launch into the test routes
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "waypointsTutorialTitleText", comment: "Title for the waypoints part of the tutorial"))
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("waypointsTutorialInstructionTextParagraph1", comment: "Text that explains the concept of waypoints paragraph 1"))
                Text(NSLocalizedString("waypointsTutorialInstructionTextParagraph2", comment: "Text that explains the concept of waypoints paragraph 2"))
            }

        }
        Spacer()
        TutorialNavLink(destination: DirectionalCues())  {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct DirectionalCues: View {
    // TODO: when called contextually, we don't want to launch into the test routes
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "directionalCuesTutorialTitleText", comment: "Title for the directional cues part of the tutorial"))
            
            Text(NSLocalizedString( "directionalCuesTutorialInstructionText", comment: "Instructions for the directional cues part of the tutorial"))
        }
        Spacer()
        TutorialNavLink(destination: GettingBackToTheCorrectPath())  {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}


struct GettingBackToTheCorrectPath: View {
    // TODO: when called contextually, we don't want to launch into the test routes
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "gettingBackToTheCorrectPathTutorialTitleText", comment: "Title for the getting back to the path part of the tutorial"))
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("gettingBackToTheCorrectPathTutorialInstructionTextParagraph1", comment: "Text that explains getting back to the correct path paragraph 1"))
                Text(NSLocalizedString("gettingBackToTheCorrectPathTutorialInstructionTextParagraph2", comment: "Text that explains getting back to the correct path paragraph 2"))
            }
            Image("GetDirection")
                .resizable()
                .frame(width: 100, height: 100)
        }
        Spacer()
        TutorialNavLink(destination: FindPathPractice1())  {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct FindPathPractice1: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString("findPathPractice1Title", comment: "Text for the title of the first following route practice."))
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("findPathPractice1InstructionTextParagraph1", comment: "Text for the instructions of the first following route practice paragraph 1"))
                Text(NSLocalizedString("findPathPractice1InstructionTextParagraph2", comment: "Text for the instructions of the first following route practice paragraph 2"))
                Text(NSLocalizedString("findPathPractice1InstructionTextParagraph3", comment: "Text for the instructions of the first following route practice paragraph 3"))
            }
            
            Button(action: {
                NotificationCenter.default.post(name: Notification.Name("StartTutorialPath"), object: nil)
                NotificationCenter.default.post(name: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil)
                NotificationCenter.default.post(name: Notification.Name("BurgerMenuReadyToDismiss"), object: nil)
                UserDefaults.standard.setValue(false, forKey: "FindPathPractice1Completed")
            }) {
                TutorialButton {
                    Text(NSLocalizedString("practiceTutorialTitle", comment: "Text for the begin button of the first following route practice."))
                }
            }
        }
        Spacer()
        TutorialNavLink(destination: FindPathPractice2()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}


struct FindPathPractice2: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString("findPathPractice2Title", comment: "Text for the title of the second following route practice."))
            
            Text(NSLocalizedString("findPathPractice2InstructionText", comment: "Text for the instructions of the second following route practice."))
            
            Button(action:{
                    NotificationCenter.default.post(name: Notification.Name("StartTutorialPath2"), object: nil)
                    NotificationCenter.default.post(name: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil)
                    UserDefaults.standard.setValue(true, forKey: "FindPathPractice1Completed")
            }) {
                TutorialButton {
                Text(NSLocalizedString("practiceTutorialTitle", comment: "Text for the begin practice for the second following route practice."))
                }
            }
            
        }.onDisappear(){
            UserDefaults.standard.setValue(true, forKey: "FindPathTutorialCompleted")
        }
        
        Spacer()
        TutorialNavLink(destination: SingleUse()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}


struct PracticeSuccess: View {
    //TODO: fix success page comes up even if you don't complete the practice route
    @State var successSound: AVAudioPlayer?
    var body: some View {
        NavigationView {
            TutorialScreen{
                Text(NSLocalizedString("findPathPracticeSuccessTitle", comment: "Text for the title of the success page for following route practice."))
                
                if UserDefaults.standard.bool(forKey: "FindPathPractice1Completed") {
                    Text(NSLocalizedString("findPathPracticeSuccess2Text", comment: "Text for the success of the second practice route."))
                } else {
                    Text(NSLocalizedString("findPathPracticeSuccess1Text", comment: "Text for the success of the first practice route."))
                }
                
                Spacer()
                    .frame(height: 100)
                if UserDefaults.standard.bool(forKey: "FindPathPractice1Completed") {
                    TutorialNavLink(destination: SingleUse()) {
                        Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
                    }.padding()
                } else {
                    TutorialNavLink(destination: FindPathPractice2()) {
                        Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
                    }.padding()
                }
            }
            
        }.onAppear() {
            SoundEffectManager.shared.success()
        }
    }
}


struct SingleUse: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "singleUseRouteTutorialButtonText", comment: "Title for the single use route part of the tutorial"))
            
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString( "singleUseRouteTutorialInstructionTextParagraph1", comment: "Instructions for using the single use route paragraph 1"))
                Text(NSLocalizedString( "singleUseRouteTutorialInstructionTextParagraph2", comment: "Instructions for using the single use route paragraph 2"))
                Text(NSLocalizedString( "singleUseRouteTutorialInstructionTextParagraph3", comment: "Instructions for using the single use route paragraph 3"))
            }
            
        }.onDisappear(){
            UserDefaults.standard.setValue(true, forKey: "SingleUseTutorialCompleted")
        }
        
        Spacer()
        TutorialNavLink(destination: UsingSingleUse()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct UsingSingleUse: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString("usingSingleUseRouteTutorialTitle", comment: "Title for using single use route section"))
            
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("usingSingleUseRouteTutorialTextParagraph1", comment: "Instruction for how to use single use routes paragraph 1"))
                Text(NSLocalizedString("usingSingleUseRouteTutorialTextParagraph2", comment: "Instruction for how to use single use routes paragraph 2"))
                Text(NSLocalizedString("usingSingleUseRouteTutorialTextParagraph3", comment: "Instruction for how to use single use routes paragraph 3"))
            }
        }
        
        Spacer()
        TutorialNavLink(destination: AddingALandmark()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct AddingALandmark: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString("addingALandmarkTutorialTitle", comment: "Title for the add a landmark  section of the tutorial"))
            
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("addingALandmarkTutorialTextParagraph1", comment: "Instruction for how to add a landmark paragraph 1"))
                Text(NSLocalizedString("addingALandmarkTutorialTextParagraph2", comment: "Instruction for how to add a landmark paragraph 2"))
                Text(NSLocalizedString("addingALandmarkTutorialTextParagraph3", comment: "Instruction for how to add a landmark paragraph 3"))
                Text(NSLocalizedString("addingALandmarkTutorialTextParagraph4", comment: "Instruction for how to add a landmark paragraph 4"))
            }
        }
        
        Spacer()
        TutorialNavLink(destination: PausingNavigation()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct PausingNavigation: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString("pausingNavigationTutorialTitle", comment: "Title for the pause navigation section of the tutorial"))
            
            Text(NSLocalizedString("pausingNavigationTutorialText", comment: "Instruction for how to pause navigation"))
        }
        
        Spacer()
        TutorialNavLink(destination: AnchorPoints()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct AnchorPoints: View {
    @ObservedObject var showPage = ShowTutorialPage.shared
    var body: some View {
        TutorialScreen  {
            Text(NSLocalizedString( "anchorPointsTutorialTitle", comment: "Title for the anchor point part of the tutorial"))
            
            Text(NSLocalizedString("anchorPointsTutorialText", comment: "Instructions for setting anchor points"))
            
            TutorialNavLink(destination: SettingAnAnchorPoint())  {
                Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
            }.padding()
        }
        
        if !showPage.confineToSection {
            Spacer()
            TutorialNavLink(destination: SavedRoutes())  {
                Text(NSLocalizedString("buttonTexttoSkip", comment: "Text on the button that brings user to the next page of the tutorial"))
            }.padding()
        }
    }
}

struct SettingAnAnchorPoint: View {
    var body: some View {
        TutorialScreen {
            Text(NSLocalizedString("settingAnAnchorPointTutorialTitle", comment: "Title of setting an anchor point page"))
            
            Text(NSLocalizedString("settingAnAnchorPointTutorialText", comment: "Text of setting an anchor point page"))
        }
        
        Spacer()
        TutorialNavLink(destination: TextOrVoiceNotes())  {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct TextOrVoiceNotes: View {
    var body: some View {
        TutorialScreen {
            Text(NSLocalizedString("textOrVoiceNotesTutorialTitle", comment: "Title of text or voice notes page"))
            
            Text(NSLocalizedString("textOrVoiceNotesTutorialText", comment: "Text of text or voice notes page"))
        }
        
        Spacer()
        TutorialNavLink(destination: PhysicalAlignment())  {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}


struct PhysicalAlignment: View {
    var body: some View {
        TutorialScreen {
            Text(NSLocalizedString("physicalAlignmentTutorialTitle", comment: "Title of the physical alignment part of the tutorial"))
            
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("physicalAlignmentTutorialTextParagraph1", comment: "Text of the physical alignment part of the tutorial paragraph 1"))
                Text(NSLocalizedString("physicalAlignmentTutorialTextParagraph2", comment: "Text of the physical alignment part of the tutorial paragraph 2"))
            }
        }
        
        Spacer()
        TutorialNavLink(destination: FindingAnAnchorPoint())  {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct FindingAnAnchorPoint: View {
    var body: some View {
        TutorialScreen {
            Text(NSLocalizedString("findingAnAnchorPointTutorialTitle", comment: "Title of the finding your anchor point part of the tutorial"))
            
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("findingAnAnchorPointTutorialTextParagraph1", comment: "Text of the finding your anchor point part of the tutorial paragraph 1"))
                Text(NSLocalizedString("findingAnAnchorPointTutorialTextParagraph2", comment: "Text of the finding your anchor point part of the tutorial paragraph 2"))
//                Text(NSLocalizedString("findingAnAnchorPointTutorialTextParagraph3", comment: "Text of the finding your anchor point part of the tutorial paragraph 3"))
            }
        }
        
        Spacer()
        TutorialNavLink(destination: ApplesARWorldMap())  {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct ApplesARWorldMap: View {
    var body: some View {
        TutorialScreen {
            Text(NSLocalizedString("applesARWorldMapTutorialTitle", comment: "Title of the AR world map part of the tutorial"))
            
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("applesARWorldMapTutorialTextParagraph1", comment: "Text of the AR world map part of the tutorial paragraph 1"))
                Text(NSLocalizedString("applesARWorldMapTutorialTextParagraph2", comment: "Text of the AR world map part of the tutorial paragraph 2"))
            }
        }
        
        Spacer()
        TutorialNavLink(destination: AnchorPointPractice())  {
            Text(NSLocalizedString("practiceTutorialTitle", comment: "Text for practice button"))
        }.padding()
    }
}

enum AlignmentAccuracy {
    case none
    case bad
    case good
    case perfect
}

class TimerDelegate: SRCountdownTimerDelegate, ObservableObject {
    var timerEnded = false

    func timerDidEnd() {
        timerEnded = true
        objectWillChange.send()
    }
    func timerDidUpdateCounterValue(newValue: Int) {
        UIAccessibility.post(notification: .announcement, argument: String(newValue))
    }
}

enum AnchorPointPracticeState {
    case initial
    case anchorPointCreationRequested
    case anchorPointSet
    case readyForAlignmentInstructions
    case anchorPointAlignmentRequested
    case anchorPointAligned
}

struct AnchorPointPracticeSubComponent: View {
    @ObservedObject private var arData = ARData.shared
    @StateObject private var timerDelegate = TimerDelegate()
    @State private var practiceState: AnchorPointPracticeState = .initial
    @State var xyzYawSet: [Float] = []
    @State var xyzYawAlign: [Float] = []
    @State var xyzYawDelta: [Float] = []
    @State var accuracy: AlignmentAccuracy = .none

    static let xPerfectThreshold = Float(0.5)
    static let yPerfectThreshold = Float(0.5)
    static let zPerfectThreshold = Float(0.5)
    static let yawPerfectThreshold = Float(0.1)
    static let xGoodThreshold = Float(0.8)
    static let yGoodThreshold = Float(1.0)
    static let zGoodThreshold = Float(0.8)
    static let yawGoodThreshold = Float(0.2)
    
    var body: some View {
        Image("Align")
            .resizable()
            .frame(width: 100, height: 100)
        
        if practiceState == .anchorPointSet {
            Text(NSLocalizedString("anchorPointPracticeAlignTitle", comment: "Align to anchor point page title")).padding()
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("anchorPointPracticeAlignTextParagraph1", comment: "Align to anchor point page instructions paragraph 1"))
                Text(NSLocalizedString("anchorPointPracticeAlignTextParagraph2", comment: "Align to anchor point page instructions paragraph 2"))
            }
        } else if practiceState == .readyForAlignmentInstructions || practiceState == .anchorPointAlignmentRequested {
            Text(NSLocalizedString("findingSavedAnchorPointTitle", comment: "Find anchor point page title")).padding()
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("findingSavedAnchorPointTextParagraph1", comment: "Find anchor point page instructions paragraph 1"))
                Text(NSLocalizedString("findingSavedAnchorPointTextParagraph2", comment: "Find anchor point page instructions paragraph 2"))
                Text(NSLocalizedString("findingSavedAnchorPointTextParagraph3", comment: "Find anchor point page instructions paragraph 3"))
            }
        } else if practiceState == .initial || practiceState == .anchorPointCreationRequested {
            //when starting anchor point practice
            Text(NSLocalizedString("anchorPointPracticeSetTutorialTitle", comment: "Set an anchor point practice page title")).padding()
            
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("anchorPointPracticeSetTutorialTextParagraph1", comment: "Set an anchor point practice page instructions paragraph 1"))
                Text(NSLocalizedString("anchorPointPracticeSetTutorialTextParagraph2", comment: "Set an anchor point practice page instructions paragraph 2"))
            }
        }
        
        if practiceState == .anchorPointCreationRequested {
            CountdownView(timerDelegate: timerDelegate)
                .frame(minWidth: 100, maxWidth: 100, minHeight: 100, maxHeight: 100)
                .onReceive(self.timerDelegate.objectWillChange) { timer in
                    if self.timerDelegate.timerEnded {
                        if let transform = arData.transform {
                            let x = transform.columns.3.x
                            let y = transform.columns.3.y
                            let z = transform.columns.3.z
                            let yaw = ViewController.getYawHelper(transform)
                            xyzYawSet = [x, y, z, yaw]
                        }
                        practiceState = .anchorPointSet
                        SoundEffectManager.shared.meh()
                    }
                }
        } else if practiceState == .anchorPointAlignmentRequested {
            CountdownView(timerDelegate: timerDelegate)
                .frame(minWidth: 100, maxWidth: 100, minHeight: 100, maxHeight: 100)
                .onReceive(self.timerDelegate.objectWillChange) { timer in
                    if let transform = arData.transform {
                        let x = transform.columns.3.x
                        let y = transform.columns.3.y
                        let z = transform.columns.3.z
                        let yaw = ViewController.getYawHelper(transform)
                        xyzYawAlign = [x, y, z, yaw]
                        xyzYawDelta = [xyzYawAlign[0] - xyzYawSet[0], xyzYawAlign[1] - xyzYawSet[1], xyzYawAlign[2] - xyzYawSet[2], xyzYawAlign[3] - xyzYawSet[3]]
                        if abs(xyzYawDelta[0]) < Self.xPerfectThreshold, abs(xyzYawDelta[1]) < Self.yPerfectThreshold, abs(xyzYawDelta[2]) < Self.zPerfectThreshold, abs(xyzYawDelta[3]) < Self.yawPerfectThreshold {
                            accuracy = .perfect
                            SoundEffectManager.shared.success()
                        } else if abs(xyzYawDelta[0]) < Self.xGoodThreshold, abs(xyzYawDelta[1]) < Self.yGoodThreshold, abs(xyzYawDelta[2]) < Self.zGoodThreshold, abs(xyzYawDelta[3]) < Self.yawGoodThreshold  {
                            accuracy = .good
                            SoundEffectManager.shared.meh()
                        } else {
                            accuracy = .bad
                            SoundEffectManager.shared.error()
                        }
                        DispatchQueue.main.async {
                            practiceState = .anchorPointAligned
                        }
                    }
            }
        }
        if practiceState == .anchorPointAligned {
            //once anchor point is aligned
            switch accuracy {
            case .perfect:
                Text(NSLocalizedString("anchorPointPracticeFeedbackPerfectText", comment: "anchor point perfectly aligned text")).padding()
            case .good:
                Text(NSLocalizedString("anchorPointPracticeFeedbackGoodText", comment: "anchor point well aligned text")).padding()
            default:
                Text(NSLocalizedString("anchorPointPracticeFeedbackBadText", comment: "anchor point not well aligned text")).padding()
            }
            
            Button(action: {
                practiceState = .readyForAlignmentInstructions
            }) {
                TutorialButton{
                    Text(NSLocalizedString("anchorPointPracticeRetryAlignButton", comment: "button text to retry aligning the anchor point"))
                }
            }
            
            Button(action: {
                practiceState = .initial
            }) {
                TutorialButton{
                    Text(NSLocalizedString("anchorPointPracticeRetryButton", comment: "button text to retry setting the anchor point"))
                }
            }.padding()
            
            TutorialNavLink(destination: SavedRoutes()) {
                Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
            }.padding()
            
        } else if practiceState == .anchorPointSet {
            //Once anchor point is set
            Button(action: {
                if practiceState == .anchorPointSet {
                    practiceState = .readyForAlignmentInstructions
                }
            }) {
                TutorialButton {
                    Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
                }
            }.disabled(practiceState == .anchorPointAlignmentRequested)
        } else if practiceState == .initial {
            Button(action: {
                if practiceState == .initial {
                    practiceState = .anchorPointCreationRequested
                }
            }) {
                TutorialButton {
                    Text(NSLocalizedString("setAnchorPointButtonText", comment: "The text shown on the button that sets the anchor point during the tutorial"))
                }
            }
        } else if practiceState == .readyForAlignmentInstructions {
            Button(action: {
                practiceState = .anchorPointAlignmentRequested
            }) {
                TutorialButton {
                    Text(NSLocalizedString("alignToAnchorPointButtonText", comment: "The text shown on the button that aligns to the anchor point during the tutorial"))
                }.padding()
            }
        }
    }
}

struct AnchorPointPractice: View {
    @ObservedObject var showPage = ShowTutorialPage.shared
    //TODO: 1 write instructions 2 align to anchor point twice? 4 count down 5 voice announcments?
    var body: some View {
        TutorialScreen {
            VStack {
                AnchorPointPracticeSubComponent()
            }
        }.onDisappear(){
            UserDefaults.standard.setValue(true, forKey: "AnchorPointsTutorialCompleted")
        }
        
        .onAppear() {
            NotificationCenter.default.post(name: Notification.Name("StartARSessionForTutorialModule"), object: nil)
        }
        
        if showPage.confineToSection {
            Button(action: {
                NotificationCenter.default.post(name: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil)
            }) {
                TutorialButton{
                    Text("Exit")
                }
            }
        }
    }
}


struct SavedRoutes: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString("savedRoutesTutorialButtonText", comment: "Title for the saved route part of the tutorial"))
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("savedRouteTutorialInstructionTextParagraph1", comment: "Instructions for using saved routes paragraph 1"))
                Text(NSLocalizedString("savedRouteTutorialInstructionTextParagraph2", comment: "Instructions for using saved routes paragraph 2"))
            }
        }.onDisappear() {
            UserDefaults.standard.setValue(true, forKey: "SavedRoutesTutorialCompleted")
        }
        Spacer()
        TutorialNavLink(destination: SavingARoute()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}


struct SavingARoute: View {
    var body: some View {
        TutorialScreen {
            Text(NSLocalizedString( "savingARouteTutorialTitle", comment: "Title for the saving a part of the tutorial"))
            
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("savingARouteTutorialTextParagraph1", comment: "Instructions for saving routes paragraph 1"))
                Text(NSLocalizedString("savingARouteTutorialTextParagraph2", comment: "Instructions for saving routes paragraph 2"))
                Text(NSLocalizedString("savingARouteTutorialTextParagraph3", comment: "Instructions for saving routes paragraph 3"))
            }
        }
        
        Spacer()
        TutorialNavLink(destination: NamingYourRoute())  {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct NamingYourRoute: View {
    var body: some View {
        TutorialScreen {
            Text(NSLocalizedString( "namingYourRouteTutorialTitle", comment: "Title for the naming your route part of the tutorial"))
            
            Text(NSLocalizedString("namingYourRouteTutorialText", comment: "Instructions for naming your route")).padding()
        }
        
        Spacer()
        TutorialNavLink(destination: FindingSavedRoutes())  {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}

struct FindingSavedRoutes: View {
    var body: some View {
        TutorialScreen  {
            Text(NSLocalizedString("findingSavedRoutesTutorialButtonText", comment: "Title for the finding saved route part of the tutorial"))
            
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("findingSavedRoutesTutorialInstructionTextParagraph1", comment: "Instructions for finding saved routes paragraph 1"))
                Text(NSLocalizedString("findingSavedRoutesTutorialInstructionTextParagraph2", comment: "Instructions for finding saved routes paragraph 2"))
                Text(NSLocalizedString("findingSavedRoutesTutorialInstructionTextParagraph3", comment: "Instructions for finding saved routes paragraph 3"))
            }
        }.onDisappear(){
            UserDefaults.standard.setValue(true, forKey: "FindingSavedRoutesTutorialCompleted")
        }
        Spacer()
        TutorialNavLink(destination: SettingOptions()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
    }
}


struct SettingOptions: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "settingOptionsTutorialButtonText", comment: "Title for the setting options part of the tutorial"))
            
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString( "settingOptionsTutorialInstructionTextParagraph1", comment: "Information about what the setting options are paragraph 1"))
                Text(NSLocalizedString( "settingOptionsTutorialInstructionTextParagraph2", comment: "Information about what the setting options are paragraph 2"))
            }

            
            TutorialNavLink(destination: setUnit()) {
                Text(NSLocalizedString("settingsWalkThroughTitle", comment: "Title for the Settings Walk Through"))
            }.padding()
            
        }.onDisappear(){
            UserDefaults.standard.setValue(true, forKey: "SettingsOptionsTutorialCompleted")
        }
        
        Spacer()
        TutorialNavLink(destination: SiriWalkthrough()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }.padding()
        
    }
}

// TODO: we are hacking this as a global variable as it does not work properly as @State in SiriWalkthrough
var siriShortcutToEdit: INVoiceShortcut?

struct SiriWalkthrough: View {
    @ObservedObject var showPage = ShowTutorialPage.shared
    let activityIdentifiers: [String] = [kNewSingleUseRouteType, kStopRecordingType, kStartNavigationType]
    @ObservedObject var siriShortcutsManager = SiriShortcutsManager.shared
    @State var presentPopup = false
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "siriWalkthroughTutorialTitleText", comment: "Title for the Siri walkthrough part of the tutorial"))
            
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString( "siriWalkthroughTutorialInstructionTextParagraph1", comment: "Information about what the siri shortcuts are paragraph 1"))
                Text(NSLocalizedString( "siriWalkthroughTutorialInstructionTextParagraph2", comment: "Information about what the siri shortcuts are paragraph 2"))
            }
            
            if !SiriShortcutsManager.shared.voiceShortcuts.isEmpty {
                Text(NSLocalizedString("currentSiriShortcuts", comment: "this is header text for the list of current Siri shortcuts the user has created within the Clew app")).padding()

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(activityIdentifiers, id: \.self) { identifier in
                        if let siriShortcut = SiriShortcutsManager.shared.findShortcut(persistentIdentifier: identifier) {
                            HStack {
                                Text(siriShortcut.shortcut.userActivity!.title!)
                                Spacer()
                                Button(action: {
                                    siriShortcutToEdit = siriShortcut
                                    presentPopup.toggle()
                                }) {
                                    Text("\"\(siriShortcut.invocationPhrase)\"")
                                }
                            }
                        }
                    }
                }.sheet(isPresented: $presentPopup) {
                    if let siriShortcut = siriShortcutToEdit {
                        EditShortcutWrapper(voiceShortCut: siriShortcut, showModal: $presentPopup)
                    }
                }
            }
            TutorialNavLink(destination: SetRecordShortcut()) {
                Text(NSLocalizedString("siriWalkthroughButtonText", comment: "Title for the Siri Walk Through"))
            }.padding()
            
        }.onDisappear(){
            UserDefaults.standard.setValue(true, forKey: "SiriWalkthroughTutorialCompleted")
        }
        if !showPage.confineToSection {
            Spacer()
            TutorialNavLink(destination: TutorialEndView()) {
                Text(NSLocalizedString("buttonTexttoSkip", comment: "Text on the button that brings user to the next section of the tutorial"))
            }.padding()
        }
    }
}

struct TutorialEndView: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString("endOfTutorialTitleText", comment: "The title of the tutorial page that shows up when you complete the tutorial"))
            
            Text(NSLocalizedString("endOfTutorialMainText", comment: "the main text at the end of the Clew tutorial"))
        }
        Spacer()
        Button(action: {
            NotificationCenter.default.post(name: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil)
        }) {
            TutorialButton {
                Text(NSLocalizedString("exitTutorial", comment: "Text on the button that exits the tutorial after the user has gone through it the whole thing"))
            }.padding()
        }
    }
}


struct CountdownView: UIViewRepresentable {
    let timerDelegate: SRCountdownTimerDelegate
    
    func makeUIView(context: Context) -> SRCountdownTimer {
        let srCountdownTimer = SRCountdownTimer()
        srCountdownTimer.labelFont = UIFont(name: "HelveticaNeue-Light", size: 20)
        srCountdownTimer.labelTextColor = UIColor.black
        
        srCountdownTimer.timerFinishingText = "End"
        srCountdownTimer.lineWidth = 10
        srCountdownTimer.lineColor = UIColor.black
        srCountdownTimer.backgroundColor = UIColor.white
        /// hide the timer as an accessibility element
        /// and announce through VoiceOver by posting appropriate notifications
        srCountdownTimer.accessibilityElementsHidden = true
        srCountdownTimer.delegate = timerDelegate
        srCountdownTimer.start(beginingValue: 5)
        return srCountdownTimer
    }

    func updateUIView(_ uiView: SRCountdownTimer, context: Context) {

    }
}
