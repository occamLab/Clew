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

enum GeospatialOverallQuality: Int, CustomStringConvertible {
    var description: String {
        switch (self) {
        case .excellent:
            return "excellent"
        case .good:
            return "good"
        case .fair:
            return "fair"
        case .poor:
            return "poor"
        }
    }
    
    case excellent = 0
    case good = 1
    case fair = 2
    case poor = 3
    
    func isAsGoodOrBetterThan(_ other: GeospatialOverallQuality)->Bool {
        return self.rawValue <= other.rawValue
    }
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
    
    func asDict()->[String: Any] {
        return ["altitude": self.altitude, "heading": self.heading, "latitude": self.coordinate.latitude, "longitude": self.coordinate.longitude,  "altitudeAccuracy": self.verticalAccuracy, "positionAccuracy": self.horizontalAccuracy, "headingAccuracy": self.headingAccuracy]
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
                         Text(String("Latitude: \(spatialTransform.coordinate.latitude)")).foregroundColor(Color.white)
                             .padding(20)
                         Text(String("Longitude: \(spatialTransform.coordinate.longitude)")).foregroundColor(Color.white)
                             .padding(20)
                         Text(String("Overall outdoor localization is \(spatialTransform.trackingQuality)")).foregroundColor(Color.white)
                             .padding(20)
                         Text(String("Position is accurate to  \(String(format: "%.1f", spatialTransform.horizontalAccuracy)) meters"))
                             .foregroundColor(Color.white)
                             .padding(20)
                         
                         Text(String("Altitude is accurate to  \(String(format: "%.1f", spatialTransform.verticalAccuracy)) meters"))
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
