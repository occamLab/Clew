//
//  TestingAccuracyView.swift
//  Clew
//  This view is used when a user enters an app clip code ID to bring up a list of routes.
//
//  Created by Paul Ruvolo on 7/23/21.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import SwiftUI
import Combine
import ARCore

enum GeospatialOverallQuality: String {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
}

extension GARGeospatialTransform {
    static var excellentQualityAltitudeAccuracy = 1.0
    static var goodQualityAltitudeAccuracy = 3.0
    static var fairQualityAltitudeAccuracy = 5.0
    
    static var excellentQualityHorizontalAccuracy = 0.8
    static var goodQualityHorizontalAccuracy = 3.0
    static var fairQualityHorizontalAccuracy = 5.0
    
    static var excellentQualityHeadingAccuracy = 2.5
    static var goodQualityHeadingAccuracy = 5.0
    static var fairQualityHeadingAccuracy = 15.0

    var trackingQuality: GeospatialOverallQuality {
        if horizontalAccuracy < Self.excellentQualityHorizontalAccuracy, verticalAccuracy < Self.excellentQualityAltitudeAccuracy, headingAccuracy < Self.excellentQualityHeadingAccuracy {
            return .excellent
        } else if horizontalAccuracy < Self.goodQualityHorizontalAccuracy, verticalAccuracy < Self.goodQualityAltitudeAccuracy, headingAccuracy < Self.goodQualityHeadingAccuracy {
            return .good
        } else if horizontalAccuracy < Self.fairQualityHorizontalAccuracy, verticalAccuracy < Self.fairQualityAltitudeAccuracy, headingAccuracy < Self.fairQualityHeadingAccuracy {
            return .fair
        } else {
            return .poor
        }
    }
}

/// Show the accuracy level of the GARSession
struct TestingAccuracyView: View {
    let vc: ViewController
    @ObservedObject private var arSession = ARSessionManager.shared
    
     var body: some View {
         if let (_, spatialTransform) = arSession.worldTransformGeoSpatialPair {
             VStack {
                 ZStack {
                     Rectangle()
                         .foregroundColor(Color.black.opacity(0.4))
                         .frame(maxHeight: .infinity)
                     VStack(alignment: .leading) {
                         Text(String("Overall outdoor localization is \(spatialTransform.trackingQuality)")).foregroundColor(Color.white)
                             .padding(20)
                         Text(String("Position is accurate to  \(String(format: "%.1f", spatialTransform.horizontalAccuracy)) meters"))
                             .foregroundColor(Color.white)
                             .padding(20)
                         
                         Text(String("Altitude is accurate to  \(String(format: "%.1f", spatialTransform.altitude)) meters"))
                             .foregroundColor(Color.white)
                             .padding(20)
                         
                         Text(String("Heading is accurate to  \(String(format: "%.1f", spatialTransform.headingAccuracy)) degrees"))
                             .foregroundColor(Color.white)
                             .padding(20)
                     }
                 }
              }
         } else {
             Text("Tracking is invalid")
         }
     }
}
