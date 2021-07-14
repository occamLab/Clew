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
        // Button for saving a route
        Button(action: {
            buttonPressed = "Save Route"
            
        }) {
            ZStack {
                Image("WhiteButtonBackground")
                    .resizable()
                    .frame(maxWidth: UIScreen.main.bounds.size.width/1.1, maxHeight: UIScreen.main.bounds.size.height/5)
                Text("Save Route")
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
            }
            
        }
    }
           
}



