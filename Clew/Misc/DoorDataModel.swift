//
//  DoorDataModel.swift
//  Clew
//
//  Created by Olin Candidate on 3/20/23.
//  Copyright © 2023 OccamLab. All rights reserved.
//

import Foundation
import TabularData

// just properties of Doors we want
// created from DoorsRaw
struct Doors: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
}

// MARK: - Welcome
// hold raw data from JSON
struct DoorsRaw: Codable {
    let type, name: String
    let crs: CRS
    let features: [Feature]
}

// MARK: - CRS
struct CRS: Codable {
    let type: String
    let properties: CRSProperties
}

// MARK: - CRSProperties
struct CRSProperties: Codable {
    let name: String
}

// MARK: - Feature
struct Feature: Codable {
    let type: String
    let properties: FeatureProperties
    let geometry: Geometry
}

// MARK: - Geometry
struct Geometry: Codable {
    let type: String
    let coordinates: [Double]
}

// MARK: - FeatureProperties
struct FeatureProperties: Codable {
    let name: String

    enum CodingKeys: String, CodingKey {
        case name = "Name"
    }
}

class DoorDataModel {
    public static var shared = DoorDataModel()
    
    var doorsRaw: [Feature] = []
    var doors: [Doors] = []
    private init() {
        if let path = Bundle.main.path(forResource: "Olin_College_Doors", ofType: "geojson") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                doorsRaw = try decoder.decode(DoorsRaw.self, from: data).features
                for i in 0...doorsRaw.count-1 {
                    let stopName = doorsRaw[i].properties.name
                    let latitude = doorsRaw[i].geometry.coordinates[1]
                    let longitude = doorsRaw[i].geometry.coordinates[0]
                    doors.append(Doors(name: stopName, latitude: latitude, longitude: longitude))
                }
                print("doors \(doors)")
            } catch {
                    // handle error
                    print("error \(error)")
                }
            }
            }

}
