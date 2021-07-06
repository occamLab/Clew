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

struct setUnit: View{
    @State private var metric = true //TODO: change so it know what your settings are when you enter the walkthrough
    var body: some View {
        TutorialScreen{
            Text("Distance Units")
            
            Button(action:{
                    print("feet")
                    UserDefaults.standard.setValue(0, forKey: "units")
                    metric = false})
            {if metric {
                TutorialButtonNotSelected{
                    Text("Imperial")}
        
            } else {
                TutorialButtonSelected{
                    Text("Imperial")}
                }
            }
            
            Button(action: {
                    print("meters")
                    UserDefaults.standard.setValue(1, forKey: "units")
                    metric = true})
            {if metric {
                TutorialButtonSelected{
                    Text("Metric")}
                    
            } else {
                TutorialButtonNotSelected{
                    Text("Metric")}
            }
            }
        
            Spacer()
            TutorialNavLink(destination: setUpColor())
                {Text("Next")}
        }
    }
}


struct setUpColor: View {
    @State private var crumbColor = "red"
    //TODO: set crumbColor to the users current crumb color
    //let colors = ["Red", "Green", "Blue", "Random"]

    var body: some View {
        TutorialScreen{
            VStack {
                Text("Chose Crumb Color")
                
                Button(action:{
                        print("red")
                        UserDefaults.standard.setValue(0, forKey: "crumbColor")
                        crumbColor = "red"})
                {if crumbColor == "red" {
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
                    crumbColor = "green"}
                    //TODO: render image of green crumb color
                    )
                {if crumbColor == "green" {
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
                        crumbColor = "blue"}
                        //TODO: render image of blue crumb color
                        )
                {if crumbColor == "blue" {
                    TutorialButtonSelected{
                        Text("Blue")}
                        
                } else {
                    TutorialButtonNotSelected{
                        Text("Blue")}
                }
                }
                
                
            
                Spacer()
                TutorialNavLink(destination: setUpPathColor())
                    {Text("Next")}
            
            }
        }
    }
}

struct setUpPathColor: View {
    @State private var pathColor = "red"
    //TODO: set crumbColor to the users current crumb color
    //let colors = ["Red", "Green", "Blue", "Random"]

    var body: some View {
        TutorialScreen{
            VStack {
                Text("Chose Path Color")
                
                Button(action:{
                        print("red")
                        UserDefaults.standard.setValue(0, forKey: "pathColor")
                        pathColor = "red"})
                {if pathColor == "red" {
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
                    pathColor = "green"}
                    //TODO: render image of green crumb color
                    )
                {if pathColor == "green" {
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
                        pathColor = "blue"}
                        //TODO: render image of blue crumb color
                        )
                {if pathColor == "blue" {
                    TutorialButtonSelected{
                        Text("Blue")}
                        
                } else {
                    TutorialButtonNotSelected{
                        Text("Blue")}
                }
                }
                
                
            
                Spacer()
                TutorialNavLink(destination: setUpPathColor())
                    {Text("Next")}
            
            }
        }
    }
}
