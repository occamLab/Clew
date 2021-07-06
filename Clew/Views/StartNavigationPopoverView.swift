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
            Text("I am placeholder text that will explain what clew is :)")
                .multilineTextAlignment(.center)
                .font(.system(size: 24, weight: .bold))
            NavigationView {
                List(vc.availableRoutes.sorted(by: {$0.0 < $1.0}), id: \.key) { routeInfo in
                    
                    Button(action: {
                        //vc.firebasePath! = routeInfo.value
                        selectedRouteName = routeInfo.key
                        vc.imageAnchoring = true
                        vc.recordPathController.remove()
                            
                    }) {
                        if selectedRouteName == routeInfo.key {
                            RowSelected {
                                RouteList(RouteName: routeInfo.key)
                            }
                        } else {
                            RowNotSelected {
                                RouteList(RouteName: routeInfo.key)
                            }
                        }
                    }
                }
                .navigationTitle("Select Route")
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
                
                Text("Start Navigating")
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
            .background(Color.green)
            .cornerRadius(10)
            .font(.system(size: 18, weight: .bold))
            .padding(10)
            .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green, lineWidth: 4))
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
