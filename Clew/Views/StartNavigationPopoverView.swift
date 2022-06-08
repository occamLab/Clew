//
//  StartNavigationPopoverView.swift
//  UIKit Clip
//
//  Created by Esme Abbot on 7/1/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI
import Firebase

class RouteListObject: ObservableObject {
    @Published var routeList = [[String: String]]()
}

struct StartNavigationPopoverView: View {
    let vc: ViewController
    @ObservedObject var routeList: RouteListObject

    var body: some View {
        VStack {
            NavigationView {
                List(routeList.routeList, id: \.first!.key) { routeInfo in
                    Button(action: {
                        vc.routeID = routeInfo.first!.key
                        vc.recordPathController.remove()
                        NotificationCenter.default.post(name: NSNotification.Name("shouldDismissRoutePopover"), object: nil)
                        #if !APPCLIP
                        self.vc.arLogger.startTrial()
                        #endif
                    }) {
                        RowNotSelected {
                            RouteList(RouteName: routeInfo.first!.value)
                        }
                    }
                }
                .navigationTitle(NSLocalizedString("selectRoutePopoverLabel", comment: "This is text instructing the user to select a route from a list ."))
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
                    .foregroundColor(Color.black)
            }
            Spacer()
        }
        .padding(12)

    }
}

struct StartButton: View {
    var vc: ViewController
    var body: some View {
        Button(action: {
            NotificationCenter.default.post(name: NSNotification.Name("shouldDismissRoutePopover"), object: nil)
            #if !APPCLIP
            self.vc.arLogger.startTrial()
            #endif
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
