//
//  SwiftUIView.swift
//  Clew-More
//
//  Created by occamlab on 7/13/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI

struct StartMenuView: View {
    let vc: ViewController
    @State private var buttonPressed = "" //TODO: change so it know what your settings are when you enter the walkthrough
    
    var body: some View {
        VStack {
            OptionsHeaderView(vc: self.vc)
            // Button for saving a route
            Button(action: {
                buttonPressed = "Save Route"
                NotificationCenter.default.post(name: NSNotification.Name("shouldRouteRecording"), object: nil)
                
            }) {
                ZStack {
                    Image("WhiteButtonBackground")
                        .resizable()
                        .frame(maxWidth: UIScreen.main.bounds.size.width/1.1, maxHeight: UIScreen.main.bounds.size.height/5)
                    Text("Save Route")
                        .font(.title2)
                        .foregroundColor(.black)
                        .fontWeight(.bold)
                }
                
            }
            .padding()
            
            // Button for recording a route from a code
            Button(action: {
                buttonPressed = "Navigate"
                NotificationCenter.default.post(name: NSNotification.Name("shouldOpenRouteMenu"), object: nil)

            }) {
                ZStack {
                    Image("WhiteButtonBackground")
                        .resizable()
                        .frame(maxWidth: UIScreen.main.bounds.size.width/1.1, maxHeight: UIScreen.main.bounds.size.height/5)
                    Text("Navigate Route from Code")
                        .font(.title2)
                        .foregroundColor(.black)
                        .fontWeight(.bold)

                }
                
            }
            
            .padding()
            
            Button(action: {
                buttonPressed = "View Routes"
                NotificationCenter.default.post(name: NSNotification.Name("shouldShowRoutes"), object: nil)

            }) {
                ZStack {
                    Image("WhiteButtonBackground")
                        .resizable()
                        .frame(maxWidth: UIScreen.main.bounds.size.width/1.1, maxHeight: UIScreen.main.bounds.size.height/5)
                    Text("View Routes Stored Locally")
                        .font(.title2)
                        .foregroundColor(.black)
                        .fontWeight(.bold)
                }
                
            }
        }
        .background(Color.white)
    }
           
}



