//
//  NameSavedRouteView.swift
//  Clew
//
//  Created by Berwin Lan on 7/20/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI
import Combine


/// A text entry box in which to enter the app clip code ID
struct NameSavedRouteView: View {
    @State private var routeName: String = ""
    let vc: ViewController
//    let worldMap: Any?

     var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.clear)
            VStack {
//                TextField(NSLocalizedString("codeIDprompt", comment: "This is a string appearing in the text box asking the user to enter their 3-digit app clip code ID"), text: $routeName)
                TextField("name me!", text: $routeName)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black, lineWidth: 3))
                    .padding(3)
                    .overlay(RoundedRectangle(cornerRadius: 2 * 3)
                                .stroke(Color.white, lineWidth: 3))
                    .padding(20)
                    
                EnterNameButton(vc: vc, routeName: routeName)
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

//                Text(NSLocalizedString("proceedToRoutes", comment: "This is the label of the button the user presses to have Firebase load in the routes based on the app clip code ID."))
                Text("press me to save route name")
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
    
    var body: some View {
        Button(action: {
            vc.routeName = routeName as NSString
            vc.saveRouteButtonPressed()
            vc.state = .readyToNavigateOrPause(allowPause: false)
        }) {
            EnterNameButtonView()
        }
    }
}
