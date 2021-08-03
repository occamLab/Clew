//
//  EnterCodeIDView.swift
//  Clew
//  This view is used when a user enters an app clip code ID to bring up a list of routes.
//
//  Created by Berwin Lan on 7/7/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI
import Combine

class CodeIDModel: ObservableObject {
    var limit: Int = 3

    @Published var code: String = "" {
        didSet {
             if code.count > limit {
                code = String(code.prefix(limit))
             }
        }
    }
}

/// A text entry box in which to enter the app clip code ID
struct EnterCodeIDView: View {
    let vc: ViewController
    @ObservedObject private var codeIDModel = CodeIDModel()
    
     var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .foregroundColor(Color.black.opacity(0.4))
                    .frame(maxHeight: .infinity)
                Text(NSLocalizedString("enterCodeIDLabel", comment: "This text appears instructing the user to enter their app clip code ID."))
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 20)
            }
            VStack {
                TextField(NSLocalizedString("enterCodeIDTextField", comment: "This is a string appearing in the text box asking the user to enter their 3-digit app clip code ID"), text: $codeIDModel.code)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .overlay(RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black, lineWidth: 3))
                    .padding(3)
                    .overlay(RoundedRectangle(cornerRadius: 2 * 3)
                                .stroke(Color.white, lineWidth: 3))
                    .padding(20)
                
                EnterButton(vc: vc, codeID: codeIDModel.code)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal, 20)
                
                Text("OR")
                
                ScanButton(vc: vc)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal, 20)
                
                
            }.onAppear(perform: {
                codeIDModel.code = ""
            })
         }
     }
}

struct EnterButtonView: View {
    var body: some View {
        ZStack {
            Image("WhiteButtonBackground")
                .resizable()
                .frame(maxWidth: UIScreen.main.bounds.size.width/1.1, maxHeight: UIScreen.main.bounds.size.height/5)
            HStack{
                Spacer()

                Text(NSLocalizedString("enterCodeIDButtonText", comment: "This is the label of the button the user presses to have Firebase load in the routes based on the app clip code ID."))
                    .bold()
                    .foregroundColor(Color.black)
                Spacer()
            }
        }
    }
}

struct ScanButtonView: View {
    var body: some View {
        ZStack {
            Image("WhiteButtonBackground")
                .resizable()
                .frame(maxWidth: UIScreen.main.bounds.size.width/1.1, maxHeight: UIScreen.main.bounds.size.height/5)
            HStack{
                Spacer()

                Text("Scan an NFC App Clip Code")
                    .bold()
                    .foregroundColor(Color.black)
                Spacer()
            }
        }
    }
}

/// Press this button to submit the app clip code ID and proceed to the routes
struct EnterButton: View {
    var vc: ViewController
    var codeID: String
    var body: some View {
        Button(action: {
            if codeID.count == 3 {
                vc.appClipCodeID = codeID
                NotificationCenter.default.post(name: NSNotification.Name("shouldDismissCodeIDPopover"), object: nil)
                vc.codeIDEntered()
            } else {
                vc.delayTransition(announcement: NSLocalizedString("codeIDErrorAnnouncement", comment: "This announcement is read out when the user enters a code ID that does not meet the criteria"), initialFocus: nil)
            }
        }) {
            EnterButtonView()
        }
    }
}

/// Press this button to open the Scan NFC Tag popover
struct ScanButton: View {
    var vc: ViewController
    var body: some View {
        Button(action: {
            vc.beginScanning(self)
            NotificationCenter.default.post(name: NSNotification.Name("shouldDismissCodeIDPopover"), object: nil)
        }) {
            ScanButtonView()
        }
    }
}

