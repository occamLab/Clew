//
//  SettingWalkThrough.swift
//  Clew
//
//  Created by Declan Ketchum on 7/1/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI


struct SettingWalkThrough: View {
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString("settingsWalkThroughIntro", comment: "Intro text to the settings walk through"))
        
        }
        Spacer()
        TutorialNavLink(destination: setUnit()) {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}


struct TutorialButtonSelected<Content: View>: View {
    //Button format when an option is selected, highlights and outlines the option selected
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
            .padding(10)
            //.border(Color.blue, width: 5) //square boarder
            .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.yellow, lineWidth: 4))
    }
}

struct TutorialButtonNotSelected<Content: View>: View {
    //Button format when that option is not selected, leaves button grey without outline
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            //.textboarder(color: .black, lineWidth: 3)
            .frame(minWidth: 0, maxWidth: 300)
            .padding()
            .foregroundColor(.white)
            .background(Color.gray)
            .cornerRadius(10)
            .font(.system(size: 18, weight: .regular))
            .padding(10)
            //.border(Color.blue, width: 5)
            .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.clear, lineWidth: 4))
    }
}

class SettingsWrapper: ObservableObject {
    public static var shared = SettingsWrapper()
    
    @objc func changeOccurred() {
        objectWillChange.send()
    }
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changeOccurred),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }
}

struct setUnit: View{
    @ObservedObject var settings = SettingsWrapper.shared
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString("settingsWalkThroughSetUnitsTitle", comment: "Set units page title"))
            
            Button(action:{
                    UserDefaults.standard.setValue(0, forKey: "units")
            }) {
                if UserDefaults.standard.integer(forKey: "units") == 1 {
                    TutorialButtonNotSelected{
                        Text(NSLocalizedString("settingsWalkThroughSetUnitsImperialButton", comment: "Imperial option button text"))
                    }
                } else {
                    TutorialButtonSelected{
                        Text(NSLocalizedString("settingsWalkThroughSetUnitsImperialButton", comment: "Imperial option button text"))
                    }
                }
            }
            
            Button(action: {
                UserDefaults.standard.setValue(1, forKey: "units")
            }) {
                if UserDefaults.standard.integer(forKey: "units") == 1 {
                    TutorialButtonSelected{
                        Text(NSLocalizedString("settingsWalkThroughSetUnitsMetricButton", comment: "Metric option button text"))
                    }
                } else {
                    TutorialButtonNotSelected{
                        Text(NSLocalizedString("settingsWalkThroughSetUnitsMetricButton", comment: "Metric option button text"))
                    }
                }
                }
        }
        Spacer()
        TutorialNavLink(destination: setUpCrumbColor()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
    }
}


struct setUpCrumbColor: View {
    @ObservedObject var settings = SettingsWrapper.shared
    let colors = ["Red", "Green", "Blue", "Random"]
    let images = [["CrumbRedPathRed", "CrumbRedPathGreen", "CrumbRedPathBlue", "CrumbRedPathRed"], ["CrumbGreenPathRed", "CrumbGreenPathGreen", "CrumbGreenPathBlue", "CrumbRedPathRed"], ["CrumbBluePathRed", "CrumbBluePathGreen", "CrumbBluePathBlue", "CrumbRedPathRed"], ["CrumbRedPathRed", "CrumbRedPathRed", "CrumbRedPathRed", "CrumbRedPathRed"]] //TODO: decide what to do with random colors

