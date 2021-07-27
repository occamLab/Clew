//
//  End Navigation Screen.swift
//  Clew-More
//
//  Created by occamlab on 7/27/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI
import ARDataLogger

struct EndNavigationScreen: View {
    var vc: ViewController
    var body: some View {
        VStack{
            Text("Navigation Complete")
                .foregroundColor(.black)
            // placeholder: rating route system
            routeFeedbackButtons()
            
            RecordFeedbackView()
                .padding()
            
            Button(action: {
                vc.hideAllViewsHelper()
                vc.state = .mainScreen(announceArrival: true)
                vc.arLogger.finalizeTrial()
                //vc.arLogger.startTrial()
                
            }){
                homeButtonView()
            }
        }
 
    }
}

struct routeFeedbackButtons: View {
    var body: some View {
        HStack {
            Spacer()
            Image("thumbs_up")
                .resizable()
                .aspectRatio(contentMode: .fit)
            Image("thumbs_down")
                .resizable()
                .aspectRatio(contentMode: .fit)
            Spacer()
        }
    }
}

struct homeButtonView: View {
    var body: some View {
        HStack {
            Image("homeButton")
                .resizable()
                .frame(width: 50, height: 50)
            Text("Main Menu")
                .bold()
                
            Spacer()
        }.background(Color.white)
    }
}


 
