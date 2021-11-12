//
//  SavedRoutesList.swift
//  Clew-More
//
//  Created by occamlab on 7/19/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI

struct SavedRoutesList: View {
    var vc: ViewController
    @State private var routeList: [SavedRoute] = []

    var body: some View {
        VStack {
            NavigationView {
                List(routeList) { route in
                    
                    Button(action: {
                        //var routeActionPopover = UIViewController()
                        self.vc.routeOptionsController = UIHostingController(rootView: RouteManagerView(route: route, vc: self.vc))
                        self.vc.routeOptionsController?.modalPresentationStyle = .popover
                        self.vc.present(self.vc.routeOptionsController!, animated: true)
                        
                        print("yeeahhh it worked!!")
                    }) {
                        RowNotSelected {
                            RouteList(RouteName: String(route.name))
                        }
                    }.accessibility(label: Text("Route \(String(route.name))"))
                }
                .navigationTitle(NSLocalizedString("selectRoutePopoverLabel", comment: "This is text instructing the user to select a route from a list."))
            }
            

        }.onAppear(perform: {
            self.routeList = self.vc.dataPersistence.routes
            })
    }
}


