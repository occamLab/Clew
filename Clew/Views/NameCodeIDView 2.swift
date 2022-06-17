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
//@available(iOS 15.0, *)
struct NameCodeIDView: View {
    let vc: ViewController
    @ObservedObject private var codeIDModel = CodeIDModel() /// this is in EnterCodeIDView
    //@FocusState private var keypadIsFocused: Bool

     var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .foregroundColor(Color.black.opacity(0.4))
                    .frame(maxHeight: .infinity)
                Text(NSLocalizedString("nameCodeIDLabel", comment: "Text that instructs the user to enter the code ID associated with the start anchor of the route they are recording."))
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 20)
            }
            VStack {
                TextField(NSLocalizedString("nameCodeIDTextField", comment: "This is a string appearing in the text box asking the user to enter their 3-digit app clip code ID"), text: $codeIDModel.code)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .overlay(RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black, lineWidth: 3))
                    .padding(3)
                    .overlay(RoundedRectangle(cornerRadius: 2 * 3)
                                .stroke(Color.white, lineWidth: 3))
                    .padding(20)
                   // .focused($keypadIsFocused)
                
                NameCodeIDButton(vc: vc, codeID: codeIDModel.code)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal, 20)
                
                ScanNFCButton(vc: vc)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal, 20)
            }.onAppear(perform: {
                codeIDModel.code = ""
                //keypadIsFocused = false
            })
         }
     }
}

struct NameCodeIDButtonView: View {
    var body: some View {
        ZStack {
            Image("WhiteButtonBackground")
                .resizable()
                .frame(maxWidth: UIScreen.main.bounds.size.width/1.1, maxHeight: UIScreen.main.bounds.size.height/5)
            HStack{
                Spacer()
                Text(NSLocalizedString("nameCodeIDButtonText", comment: "This is the label of the button the user presses to have Firebase load in the routes based on the app clip code ID."))
                    .bold()
                    .foregroundColor(Color.black)
                Spacer()
            }
        }
    }
}

struct ScanNFCButtonView: View {
    var body: some View {
        ZStack {
            Image("WhiteButtonBackground")
                .resizable()
                .frame(maxWidth: UIScreen.main.bounds.size.width/1.1, maxHeight: UIScreen.main.bounds.size.height/5)
            HStack{
                Spacer()
                Text("Scan NFC App Clip Code")
                    .bold()
                    .foregroundColor(Color.black)
                Spacer()
            }
        }
    }
}

/// Press this button to submit the app clip code ID and proceed to the routes
struct NameCodeIDButton: View {
    var vc: ViewController
    var codeID: String
    var body: some View {
        Button(action: {
            if codeID.count == 3 {
                vc.appClipCodeID = codeID
                vc.saveCodeIDButtonPressed()
            } else {
                vc.delayTransition(announcement: NSLocalizedString("codeIDErrorAnnouncement", comment: "This announcement is read out when the user enters a code ID that does not meet the criteria"), initialFocus: nil)
            }

        }) {
            NameCodeIDButtonView()
        }
    }
}

/// Press this button to submit the app clip code ID and proceed to the routes
struct ScanNFCButton: View {
    var vc: ViewController
    var body: some View {
        Button(action: {
            vc.beginScanning(self)

        }) {
            ScanNFCButtonView()
        }
    }
}
