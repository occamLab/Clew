//
//  StartNavigationPopoverView.swift
//  UIKit Clip
//
//  Created by occamlab on 7/1/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI

struct StartNavigationPopoverView: View {
    let vc: ViewController
    
    var body: some View {
        var routePath: String = ""
        var selected = false
        
        NavigationView {
            List(vc.availableRoutes.sorted(by: >), id: \.key) { routeInfo in
                
                Button(action: {
                    routePath = routeInfo.value
                    vc.firebasePath = routePath
                    selected = true
                    vc.imageAnchoring = true
                    vc.recordPathController.remove()

                        
                }) {
                    RouteList(RouteName: routeInfo.key)
                }
            }
            .navigationTitle("Select A Route")
            .padding()
        }
        Button(action: {
            if selected {
                vc.handleStateTransitionToNavigatingExternalRoute()
                NotificationCenter.default.post(name: NSNotification.Name("shouldDismissRoutePopover"), object: nil)
            }
        }) {
            Text("Start Navigation")
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
            
            Spacer()
        }
    }
}
/*struct StartNavigationPopoverView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StartNavigationPopoverView(ViewController())
        }
    }
}*/
