//
//  EndNavigationScreen.swift
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
        ZStack {
            Rectangle()
                .fill(Color.white)
            
            VStack {
                Text("Navigation Complete")
                    .foregroundColor(.black)
                    .font(.title)

                // placeholder: rating route system
                routeFeedbackButtons()
                
                RecordFeedbackView()
                
                Button(action: {
                    vc.hideAllViewsHelper()
                    vc.state = .mainScreen(announceArrival: false)
                    vc.arLogger.finalizeTrial()
                }){
                    homeButtonView()
                }
            }
            .padding()
        }
    }
}

struct routeFeedbackButtons: View {
    var body: some View {
        VStack{
            Text("Please rate your route experience")
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
}

struct homeButtonView: View {
    var body: some View {
        HStack {
            Image("homeButton")
                .resizable()
                .frame(width: 50, height: 50)
                .padding()
            Text("Main Menu")
                .bold()
            Spacer()
        }
        .background(Color.white)
    }
}


 
