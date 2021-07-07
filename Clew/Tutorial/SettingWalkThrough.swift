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
            Text("You can ajust all the settings from the settings tap in the main menu, or go to the next page to walk through the settings.")
            
            Spacer()
            TutorialNavLink(destination: setUnit()) {Text("Next")}
        }
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
            .font(.system(size: 18, weight: .bold))
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
            .font(.system(size: 18, weight: .bold))
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
            Text("Distance Units")
            
            Button(action:{
                    print("feet")
                    UserDefaults.standard.setValue(0, forKey: "units")
            }) {
                if UserDefaults.standard.integer(forKey: "units") == 1 {
                    TutorialButtonNotSelected{
                        Text("Imperial")
                    }
                } else {
                    TutorialButtonSelected{
                        Text("Imperial")
                    }
                }
            }
            
            Button(action: {
                print("meters")
                UserDefaults.standard.setValue(1, forKey: "units")
            }) {
                if UserDefaults.standard.integer(forKey: "units") == 1 {
                    TutorialButtonSelected{
                        Text("Metric")
                    }
                } else {
                    TutorialButtonNotSelected{
                        Text("Metric")
                    }
                }
        
                Spacer()
                TutorialNavLink(destination: setUpColor()) {
                    Text("Next")
                }
            }
        }
    }
}


struct setUpColor: View {
    @ObservedObject var settings = SettingsWrapper.shared
    let colors = ["Red", "Green", "Blue", "Random"]

    var body: some View {
        TutorialScreen{
            VStack {
                Text("Chose Crumb Color")
                
                ForEach(colors.indices) { i in
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
                
                /*Button(action:{
                        print("red")
                        UserDefaults.standard.setValue(0, forKey: "crumbColor")
                        //crumbColor = "red"
                })
                {
                if UserDefaults.standard.integer(forKey: "crumbColor") == 0 {
                    TutorialButtonSelected{
                        Text("Red")}
            
                } else {
                    TutorialButtonNotSelected{
                        Text("Red")}
                    }
                }
                
                Button(action: {
                    print("Green")
                    UserDefaults.standard.setValue(1, forKey: "crumbColor")
                    //crumbColor = "green"
                
                    //TODO: render image of green crumb color
                })
                {if UserDefaults.standard.integer(forKey: "crumbColor") == 1 {
                    TutorialButtonSelected{
                        Text("Green")}
                        
                } else {
                    TutorialButtonNotSelected{
                        Text("Green")}
                }
                }
                
                Button(action: {
                        print("blue")
                        UserDefaults.standard.setValue(2, forKey: "crumbColor")
                        //crumbColor = "blue"
                    
                }
                        //TODO: render image of blue crumb color
                        )
                {if UserDefaults.standard.integer(forKey: "crumbColor") == 2 {
                    TutorialButtonSelected{
                        Text("Blue")}
                        
                } else {
                    TutorialButtonNotSelected{
                        Text("Blue")}
                }
                }*/
                
                Spacer()
                TutorialNavLink(destination: setUpPathColor())
                    {Text("Next")}
            
            }
        }
    }
}

struct setUpPathColor: View {
    @ObservedObject var settings = SettingsWrapper.shared
    let colors = ["Red", "Green", "Blue", "Random"]

    var body: some View {
        TutorialScreen{
            VStack {
                Text("Chose Path Color")
                
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
                
                /*Button(action:{
                        print("red")
                        UserDefaults.standard.setValue(0, forKey: "pathColor")
                        //crumbColor = "red"
                })
                {
                if UserDefaults.standard.integer(forKey: "pathColor") == 0 {
                    TutorialButtonSelected{
                        Text("Red")}
            
                } else {
                    TutorialButtonNotSelected{
                        Text("Red")}
                    }
                }
                
                Button(action: {
                    print("Green")
                    UserDefaults.standard.setValue(1, forKey: "pathColor")
                    //crumbColor = "green"
                
                    //TODO: render image of green crumb color
                })
                {if UserDefaults.standard.integer(forKey: "pathColor") == 1 {
                    TutorialButtonSelected{
                        Text("Green")}
                        
                } else {
                    TutorialButtonNotSelected{
                        Text("Green")}
                }
                }
                
                Button(action: {
                        print("blue")
                        UserDefaults.standard.setValue(2, forKey: "pathColor")
                        //crumbColor = "blue"
                    
                }
                        //TODO: render image of blue crumb color
                        )
                {if UserDefaults.standard.integer(forKey: "pathColor") == 2 {
                    TutorialButtonSelected{
                        Text("Blue")}
                        
                } else {
                    TutorialButtonNotSelected{
                        Text("Blue")}
                }
                }*/
                
                Spacer()
                TutorialNavLink(destination: setUpPathColor())
                    {Text("Next")}
            
            }
        }
    }
}
