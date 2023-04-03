//
//  BusStopDataModel.swift
//  Clew
//
//  Created by Olin Candidate on 2/17/23.
//  Copyright © 2023 OccamLab. All rights reserved.
//


import Foundation
import TabularData


struct BusStop : Decodable {
    var Stop_ID: Int
    var Stop_name: String
    var Direction: Int
    var Latitude: Double
    var Longitude: Double
    func distanceFrom(latitude: Double, longitude: Double)->Double {
        let busStopLocation = CLLocation(latitude: self.Latitude, longitude: self.Longitude)
        return busStopLocation.distance(from: CLLocation(latitude: latitude, longitude: longitude))
    }
}

class BusStopDataModel {
    public static var shared = BusStopDataModel()
    
    var stops: [BusStop] = []
    private init() {
        if let path = Bundle.main.path(forResource: "mbtaBusStops", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                print("data \(data)")
                let decoder = JSONDecoder()
                stops = try decoder.decode([BusStop].self, from: data)
                
                // add testing bus stops
                stops.append(BusStop(Stop_ID: 0, Stop_name: "OlinMAC", Direction: 0, Latitude: 42.293592, Longitude: -71.264154))
                stops.append(BusStop(Stop_ID: 1, Stop_name: "OlinCenterO", Direction: 1, Latitude: 42.293584, Longitude: -71.263934))
                
            } catch {
                // handle error
                print("error \(error)")
                print("test")
            }
        }
    }
    
    func getClosestBusStops(to coordinate: CLLocationCoordinate2D)->[BusStop] {
        var closestBusStops: [BusStop] = []
        for stop in BusStopDataModel.shared.stops {
            let distance = stop.distanceFrom(latitude: coordinate.latitude, longitude: coordinate.longitude)
            if Set(closestBusStops.map({$0.Stop_ID})).contains(stop.Stop_ID) {
                continue
            }
            if closestBusStops.count >= 2 {
                if closestBusStops[1].distanceFrom(latitude: coordinate.latitude, longitude: coordinate.longitude) > distance {
                    closestBusStops[1] = stop
                }
            }
            else {
                closestBusStops.append(stop)
            }
            closestBusStops = closestBusStops.sorted(by: {$0.distanceFrom(latitude: coordinate.latitude, longitude: coordinate.longitude) < $1.distanceFrom(latitude: coordinate.latitude, longitude: coordinate.longitude)})
        }
        print("closest stops \(closestBusStops[0].Stop_name), \(closestBusStops[1].Stop_name)")
        print("closest stops \(closestBusStops[0].Stop_ID), \(closestBusStops[1].Stop_ID)")
        return closestBusStops
    }
}
