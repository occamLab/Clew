//
//  BusStopDataModel.swift
//  Clew
//
//  Created by Olin Candidate on 2/17/23.
//  Copyright © 2023 OccamLab. All rights reserved.
//


import Foundation

struct ResponseData: Decodable {
    var colors: [ColorPair]
}

struct ColorPair : Decodable {
    var color: String
    var value: String
}

class BusStopDataModel {
    init() {
        if let path = Bundle.main.path(forResource: "sample", ofType: "json") {
            do {
                  let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                print("data \(data)")
                let decoder = JSONDecoder()
                let jsonData = try decoder.decode(ResponseData.self, from: data)
                for color in jsonData.colors {
                    print("color \(color.color) value \(color.value)")
                }
              } catch {
                   // handle error
                  print("error \(error)")
                  print("test")
              }
        }
        
        print("test")
    }
}
