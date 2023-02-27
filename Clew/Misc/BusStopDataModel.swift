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
        if let path = Bundle.main.path(forResource: "test", ofType: "json") {
            do {
                  let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                print("data \(data)")
                let decoder = JSONDecoder()
                stops = try decoder.decode([BusStop].self, from: data)
              } catch {
                   // handle error
                  print("error \(error)")
                  print("test")
              }
        }
    }
}

//class BusStopDataModel {
//    init() {
//        if let path = Bundle.main.path(forResource: "busStopData", ofType: "csv") {
////            var allBusStops = try! DataFrame(
////                csvData: path,
////                options: options
////            )
//            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: options)
//
//        }
//
//    }
//}

//guard let fileUrl = URL(string: deaths_path) else {
//
//    fatalError("Error creating Url")
//
//}
//
//
//var covidDeathsDf = try! DataFrame(
//
//    contentsOfCSVFile: fileUrl,
//
//    options: options)
//
//
//print("\(covidDeathsDf)")


//struct ResponseData: Decodable {
//    var colors: [ColorPair]
//}
//
//struct ColorPair : Decodable {
//    var color: String
//    var value: String
//}
//
//class BusStopDataModel {
//    init() {
//        if let path = Bundle.main.path(forResource: "sample", ofType: "json") {
//            do {
//                  let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
//                print("data \(data)")
//                let decoder = JSONDecoder()
//                let jsonData = try decoder.decode(ResponseData.self, from: data)
//                for color in jsonData.colors {
//                    print("color \(color.color) value \(color.value)")
//                }
//              } catch {
//                   // handle error
//                  print("error \(error)")
//                  print("test")
//              }
//        }
//
//        print("test")
//    }
//}
