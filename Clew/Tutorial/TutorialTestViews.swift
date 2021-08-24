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

//TODO: make sure we can't access old tutorial modes when clicking next
//TODO: 1 add content to all pages 4 add localized strings to everything
//TODO: stop AR session when needed based on the tutorial state
//TODO: make sure contextual help makes sense in all cases (e.g., the recording use case doesn't really work)
//TODO: thin out the on-screen instructions for anchor points
//TODO: polish the anchor point practice page (needs to maybe have less text appearing randomly and also provide more announcements to help guide the user)
//TODO: move reset tutorial practice onto main page
//TODO: make sounds play even with silent switch on
//TODO: better instructions for the how to hold your phone
//TODO: Figure out why do anchor points show up as their own section and under saved routes
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
            /*leading:
             NavigationLink("Tutorial", destination: TutorialTestView())
             .padding(),*/ //TODO: make a return to tutorial menu button on all the pages
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


struct TutorialNavLinkWithRedirection<Destination: View, Content: View>: View {
    //creates a button format for all the CLEW tutorial navigation links to use. only works for navigation links
    let content: Content
    let destination: Destination
    let activationTag: String
    let selection: Binding<String?>
    
    init(destination: Destination, tag: String, selection: Binding<String?>, @ViewBuilder content: () -> Content) {
        self.destination = destination
        self.selection = selection
        self.activationTag = tag
        self.content = content()
    }
    
