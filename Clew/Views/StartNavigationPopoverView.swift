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
        var routeID: String = ""
        var selected = false
        
        NavigationView {
            List(vc.dataPersistence.routes) { route in
                
                Button(action: {
                    //routeID = String(route.name)
                    routeID = "table2wall"

                    vc.routeID = routeID
                    vc.imageAnchoring = true
                    vc.recordPathController.remove()
                    vc.handleStateTransitionToNavigatingExternalRoute()
                    NotificationCenter.default.post(name: NSNotification.Name("shouldDismissRoutePopover"), object: nil)
                        
                }) {
                    RouteList(Route: route)
                }
            }
            .navigationTitle("Select A Route")
            .padding()
        }
        Button(action: {
            if selected {
                vc.routeID = routeID

            }
        }) {
            Text("Start Navigation")
        }
    }
    
            
}

struct RouteList: View {
    
    var Route: SavedRoute
    
    var body: some View {
        HStack {
            Image("route")
                .resizable()
                .frame(width: 50, height: 50)
            
            Text(String(Route.name))
            
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
