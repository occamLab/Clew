//
//  StartNavigationPopoverView.swift
//  UIKit Clip
//
//  Created by occamlab on 7/1/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI
import Firebase

struct StartNavigationPopoverView: View {
    let vc: ViewController
    @State private var selectedRouteName = "" //TODO: change so it know what your settings are when you enter the walkthrough

    var body: some View {

        VStack {
            Text(NSLocalizedString("startNavigationPopoverText", comment: "This is text that appears with the list of routes in the app clip."))
                .multilineTextAlignment(.center)
                .font(.system(size: 24, weight: .bold))
            
            NavigationView {
                List(vc.availableRoutes, id: \.first!.key) { routeInfo in
                    
                    Button(action: {
                        vc.routeID = routeInfo.first!.key
                        print(vc.routeID)
                        selectedRouteName = routeInfo.first!.value
                        //vc.imageAnchoring = true
                        vc.recordPathController.remove()
                            
                    }) {
                        if selectedRouteName == routeInfo.first!.value {
                            RowSelected {
                                RouteList(RouteName: routeInfo.first!.value)
                            }
                        } else {
                            RowNotSelected {
                                RouteList(RouteName: routeInfo.first!.value)
                            }
                        }
                    }
                }
                .navigationTitle(NSLocalizedString("selectRoutePopoverLabel", comment: "This is text instructing the user to select a route from a list."))
            }
            
            if selectedRouteName.count > 0 {
                StartButton(vc: vc)
                    .padding(12)
            }
        }
    }
}

struct RouteList: View {
    
    var RouteName: String
    
    var body: some View {
        HStack {
            Image("route")
                .resizable()
                .frame(width: 50, height: 50)
            
            Text(RouteName)
                .bold()
            Spacer()
        }
    }
}


struct StartButtonView: View {
    var body: some View {
        HStack{
            Spacer()
            VStack{
                Image("StartNavigation")
                
                Text(NSLocalizedString("startNavigatingLabel", comment: "This text shows up below the play button to start navigating a route."))
                    .bold()
                    .foregroundColor(Color.primary)
            }
            Spacer()
        }
    }
}

struct StartButton: View{
    var vc: ViewController
    var body: some View {
        Button(action: {
            vc.handleStateTransitionToNavigatingExternalRoute()
            NotificationCenter.default.post(name: NSNotification.Name("shouldDismissRoutePopover"), object: nil)
            
        }) {
            StartButtonView()
        }
    }
}


struct RowSelected<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .frame(minWidth: 0, maxWidth: 300)
            .padding()
            .foregroundColor(.black)
            .background(Color.clewGreen)
            .cornerRadius(10)
            .font(.system(size: 18, weight: .bold))
            .padding(10)
            .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.clewGreen, lineWidth: 4))
    }
}

struct RowNotSelected<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .frame(minWidth: 0, maxWidth: 300)
            .padding()
            .foregroundColor(.primary)
            .background(Color.clear)
            .cornerRadius(10)
            .font(.system(size: 18, weight: .bold))
            .padding(10)
            .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.clear, lineWidth: 4))
    }
}
