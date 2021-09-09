//
//  EndNavigationScreen.swift
//  Clew-More
//
//  Created by occamlab on 7/27/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI
import ARDataLogger
import FirebaseStorage

class LoggerDelegate: ObservableObject, ARDataLoggerDelegate {
    var uploadPending = false
    func dataUploadDidFinishWithError(error: Error) {
        uploadPending = false
        objectWillChange.send()
    }
    
    func dataUploadDidFinishSuccessfully(metadata: StorageMetadata) {
        uploadPending = false
        objectWillChange.send()
    }
}

struct EndNavigationScreen: View {
    var vc: ViewController
    @State private var feedbackGiven = false
    @StateObject var loggerDelegate = LoggerDelegate()
    var body: some View {

        ZStack{
            Rectangle()
                .fill(Color.white)
            VStack {
                
                /// Title
                Text("Navigation Complete")
                    .font(.title)
                    .foregroundColor(.black)
                    .accessibility(addTraits: .isSelected)
                
                /// Route Feedback Stack
                ZStack {
                    if !feedbackGiven {
                        VStack {
                            Text("Please Rate Your Route Experience")
                                .font(.title2)
                                .foregroundColor(.black)
                            HStack {
                                Spacer()
                                Button(action: {
                                    vc.surveyInterface.sendLogDataHelper(pathStatus: false, announceArrival: true, vc: vc)
                                    feedbackGiven = true
                                    // TODO: figure out how to have this get invoked from other views (e.g., the root container view) for cases when we don't have the user giving feedback (e.g., they just hit the home button).
                                    loggerDelegate.uploadPending = true
                                    vc.arLogger.uploadLocalDataToCloud()
                                }){
                                    Image("thumbs_up")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                }
                                .accessibility(label: Text("Good"))
                                .accessibility(hint: Text("Submit Feedback that route is good"))
                                Button(action: {
                                    vc.surveyInterface.sendLogDataHelper(pathStatus: true, announceArrival: true, vc: vc)
                                    feedbackGiven = true
                                    loggerDelegate.uploadPending = true
                                    vc.arLogger.uploadLocalDataToCloud()
                                }){
                                    Image("thumbs_down_red")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                }.accessibility(label: Text("Bad"))
                                .accessibility(hint: Text("Submit Feedback That Route is Bad"))


                                Spacer()
                            }
                        }
                    }
                    if feedbackGiven {
                        Rectangle()
                            .fill(Color.white)
                        Text("Thank you for your feedback")
                    }
                }
                
                /// Voice Feedback Interface
                RecordFeedbackView()
                
                /// Home Button
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

            }.padding()
                
        }.onAppear(perform: {
            feedbackGiven = false
            ARLogger.shared.delegate = loggerDelegate
        })
        .sheet(isPresented: $loggerDelegate.uploadPending) {
            UploadingView(loadingViewShowing: $loggerDelegate.uploadPending)
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
                .font(.title2)
                .foregroundColor(.black)
            Spacer()
        }
        .background(Color.white)
    }
}


 
