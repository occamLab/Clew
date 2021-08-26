//
//  SettingWalkThrough.swift
//  Clew
//
//  Created by Declan Ketchum on 7/1/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI

struct TutorialButtonToggle<Content: View>: View {
    let isSelected: Bool
    let content: Content
    
    init(isSelected: Bool, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.content = content()
    }
    var body: some View {
        // TODO: figure out how to avoid redundant code
        if isSelected {
            content
                .frame(minWidth: 0, maxWidth: 300)
                .padding()
                .foregroundColor(.black)
                .background(Color.yellow)
                .cornerRadius(10)
                .font(.system(size: 18, weight: .regular))
                .padding(10)
                .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.yellow, lineWidth: 4))
        } else {
            content
                .frame(minWidth: 0, maxWidth: 300)
                .padding()
                .foregroundColor(.white)
                .background(Color.gray)
                .cornerRadius(10)
                .font(.system(size: 18, weight: .regular))
                .padding(10)
                .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.clear, lineWidth: 4))
        }
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
            
            Text(NSLocalizedString("settingsWalkThroughSetUnitsText", comment: "Set units page text")).padding()

            
            Button(action:{
                    UserDefaults.standard.setValue(0, forKey: "units")
            }) {
                TutorialButtonToggle(isSelected: UserDefaults.standard.integer(forKey: "units") == 0) {
                    Text(NSLocalizedString("settingsWalkThroughSetUnitsImperialButton", comment: "Imperial option button text"))
                }
            }
            
            Button(action: {
                UserDefaults.standard.setValue(1, forKey: "units")
            }) {
                TutorialButtonToggle(isSelected: UserDefaults.standard.integer(forKey: "units") == 1) {
                    Text(NSLocalizedString("settingsWalkThroughSetUnitsMetricButton", comment: "Metric option button text"))
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
    let images = [["CrumbRedPathRed", "CrumbRedPathGreen", "CrumbRedPathBlue", "CrumbRedPathRed"], ["CrumbGreenPathRed", "CrumbGreenPathGreen", "CrumbGreenPathBlue", "CrumbRedPathRed"], ["CrumbBluePathRed", "CrumbBluePathGreen", "CrumbBluePathBlue", "CrumbRedPathRed"], ["CrumbRedPathRed", "CrumbRedPathRed", "CrumbRedPathRed", "CrumbRedPathRed"]] //TODO: decide what to do with random colors (note: probably get rid of them)

    var body: some View {
        TutorialScreen{
            VStack {
                Text(NSLocalizedString("settingsWalkThroughCrumbColorTitle", comment: "Crumb color title"))
                
                Text(NSLocalizedString("settingsWalkThroughCrumbColorText", comment: "Crumb color text")).padding()
                
                ForEach(colors.indices) { i in
                    Button(action:{
                            UserDefaults.standard.setValue(i, forKey: "crumbColor")
                    }) {
                        TutorialButtonToggle(isSelected: UserDefaults.standard.integer(forKey: "crumbColor") == i) {
                            Text(colors[i])
                        }
                    }
                }
                
                ForEach(colors.indices) { p in
                    if UserDefaults.standard.integer(forKey: "pathColor") == p {
                        // TODO: this could probably be simplified by just indexing into the color array (might be bad if we update the color list though)
                        ForEach(colors.indices) { c in
                            if UserDefaults.standard.integer(forKey: "crumbColor") == c {
                            
                                Image(images[c][p])
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
                
                Text(NSLocalizedString("settingsWalkThroughPathColorText", comment: "Path color text")).padding()
                
                ForEach(colors.indices) { i in
                    Button(action:{
                            print(colors[i])
                            UserDefaults.standard.setValue(i, forKey: "pathColor")
                    }) {
                        TutorialButtonToggle(isSelected: UserDefaults.standard.integer(forKey: "pathColor") == i) {
                            Text(colors[i])
                        }
                    }
                }
                
                ForEach(colors.indices) { p in
                    if UserDefaults.standard.integer(forKey: "pathColor") == p {
                        ForEach(colors.indices) { c in
                            if UserDefaults.standard.integer(forKey: "crumbColor") == c{
                            
                                Image(images[c][p])
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                        }
                    }
                }
            
            }
        }
        Spacer()
        TutorialNavLink(destination: setUpFeedback()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
    }
}

struct setUpFeedback: View{
    @ObservedObject var settings = SettingsWrapper.shared
    //let feedback = ["Sound", "Voice", "Haptic"]
    var body: some View{
        TutorialScreen{
            Text(NSLocalizedString("settingsWalkThroughFeedbackOptionsTitle", comment: "the title of the feedback options portion of the tutorial"))
                 
            Text(NSLocalizedString("settingsWalkThroughFeedbackOptionsText", comment: "the text of the feedback options portion of the tutorial")).padding()
            
            Button(action: {
                if UserDefaults.standard.bool(forKey: "soundFeedback"){
                    UserDefaults.standard.setValue(false, forKey: "soundFeedback")
                } else{
                    UserDefaults.standard.setValue(true, forKey: "soundFeedback")
                }
            }) {
                TutorialButtonToggle(isSelected: UserDefaults.standard.bool(forKey: "soundFeedback")) {
                    Text(NSLocalizedString("settingsWalkThroughFeedbackOptionsSound", comment: "button text for turning on sound feedback in the tutorial"))
                }
            }
            
            
            Button(action: {
                if UserDefaults.standard.bool(forKey: "voiceFeedback"){
                    UserDefaults.standard.setValue(false, forKey: "voiceFeedback")
                } else{
                    UserDefaults.standard.setValue(true, forKey: "voiceFeedback")
                }
            }) {
                TutorialButtonToggle(isSelected: UserDefaults.standard.bool(forKey: "voiceFeedback")) {
                    Text(NSLocalizedString("settingsWalkThroughFeedbackOptionsSpeech", comment: "button text for turning on voice feedback in the tutorial"))
                }
            }
            
            Button(action: {
                if UserDefaults.standard.bool(forKey: "hapticFeedback") {
                    UserDefaults.standard.setValue(false, forKey: "hapticFeedback")
                } else{
                    UserDefaults.standard.setValue(true, forKey: "hapticFeedback")
                }
            }) {
                TutorialButtonToggle(isSelected: UserDefaults.standard.bool(forKey: "hapticFeedback")) {
                    Text(NSLocalizedString("settingsWalkThroughFeedbackOptionsHaptic", comment: "button text for turning on haptic feedback in the tutorial"))
                }
            }
        }
        Spacer()
        TutorialNavLink(destination: SetPhoneBodyOffset()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
    }
}

struct SetPhoneBodyOffset: View{
    @ObservedObject var settings = SettingsWrapper.shared
    var body: some View {
        TutorialScreen{
            Text(NSLocalizedString("settingsWalkThroughPhoneBodyOffsetTitle", comment: "Determine whether to use the phone body offset correction page title"))
            
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("settingsWalkThroughPhoneBodyOffsetTextParagraph1", comment: "Determine whether to use the phone body offset correction page text paragraph 1"))
                Text(NSLocalizedString("settingsWalkThroughPhoneBodyOffsetTextParagraph2", comment: "Determine whether to use the phone body offset correction page text paragraph 2"))
                Text(NSLocalizedString("settingsWalkThroughPhoneBodyOffsetTextParagraph3", comment: "Determine whether to use the phone body offset correction page text paragraph 3"))
            }

            
            Button(action:{
                UserDefaults.standard.setValue(false, forKey: "adjustOffset")
            }) {
                TutorialButtonToggle(isSelected: !UserDefaults.standard.bool(forKey: "adjustOffset")) {
                    Text(NSLocalizedString("settingsWalkThroughDontAdjustPhoneBodyOffset", comment: "Don't correct for phone body offset settings adjustment"))
                }
            }
            
            Button(action: {
                UserDefaults.standard.setValue(true, forKey: "adjustOffset")
            }) {
                TutorialButtonToggle(isSelected: UserDefaults.standard.bool(forKey: "adjustOffset")) {
                    Text(NSLocalizedString("settingsWalkThroughAdjustPhoneBodyOffset", comment: "Correct for phone body offset settings adjustment"))
                }
            }
        }
        Spacer()
        TutorialNavLink(destination: settingsWalkThroughEndPage()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
    }
}



struct settingsWalkThroughEndPage: View{
    var body: some View{
        TutorialScreen{
            Text(NSLocalizedString("settingsWalkThroughCompleteTitle", comment: "Title of the screen displayed at the end of the settings walkthrough")).padding()
            
            Text(NSLocalizedString("settingsWalkThroughCompleteText", comment: "Text of the screen displayed at the end of the settings walkthrough")).padding()
        }
        Spacer()
        TutorialNavLink(destination: SiriWalkthrough()) {
            Text(NSLocalizedString("buttonTexttoNextScreenTutorial", comment: "Text on the button that brings user to the next page of the tutorial"))
        }
    }
}
