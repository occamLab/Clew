//
//  NameSavedRouteView.swift
//  Clew
//
//  Created by Berwin Lan on 7/20/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI
import Combine


/// A text entry box in which to enter the recorded route's name
struct NameSavedRouteView: View {
    @State private var routeName: String = ""
    let vc: ViewController
    var worldMap: Any?
    
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .foregroundColor(Color.black.opacity(0.4))
                    .frame(maxHeight: .infinity)
                Text(NSLocalizedString("nameSavedRouteLabel", comment: "Text that instructs the user to name the route they just recorded."))
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 20)
            }
            VStack {
                TextField(NSLocalizedString("nameSavedRouteTextField", comment: "Message displayed to the user when typing to save a route by name."), text: $routeName)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black, lineWidth: 3))
                    .padding(3)
                    .overlay(RoundedRectangle(cornerRadius: 2 * 3)
                                .stroke(Color.white, lineWidth: 3))
                    .padding(20)
                    
                EnterNameButton(vc: vc, routeName: routeName, worldMap: worldMap)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal, 20)
            } .onAppear(perform: {
                routeName = ""
            })
        }
    }
}

struct EnterNameButtonView: View {
    var body: some View {
        ZStack {
            Image("WhiteButtonBackground")
                .resizable()
                .frame(maxWidth: UIScreen.main.bounds.size.width/1.1, maxHeight: UIScreen.main.bounds.size.height/5)
            HStack {
                Spacer()
                Text(NSLocalizedString("nameSavedRouteButtonText", comment: "The text that appears on the button the user should press to submit their route name."))
                    .bold()
                    .foregroundColor(Color.black)
                Spacer()
            }
        }
    }
}

/// Press this button to submit the app clip code ID and proceed to the routes
struct EnterNameButton: View {
    var vc: ViewController
    var routeName: String
    var worldMap: Any?
    
    var body: some View {
        Button(action: {
            vc.routeName = routeName as NSString
            vc.saveRouteButtonPressed(worldMap: worldMap)
            vc.state = .readyToNavigateOrPause(allowPause: false)
        }) {
            EnterNameButtonView()
        }
    }
}