    var body: some View {
        NavigationLink(destination: self.destination, tag: activationTag, selection: selection) {
            content
                //.textboarder(color: .black, lineWidth: 3)
                .frame(minWidth: 0, maxWidth: 300)
                .padding()
                .foregroundColor(.black)
                .background(Color.yellow)
                .cornerRadius(10)
                .font(.system(size: 18, weight: .regular))
                .accessibility(hint: UserDefaults.standard.bool(forKey: activationTag + "TutorialCompleted") ? Text("Module Completed") : Text("Module Not Completed") )
            if UserDefaults.standard.bool(forKey: activationTag + "TutorialCompleted") {
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
            //.textboarder(color: .black, lineWidth: 3)
            .frame(minWidth: 0, maxWidth: 300)
            .padding()
            .foregroundColor(.black)
            .background(Color.yellow)
            .cornerRadius(10)
            .font(.system(size: 18, weight: .regular))
    }
}

class ShowTutorialPage: ObservableObject {
    @Published var selectedView: String? = ""
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
                
                HStack{
                    TutorialNavLinkWithRedirection(destination: CLEWintro(), tag: "CLEWintro", selection: $showPage.selectedView) {
                        Text(NSLocalizedString("ClewIntroTutorialTitle", comment: "Intro to Clew Tutorial Title"))
                    }
                }
                
                HStack{
                    TutorialNavLinkWithRedirection(destination: OrientPhone(), tag: "OrientPhone", selection: $showPage.selectedView) {
                        Text(NSLocalizedString("orientPhoneTutorialButtonText", comment: "Text for the tutorial screem for phone position"))
                    }
                }
                
                HStack{
                    TutorialNavLinkWithRedirection(destination: FindPath(), tag: "FindPath", selection: $showPage.selectedView) {
                        Text(NSLocalizedString( "findPathTutorialButtonText", comment: "Title for the finding and following path part of the tutorial"))
                    }
                }
                
                HStack{
                    TutorialNavLinkWithRedirection(destination: SingleUse(), tag: "SingleUse", selection: $showPage.selectedView) {
                        Text(NSLocalizedString( "singleUseRouteTutorialButtonText", comment: "Title for the single use route part of the tutorial"))
                    }
                }
                
                HStack{
                    TutorialNavLinkWithRedirection(destination: AnchorPoints(), tag: "AnchorPoints", selection: $showPage.selectedView) {
                        Text("Anchor Points")
                    }
                }
                
                HStack{
                    TutorialNavLinkWithRedirection(destination: SavedRoutes(), tag: "SavedRoutes", selection: $showPage.selectedView) {Text(NSLocalizedString( "savedRoutesTutorialButtonText", comment: "Title for the saved route part of the tutorial"))
                    }
                }
                
                HStack{
                    TutorialNavLinkWithRedirection(destination: FindingSavedRoutes(), tag: "FindingSavedRoutes", selection: $showPage.selectedView) {Text(NSLocalizedString( "findingSavedRoutesTutorialButtonText", comment: "Title for the finding saved route part of the tutorial"))
                    }
                }
                
                HStack{
                    TutorialNavLinkWithRedirection(destination: SettingOptions(), tag: "SettingsOptions", selection: $showPage.selectedView) {
                        Text(NSLocalizedString( "settingOptionsTutorialButtonText", comment: "Title for the setting options part of the tutorial"))
                    }
                }
                
                HStack{
                    TutorialNavLinkWithRedirection(destination: SiriWalkthrough(), tag: "SiriWalkthrough", selection: $showPage.selectedView) {
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
            
            Button(action:{
                UserDefaults.standard.setValue(false, forKey: "CLEWintroTutorialCompleted")
                UserDefaults.standard.setValue(false, forKey: "OrientPhoneTutorialCompleted")
                UserDefaults.standard.setValue(false, forKey: "FindPathTutorialCompleted")
                UserDefaults.standard.setValue(false, forKey: "FindPathPractice1Completed")
                UserDefaults.standard.setValue(false, forKey: "FindPathPractice2Completed")
                UserDefaults.standard.setValue(false, forKey: "AnchorPointsTutorialCompleted")
                UserDefaults.standard.setValue(false, forKey: "SingleUseTutorialCompleted")
                UserDefaults.standard.setValue(false, forKey: "SavedRoutesTutorialCompleted")
                UserDefaults.standard.setValue(false, forKey: "FindingSavedRoutesTutorialCompleted")
                UserDefaults.standard.setValue(false, forKey: "SettingsOptionsTutorialCompleted")
                UserDefaults.standard.setValue(false, forKey: "SiriWalkthroughTutorialCompleted")
            }) {
                Text("Reset Tutorial Progress")
            }
            
            
        }
        Spacer()
        TutorialNavLink(destination: UsingClew()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
    }
}

struct UsingClew: View {
    var body: some View {
        TutorialScreen {
            
            Text(NSLocalizedString("introUsingClewTitle", comment: "Title for intro to Using Clew Page"))
            
            Text(NSLocalizedString("introUsingClewText", comment: "Text for intro to Using Clew Page"))
            
            //Add link to examples?
        }
        Spacer()
        TutorialNavLink(destination: ClewsRole()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
    }
}

struct ClewsRole: View {
    var body: some View {
        TutorialScreen {
            
            Text(NSLocalizedString("introClewsRoleTutorialTitle", comment: "Title for intro to Clew's role Page"))
            
            Text(NSLocalizedString("introClewsRoleTutorialText", comment: "Text for intro to Clew's role Page"))
        }
        Spacer()
        TutorialNavLink(destination: UsingClewTutorial()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
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
        }
    }
}

struct ClewExamples: View {
    //Not in Tutorial at the moment
    var body: some View {
        TutorialScreen {
            Text("What Can I Use Clew For?")
            
            Text("Clew is a versitile tool for traveling from point A to B. Below are some examples of what situations current users find Clew helpful.")
            
            Text("You could use Clew when visting a hotel, by saving a Clew route from the front door to the elevator and then save a route from the elevator to your room. Then you could use Clew to navigate those routes whenever you like.")
            
            Text("You could use Clew to navigate between your table and the restroom in a resturant.")
            
        }
    }
}


struct OrientPhone: View {
    var body: some View {
        TutorialScreen {
            Text(NSLocalizedString("orientPhoneTutorialButtonText", comment: "Title for the setting options part of the tutorial"))
            
            Text(NSLocalizedString("orientPhoneTutorialInstructionText", comment: "Text that explains how to orient the phone for the best experience using Clew"))
            
            TutorialNavLink(destination: OrientPhoneTips()) {
                Text(NSLocalizedString("tipTutorialTitle", comment: "text on button to tips page"))
            }
            
            TutorialNavLink(destination: PracticeOrientPhone()) {
                Text(NSLocalizedString("orientPhoneTutorialPracticeTitle", comment: "Title for holding phone practice"))
            }
            
            
        }
        Spacer()
        TutorialNavLink(destination: FindPath()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
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
        TutorialNavLink(destination: PracticeOrientPhone()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
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
        
        //ScrollView{
        Text(NSLocalizedString("orientPhoneTutorialPracticeInstructions", comment: "Instructions for practicing holding phone activity"))
        //}
        
        Button(action:{
            started.toggle()
            NotificationCenter.default.post(name: Notification.Name("StartARSession"), object: nil)
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
        Spacer().onReceive(self.arData.objectWillChange) { newARData in
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
            TutorialNavLink(destination: FindPath()) {
                Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
            } //change skip button to next button when score equals three because the user has completed the practice
        } else {
            Spacer()
            TutorialNavLink(destination: FindPath()) {
                Text(NSLocalizedString("buttonTexttoSkip", comment: "Text on skip button"))
            }
        }
    }
}


struct FindPath: View {
    // TODO: when called contextually, we don't want to launch into the test routes
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "findPathTutorialButtonText", comment: "Title for the finding and following path part of the tutorial"))
            
            Text(NSLocalizedString("findPathTutorialInstructionText", comment: "Text that explains what it sounds and feels like to be on the path and following the path"))
            //.fixedSize(horizontal: false, vertical: true)
            
            //TutorialNavLink(destination: FindPathPractice1())  {Text("Practice")}
            //TutorialNavLink(destination: TutorialEndView())  {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
            
        }
        Spacer()
        TutorialNavLink(destination: FindPathPractice1())  {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
    }
}

struct FindPathPractice1: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString("findPathPractice1Title", comment: "Text for the title of the first following route practice."))
            
            Text(NSLocalizedString("findPathPractice1InstructionText", comment: "Text for the instructions of the first following route practice."))
            
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
        }
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
        }
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
                
                Spacer() //TODO: spacer does not push next button to the bottom :(
                if UserDefaults.standard.bool(forKey: "FindPathPractice1Completed") {
                    TutorialNavLink(destination: SingleUse()) {
                        Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
                    }
                } else {
                    TutorialNavLink(destination: FindPathPractice2()) {
                        Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
                    }
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
            
            //ScrollView{
            Text(NSLocalizedString( "singleUseRouteTutorialInstructionText", comment: "Instructions for using the single use route"))
            //.fixedSize(horizontal: false, vertical: true)
            //}
            
        }.onDisappear(){
            UserDefaults.standard.setValue(true, forKey: "SingleUseTutorialCompleted")
        }
        
        Spacer()
        TutorialNavLink(destination: UsingSingleUse()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
    }
}

struct UsingSingleUse: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString("usingSingleUseRouteTutorialTitle", comment: "Title for using single use route section"))
            
            Text(NSLocalizedString("usingSingleUseRouteTutorialText", comment: "Instruction for how to use single use routes"))
        }
        
        Spacer()
        TutorialNavLink(destination: AnchorPoints()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
    }
}


