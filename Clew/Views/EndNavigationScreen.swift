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
    @State private var feedbackGiven = false
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
            
            VStack {
                Text("Navigation Complete")
                    .foregroundColor(.black)
                // placeholder: rating route system
                routeFeedbackButtons(vc: vc)
                RecordFeedbackView()
                    .padding()
                
                Button(action: {
                    if !feedbackGiven{
                        vc.surveyInterface.sendLogDataHelper(pathStatus: nil, announceArrival: true, vc: vc)
                    }
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
    var vc: ViewController
    var body: some View {
        VStack{
            Text("Please rate your route experience")
            HStack {
                Spacer()
                Button(action: {
                    vc.surveyInterface.sendLogDataHelper(pathStatus: false, announceArrival: true, vc: vc)
                }){
                    Image("thumbs_up")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                Button(action: {
                    vc.surveyInterface.sendLogDataHelper(pathStatus: true, announceArrival: true, vc: vc)

                }){
                    Image("thumbs_down")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }

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


 
