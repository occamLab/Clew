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
            Text("You can ajust all the settings from the settings tap in the main menu")
            
            TutorialNavLink(destination: setUnit()) {Text("Next")}
        }
    }
}

struct setUnit: View{
    @State private var metric = true
    var body: some View {
        TutorialScreen{
            Text("Distance Units")
            
            Button("Imperial", action:{ print("feet"); metric = false})
            
            Button("Metric", action: {print("meters"); metric = true})
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