struct AnchorPoints: View {
    @ObservedObject var showPage = ShowTutorialPage.shared
    var body: some View {
        TutorialScreen  {
            Text(NSLocalizedString( "anchorPointsTutorialTitle", comment: "Title for the anchor point part of the tutorial"))
            
            //ScrollView{
            Text(NSLocalizedString("anchorPointsTutorialText", comment: "Instructions for setting anchor points"))
            
            TutorialNavLink(destination: AnchorPointTips())  {
                Text(NSLocalizedString("tipTutorialTitle", comment: "Tip page button text"))
            }
            
            TutorialNavLink(destination: AnchorPointPractice())  {
                Text(NSLocalizedString("practiceTutorialTitle", comment: "Text for practice button"))
            }
            
        }
        
        if !showPage.confineToSection {
            Spacer()
            TutorialNavLink(destination: SavedRoutes())  {
                Text(NSLocalizedString("buttonTexttoSkip", comment: "Text on the button that brings user to the next page of the tutorial"))
            }
        }
    }
}


struct AnchorPointTips: View {
    var body: some View {
        TutorialScreen {
            Text(NSLocalizedString("anchorPointsTutorialTipsTitle", comment: "Title of anchor point tips page"))
            
            Text(NSLocalizedString("anchorPointsTutorialTipsText", comment: "Text of anchor point tips page"))
        }
        
        Spacer()
        TutorialNavLink(destination: AnchorPointPractice())  {
            Text(NSLocalizedString("practiceTutorialTitle", comment: "Text for practice button"))
        }
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

    static let xPerfectThreshold = Float(0.1)
    static let yPerfectThreshold = Float(0.1)
    static let zPerfectThreshold = Float(0.1)
    static let yawPerfectThreshold = Float(0.1)
    static let xGoodThreshold = Float(0.5)
    static let yGoodThreshold = Float(0.5)
    static let zGoodThreshold = Float(0.5)
    static let yawGoodThreshold = Float(0.5)
    
    var body: some View {
        Image("Align")
            .resizable()
            .frame(width: 100, height: 100)
        
        if practiceState == .anchorPointSet || practiceState == .anchorPointAlignmentRequested {
            Text(NSLocalizedString("anchorPointPracticeAlignTitle", comment: "Align to anchor point page title")).padding()
            
            Text(NSLocalizedString("anchorPointPracticeAlignText", comment: "Align to anchor point page instructions")).padding()
        } else if practiceState == .initial || practiceState == .anchorPointCreationRequested {
            //when starting anchor point practice
            Text(NSLocalizedString("anchorPointPracticeSetTutorialTitle", comment: "Set an anchor point practice page title")).padding()
            
            Text(NSLocalizedString("anchorPointPracticeSetTutorialText", comment: "Set an anchor point practice page instructions")).padding()
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
                Text(NSLocalizedString("anchorPointPracticeFeedbackPerfectTitle", comment: "anchor point perfectly aligned heading")).padding()
                Text(NSLocalizedString("anchorPointPracticeFeedbackPerfectText", comment: "anchor point perfectly aligned text")).padding()
            case .good:
                Text(NSLocalizedString("anchorPointPracticeFeedbackGoodTitle", comment: "anchor point well aligned header")).padding()
                Text(NSLocalizedString("anchorPointPracticeFeedbackGoodText", comment: "anchor point well aligned text")).padding()
            default:
                Text(NSLocalizedString("anchorPointPracticeFeedbackBadTitle", comment: "anchor point not well aligned header")).padding()
                Text(NSLocalizedString("anchorPointPracticeFeedbackBadText", comment: "anchor point not well aligned text")).padding()
            }
            
            Button(action: {
                practiceState = .anchorPointSet
            }) {
                TutorialButton{
                    Text(NSLocalizedString("anchorPointPracticeRetryAlignButton", comment: "button text to retry aligning the anchor point"))
                }
            }.padding()
            
            Button(action: {
                practiceState = .initial
            }) {
                TutorialButton{
                    Text(NSLocalizedString("anchorPointPracticeRetryButton", comment: "button text to retry setting the anchor point"))
                }
            }.padding()
            
            TutorialNavLink(destination: AnchorPointTips())  {
                Text(NSLocalizedString("tipTutorialTitle", comment: "Button to tips page"))
            }.padding()
        } else if practiceState == .anchorPointSet {
            //Once anchor point is set
            Button(action: {
                if practiceState == .anchorPointSet {
                    practiceState = .anchorPointAlignmentRequested
                }
            }) {
                TutorialButton {
                    Text(NSLocalizedString("alignToAnchorPointButtonText", comment: "The text shown on the button that aligns to the anchor point during the tutorial"))
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
            NotificationCenter.default.post(name: Notification.Name("StartARSession"), object: nil)
        }
        
        if !showPage.confineToSection {
            Spacer()
            TutorialNavLink(destination: SavedRoutes())  {
                Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
            }
        } else {
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
            
            Text(NSLocalizedString("savedRouteTutorialInstructionText", comment: "Instructions for using saved routes"))
            //.fixedSize(horizontal: false, vertical: true)
            
        }.onDisappear() {
            UserDefaults.standard.setValue(true, forKey: "SavedRoutesTutorialCompleted")
        }
        Spacer()
        TutorialNavLink(destination: RecordSavedRoutes()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
    }
}


struct RecordSavedRoutes: View {
    //@ObservedObject var entered
    var body: some View {
        TutorialScreen {
            Text(NSLocalizedString( "recordSavedRoutesTutorialButtonText", comment: "Title for the recording saved routes part of the tutorial"))
            
            //ScrollView{
            Text(NSLocalizedString("recordSavedRoutesTutorialInstructionText", comment: "Instructions for recording saved routes"))
            //.fixedSize(horizontal: false, vertical: true)
            
            TutorialNavLink(destination: AnchorPoints()) {
                Text(NSLocalizedString("anchorPointsTutorialTitle", comment: "Title for the anchor point part of the tutorial"))
            }
            
            TutorialNavLink(destination: VoiceNotes()) {
                Text(NSLocalizedString( "voiceNotesTutorialButtonText", comment: "Title for the voice notes part of the tutorial"))
            }
            
        }
        
        Spacer()
        TutorialNavLink(destination: FindingSavedRoutes())  {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
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
        TutorialNavLink(destination: FindingSavedRoutes())  {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
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
        TutorialNavLink(destination: SettingOptions()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
    }
}


struct SettingOptions: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "settingOptionsTutorialButtonText", comment: "Title for the setting options part of the tutorial"))
            
            //ScrollView{
            Text(NSLocalizedString( "settingOptionsTutorialInstructionText", comment: "Information about what the setting options are"))
            //.fixedSize(horizontal: false, vertical: true)
            
            TutorialNavLink(destination: SettingWalkThrough()) {
                Text(NSLocalizedString("settingsWalkThroughTitle", comment: "Title for the Settings Walk Through"))
            }
            
        }.onDisappear(){
            UserDefaults.standard.setValue(true, forKey: "SettingsOptionsTutorialCompleted")
        }
        
        Spacer()
        TutorialNavLink(destination: SiriWalkthrough()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
        
    }
}

struct SiriWalkthrough: View {
    @ObservedObject var showPage = ShowTutorialPage.shared
    let activityIdentifiers: [String] = [kNewSingleUseRouteType, kStopRecordingType, kStartNavigationType]
    let minRowHeight = 75
    @ObservedObject var siriShortcutsManager = SiriShortcutsManager.shared
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString( "siriWalkthroughTutorialTitleText", comment: "Title for the Siri walkthrough part of the tutorial"))
            
            //ScrollView{
            Text(NSLocalizedString( "siriWalkthroughTutorialInstructionText", comment: "Information about what the setting options are"))
            //.fixedSize(horizontal: false, vertical: true)
            
            if !SiriShortcutsManager.shared.voiceShortcuts.isEmpty {
                Text("Current Siri Shortcuts for Clew").padding()

                List {
                    ForEach(activityIdentifiers, id: \.self) { identifier in
                        if let siriShortcut = SiriShortcutsManager.shared.findShortcut(persistentIdentifier: identifier) {
                            HStack {
                                Text(siriShortcut.shortcut.userActivity!.title!).padding()
                                Text("\"\(siriShortcut.invocationPhrase)\"").padding()
                            }
                        }
                    }
                }.frame(minHeight: CGFloat(minRowHeight * SiriShortcutsManager.shared.voiceShortcuts.count)).border(Color.black)
            }
            TutorialNavLink(destination: SetRecordShortcut()) {
                Text(NSLocalizedString("siriWalkthroughButtonText", comment: "Title for the Siri Walk Through"))
            }
            
        }.onDisappear(){
            UserDefaults.standard.setValue(true, forKey: "SiriWalkthroughTutorialCompleted")
        }
        if !showPage.confineToSection {
            Spacer()
            TutorialNavLink(destination: TutorialEndView()) {
                Text(NSLocalizedString("buttonTexttoSkip", comment: "Text on the button that brings user to the next section of the tutorial"))
            }
        }
    }
}

struct TutorialEndView: View {
    var body: some View {
        TutorialScreen{
            Text("End of Tutorial")
            
            Text("Nice Job! You've completed the Clew tutorial. You can come back to this information at anytime through the menu options or by pressing the help button on the Clew main screens.")
        }
        Spacer()
        Button(action: {
            NotificationCenter.default.post(name: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil)
        }) {
            TutorialButton{
                Text("Exit Tutorial")
            }
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
