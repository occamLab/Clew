//
//  TargetLocationDataModel.swift
//  Clew
//
//  Created by Olin Candidate on 4/3/23.
//  Copyright © 2023 OccamLab. All rights reserved.
// TODO: Save objects to memory

import Foundation
import TabularData

struct TargetLocation: Decodable {
    var name: String
    var latitude: Double
    var longitude: Double
    var type: String // "Door" or "Bus"
    var id: Int? // only for bus
    var direction: Int? // only for bus
    func distanceFrom(latitude: Double, longitude: Double)->Double {
        let targetLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        return targetLocation.distance(from: CLLocation(latitude: latitude, longitude: longitude))
    }
}

// Additional structs needed to decode marked data from Google Earth

struct DoorRaw: Codable {
    let type, name: String
    let crs: CRS
    let features: [Feature]
}

struct CRS: Codable {
    let type: String
    let properties: CRSProperties
}

struct CRSProperties: Codable {
    let name: String
}

struct Feature: Codable {
    let type: String
    let properties: FeatureProperties
    let geometry: Geometry
}

struct Geometry: Codable {
    let type: String
    let coordinates: [Double]
}

struct FeatureProperties: Codable {
    let name: String

    enum CodingKeys: String, CodingKey {
        case name = "Name"
    }
}

// one shared struct TargetLocation
// contains variables:
// id (only for Bus)
// direction (only for Bus)
// name
// latitude
// longtitude
// func distanceFrom
// TODO needs to parse differently if its busStop or Door

class TargetLocationDataModel {
    // TODO
    public static var shared = TargetLocationDataModel()
    
    var doorsRaw: [Feature] = [] // raw doors
    var targetLocations: [TargetLocation] = []
    
    private init() {
        // Add doors from specific file name
        // TODO iterate through all files in folder?
        
        if let path = Bundle.main.path(forResource: "Olin_College_Doors", ofType: "geojson") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                doorsRaw = try decoder.decode(DoorRaw.self, from: data).features
                for i in 0...doorsRaw.count-1 {
                    let name = doorsRaw[i].properties.name
                    let latitude = doorsRaw[i].geometry.coordinates[1]
                    let longitude = doorsRaw[i].geometry.coordinates[0]
                    targetLocations.append(TargetLocation(name: name, latitude: latitude, longitude: longitude, type: "Door"))
                }
                targetLocations.append(TargetLocation(name: "CCSideByHand", latitude: 42.293811, longitude: -71.263533, type: "Door"))
                targetLocations.append(TargetLocation(name: "Howe Building East", latitude: 42.361361, longitude: -71.174921, type: "Door"))
                targetLocations.append(TargetLocation(name: "Library Main Door", latitude: 42.3615711, longitude: -71.177996, type: "Door"))
            } catch {
                    // handle error
                    print("error \(error) decoding Doors")
            }
        }
        
        if let path = Bundle.main.path(forResource: "mbtaBusStops", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                var busStopTargets = try decoder.decode([TargetLocation].self, from: data)
                for var targetLocation in busStopTargets {
                    targetLocation.type = "Bus"
                    targetLocations.append(targetLocation)
                }
                // add testing bus stops
                targetLocations.append(TargetLocation(name: "OlinMAC", latitude: 42.293592, longitude: -71.264154, type: "Bus", id: 0, direction: 0))
                targetLocations.append(TargetLocation(name: "OlinCenterO", latitude: 42.293584, longitude: -71.263934, type: "Bus", id: 1, direction: 1))
                
            } catch {
                // handle error
                print("error \(error) decoding Bus Stops")
            }
        }
    }
}
