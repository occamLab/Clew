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