    var body: some View {
        TutorialScreen{
            VStack {
                Text(NSLocalizedString("settingsWalkThroughCrumbColorTitle", comment: "Crumb color title"))
                
                ForEach(colors.indices) { i in
                    Button(action:{
                            print(colors[i])
                            UserDefaults.standard.setValue(i, forKey: "crumbColor")
                            //crumbColor = "red"
                    })
                    {
                    if UserDefaults.standard.integer(forKey: "crumbColor") == i {
                        TutorialButtonSelected{
                            Text(colors[i])}
                
                    } else {
                        TutorialButtonNotSelected{
                            Text(colors[i])}
                        }
                    }
                }
                
                ForEach(colors.indices) { p in
                    if UserDefaults.standard.integer(forKey: "pathColor") == p {
                        ForEach(colors.indices) { c in
                            if UserDefaults.standard.integer(forKey: "crumbColor") == c{
                            
                                Image(images[c][p])
                                //("CrumbRedPathRed")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                        }
                    }
                }
                
            
            }
        }
        Spacer()
        TutorialNavLink(destination: setUpPathColor())
            {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}

struct setUpPathColor: View {
    @ObservedObject var settings = SettingsWrapper.shared
    let colors = ["Red", "Green", "Blue", "Random"]
    let images = [["CrumbRedPathRed", "CrumbRedPathGreen", "CrumbRedPathBlue", "CrumbRedPathRed"], ["CrumbGreenPathRed", "CrumbGreenPathGreen", "CrumbGreenPathBlue", "CrumbRedPathRed"], ["CrumbBluePathRed", "CrumbBluePathGreen", "CrumbBluePathBlue", "CrumbRedPathRed"], ["CrumbRedPathRed", "CrumbRedPathRed", "CrumbRedPathRed", "CrumbRedPathRed"]]

    var body: some View {
        TutorialScreen{
            VStack {
                Text(NSLocalizedString("settingsWalkThroughPathColorTitle", comment: "Path color title"))
                
                ForEach(colors.indices) { i in
                 // trying to make a button for each button
                    Button(action:{
                            print(colors[i])
                            UserDefaults.standard.setValue(i, forKey: "pathColor")
                            //crumbColor = "red"
                    })
                    {
                    if UserDefaults.standard.integer(forKey: "pathColor") == i {
                        TutorialButtonSelected{
                            Text(colors[i])}
                
                    } else {
                        TutorialButtonNotSelected{
                            Text(colors[i])}
                        }
                    }
                }
                
                ForEach(colors.indices) { p in
                    if UserDefaults.standard.integer(forKey: "pathColor") == p {
                        ForEach(colors.indices) { c in
                            if UserDefaults.standard.integer(forKey: "crumbColor") == c{
                            
                                Image(images[c][p])
                                //("CrumbRedPathRed")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                        }
                    }
                }
            
            }
        }
        Spacer()
        TutorialNavLink(destination: setUpFeedback())
            {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}

struct setUpFeedback: View{
    @ObservedObject var settings = SettingsWrapper.shared
    //let feedback = ["Sound", "Voice", "Haptic"]
    var body: some View{
        TutorialScreen{
            Text("Feedback Options")
            
            Text("We recomend that you leave all of the feedback options on until you have played around with Clew for a while. Then you can return to settings and decide if you want to turn off any of the feedback features.")
            
            Button(action: {
                if UserDefaults.standard.bool(forKey: "soundFeedback"){
                    UserDefaults.standard.setValue(false, forKey: "soundFeedback")
                } else{
                    UserDefaults.standard.setValue(true, forKey: "soundFeedback")
                }
            })
            {if UserDefaults.standard.bool(forKey: "soundFeedback"){
                TutorialButtonSelected{
                    Text("Sound")}
        
            } else {
                TutorialButtonNotSelected{
                    Text("Sound")}
                }
            }
            
            
            Button(action: {
                if UserDefaults.standard.bool(forKey: "voiceFeedback"){
                    UserDefaults.standard.setValue(false, forKey: "voiceFeedback")
                } else{
                    UserDefaults.standard.setValue(true, forKey: "voiceFeedback")
                }
            })
            {if UserDefaults.standard.bool(forKey: "voiceFeedback"){
                TutorialButtonSelected{
                    Text("Voice")}
        
            } else {
                TutorialButtonNotSelected{
                    Text("Voice")}
                }
            }
            
            Button(action: {
                if UserDefaults.standard.bool(forKey: "hapticFeedback"){
                    UserDefaults.standard.setValue(false, forKey: "hapticFeedback")
                } else{
                    UserDefaults.standard.setValue(true, forKey: "hapticFeedback")
                }
            })
            {if UserDefaults.standard.bool(forKey: "hapticFeedback"){
                TutorialButtonSelected{
                    Text("Haptic")}
        
            } else {
                TutorialButtonNotSelected{
                    Text("Haptic")}
                }
            }
            
        }
        Spacer()
        TutorialNavLink(destination: settingsWalkThroughEndPage())
            {Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))}
    }
}


struct settingsWalkThroughEndPage: View{
    var body: some View{
        TutorialScreen{
            Text("End of Settings Walk Through")
            
            Text("Clew is all set up according to your preferences. You can change any settings at anytime through the settings page. You can also access this settings walk through again by entering the tutorial and then going to 'Settings Options'.")
        }
        Spacer()
        Button(action: {
            NotificationCenter.default.post(name: Notification.Name("TutorialPopoverReadyToDismiss"), object: nil)
        }) {TutorialButton{Text("Exit Walk Through")}}
    }
}
