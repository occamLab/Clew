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
                
                ScanButton(vc: vc)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal, 20)
                
                
            }.onAppear(perform: {
                codeIDModel.code = ""
            })
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

                Text(NSLocalizedString("scanNfcButtonText", comment: "This is the label of the button the user presses to scan an NFC tag containing the app clip code ID."))
                    .bold()
                    .foregroundColor(Color.black)
                Spacer()
            }
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

