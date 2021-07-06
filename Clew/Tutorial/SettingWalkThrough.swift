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
                /*Picker("Select a crumb color", selection: $crumbColor) {
                    ForEach(colors, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Text("Selected color: \(crumbColor)")*/
                Text("Chose Crumb Color")
                
                Button(action:{
                        print("red")
                        //UserDefaults.standard.setValue(0, forKey: "units")
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
                        print("blue")
                        //UserDefaults.standard.setValue(1, forKey: "units")
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
                
                Button(action: {
                        print("Green")
                        //UserDefaults.standard.setValue(1, forKey: "units")
                        crumbColor = "green"}
                        //TODO: render image of blue crumb color
                        )
                {if crumbColor == "green" {
                    TutorialButtonSelected{
                        Text("Green")}
                        
                } else {
                    TutorialButtonNotSelected{
                        Text("Blue")}
                }
                }
            
                Spacer()
                TutorialNavLink(destination: setUpColor())
                    {Text("Next")}
            
            }
        }
    }
}

/*struct setColor: View{
    @State private var crumbColor = "blue"
    @State private var pathColor = "blue"
    var body: some View {
        TutorialScreen{
            Text("Crumb and Path Color")
            
            Text("Set Crumb Color")
            
            Button("Red", action:{ print(crumbColor); crumbColor = "red"})
            
            Button("Green", action: {print("Green"); crumbColor = "green"})
            
            Button("Blue", action: {print("Blue")})
            
            Button("Random", action: {print("random")})
            
            Text("Set Path Color")
            
            Button("Red", action:{ print("Blue")})
            
            Button("Green", action: {print("Green")})
            
            Button("Blue", action: {print("Blue")})
            
            Button("Random", action: {print("random")})
            
            //render an image of the options
            
        }
    }
}*/
