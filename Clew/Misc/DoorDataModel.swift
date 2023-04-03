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
struct Door: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    func distanceFrom(latitude: Double, longitude: Double)->Double {
        let doorLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        return doorLocation.distance(from: CLLocation(latitude: latitude, longitude: longitude))
    }
}

//// MARK: - Welcome
//// hold raw data from JSON
//struct DoorRaw: Codable {
//    let type, name: String
//    let crs: CRS
//    let features: [Feature]
//}
//
//// MARK: - CRS
//struct CRS: Codable {
//    let type: String
//    let properties: CRSProperties
//}
//
//// MARK: - CRSProperties
//struct CRSProperties: Codable {
//    let name: String
//}
//
//// MARK: - Feature
//struct Feature: Codable {
//    let type: String
//    let properties: FeatureProperties
//    let geometry: Geometry
//}
//
//// MARK: - Geometry
//struct Geometry: Codable {
//    let type: String
//    let coordinates: [Double]
//}
//
//// MARK: - FeatureProperties
//struct FeatureProperties: Codable {
//    let name: String
//
//    enum CodingKeys: String, CodingKey {
//        case name = "Name"
//    }
//}

class DoorDataModel {
    public static var shared = DoorDataModel()
    
    var doorsRaw: [Feature] = []
    var doors: [Door] = []
    private init() {
        if let path = Bundle.main.path(forResource: "Olin_College_Doors", ofType: "geojson") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                doorsRaw = try decoder.decode(DoorRaw.self, from: data).features
                for i in 0...doorsRaw.count-1 {
                    let stopName = doorsRaw[i].properties.name
                    let latitude = doorsRaw[i].geometry.coordinates[1]
                    let longitude = doorsRaw[i].geometry.coordinates[0]
                    doors.append(Door(name: stopName, latitude: latitude, longitude: longitude))
                }
                doors.append(Door(name: "CCSideByHand", latitude: 42.293811, longitude: -71.263533))
                doors.append(Door(name: "Howe Building East", latitude: 42.361361, longitude: -71.174921))
                doors.append(Door(name: "Library Main Door", latitude: 42.3615711, longitude: -71.177996))
                print("doors \(doors)")
            } catch {
                    // handle error
                    print("error \(error)")
                }
            }
            }
    
    func getClosestDoors(to coordinate: CLLocationCoordinate2D)->[Door] {
        var closestDoors: [Door] = []
        for door in DoorDataModel.shared.doors {
            let distance = door.distanceFrom(latitude: coordinate.latitude, longitude: coordinate.longitude)
            if Set(closestDoors.map({$0.name})).contains(door.name) {
                continue
            }
            if closestDoors.count >= 2 {
                if closestDoors[1].distanceFrom(latitude: coordinate.latitude, longitude: coordinate.longitude) > distance {
                    closestDoors[1] = door
                }
            }
            else {
                closestDoors.append(door)
            }
            closestDoors = closestDoors.sorted(by: {$0.distanceFrom(latitude: coordinate.latitude, longitude: coordinate.longitude) < $1.distanceFrom(latitude: coordinate.latitude, longitude: coordinate.longitude)})
        }
        print("closest stops \(closestDoors[0].name), \(closestDoors[1].name)")
        return closestDoors
    }

}
