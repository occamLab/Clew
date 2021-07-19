//
//  RouteManagerView.swift
//  Clew-More
//
//  Created by occamlab on 7/19/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI

struct RouteManagerView: View {
    var route: SavedRoute
    var vc: ViewController
    var body: some View {
        Text(String(route.name))
            .font(.title)
            .multilineTextAlignment(.center)
        Text("App Clip Code ID: \(String(route.appClipCodeID))")
            .font(.title2)
        VStack {
            Button(action: {
                self.vc.onRouteTableViewCellClicked(route: self.route, navigateStartToEnd: true)
                self.vc.routeOptionsController?.dismiss(animated: false)
            } ){
                Text("Navigate/Test Route")
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
            }.padding()
            
            Button(action: {
                self.vc.dataPersistence.uploadToFirebase(route: self.route)
                self.vc.routeOptionsController?.dismiss(animated: false)
                self.vc.hideAllViewsHelper()
                self.vc.add(self.vc.recordPathController)

            }) {
                Text("Upload Route")
                    .frame(minWidth: 0, maxWidth: 300)
                    .padding()
                    .foregroundColor(.black)
                    .background(Color.orange)
                    .cornerRadius(10)
                    .font(.system(size: 18, weight: .bold))
                    .padding(10)
                    .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.orange, lineWidth: 4))
            }.padding()
            
            Button(action: {
                do {
                    try self.vc.dataPersistence.delete(route: self.route)
                    self.vc.routeOptionsController?.dismiss(animated: false)
                    self.vc.hideAllViewsHelper()
                    self.vc.add(self.vc.recordPathController)
                    //self.routes.remove(at: indexPath.row)
                    //self.tableView.deleteRows(at: [indexPath], with: .fade)
                } catch {
                    print("Unexpectedly failed to persist the new routes data")
                }
            }) {
                Text("Delete Route")
                    .frame(minWidth: 0, maxWidth: 300)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(10)
                    .font(.system(size: 18, weight: .bold))
                    .padding(10)
                    .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red, lineWidth: 4))
            }.padding()
            
            Button(action: {
                let url = self.vc.dataPersistence.uploadToFirebase(route: self.route)
                
                /// define share menu content and a message to show with it
                /// TODO: localize
                let activity = UIActivityViewController(
                    activityItems: [NSLocalizedString("automaticEmailTextWhenSharingRoutes", comment: "The text added to an email for sharing routes."), url as Any],
                    applicationActivities: nil
                )
                self.vc.routeOptionsController?.dismiss(animated: false)
                /// show the share menu
                self.vc.present(activity, animated: true, completion: nil)
            }) {
                Text("Share")
                    .frame(minWidth: 0, maxWidth: 300)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.clewGreen)
                    .cornerRadius(10)
                    .font(.system(size: 18, weight: .bold))
                    .padding(10)
                    .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.clewGreen, lineWidth: 4))
            }.padding()
            
        }
     
        
    }
}

