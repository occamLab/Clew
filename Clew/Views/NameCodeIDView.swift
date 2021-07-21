//
//  NameCodeIDView.swift
//  Clew
//  This view is used when a new route is recorded.
//
//  Created by Berwin Lan on 7/20/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI
import Combine

/// A text entry box in which to enter the app clip code ID
struct NameCodeIDView: View {
    let vc: ViewController
    @ObservedObject private var codeIDModel = CodeIDModel()
    

     var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.clear)
            VStack {
//                TextField(NSLocalizedString("codeIDprompt", comment: "This is a string appearing in the text box asking the user to enter their 3-digit app clip code ID"), text: $codeIDModel.code)
                TextField("enter code id here", text: $codeIDModel.code)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .overlay(RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black, lineWidth: 3))
                    .padding(3)
                    .overlay(RoundedRectangle(cornerRadius: 2 * 3)
                                .stroke(Color.white, lineWidth: 3))
                    .padding(20)
                    
                
                EnterCodeIDButton(vc: vc, codeID: codeIDModel.code)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal, 20)
            }.onAppear(perform: {
                codeIDModel.code = ""
            })
         }
     }
}

struct EnterCodeIDButtonView: View {
    var body: some View {
        ZStack {
            Image("WhiteButtonBackground")
                .resizable()
                .frame(maxWidth: UIScreen.main.bounds.size.width/1.1, maxHeight: UIScreen.main.bounds.size.height/5)
            HStack{
                Spacer()

//                Text(NSLocalizedString("proceedToRoutes", comment: "This is the label of the button the user presses to have Firebase load in the routes based on the app clip code ID."))
                Text("save code id")
                    .bold()
                    .foregroundColor(Color.black)
                Spacer()
            }
        }
    }
}

/// Press this button to submit the app clip code ID and proceed to the routes
struct EnterCodeIDButton: View {
    var vc: ViewController
    var codeID: String
    var body: some View {
        Button(action: {
            vc.appClipCodeID = codeID
            vc.saveCodeIDButtonPressed()
        }) {
            EnterCodeIDButtonView()
        }
    }
}
