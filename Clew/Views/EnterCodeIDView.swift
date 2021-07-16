//
//  EnterCodeIDView.swift
//  Clew
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
            TextField(NSLocalizedString("codeIDprompt", comment: "This is a string appearing in the text box asking the user to enter their 3-digit app clip code ID"), text: $codeIDModel.code)
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
                .padding(40)
                .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.clewGreen, lineWidth: 10)
                )
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding(.horizontal, 20)
        }
     }
}

struct EnterButtonView: View {
    var body: some View {
        HStack{
            Spacer()

            Text(NSLocalizedString("proceedToRoutes", comment: "This is the label of the button the user presses to have Firebase load in the routes based on the app clip code ID."))
                .bold()
                .foregroundColor(Color.primary)
            Spacer()
        }
    }
}

/// Press this button to submit the app clip code ID and proceed to the routes
struct EnterButton: View {
    var vc: ViewController
    var codeID: String
    var body: some View {
        Button(action: {
            vc.appClipCodeID = codeID
            NotificationCenter.default.post(name: NSNotification.Name("shouldDismissCodeIDPopover"), object: nil)
            vc.codeIDEntered()
        }) {
            EnterButtonView()
        }
    }
}
