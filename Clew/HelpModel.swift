//
//  HelpModel.swift
//  Clew
//
//  Created by tad on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
///retrieves the data from the JSON file
public func dataFromFile(_ filename: String) -> Data? {
    
    ///creates a test Class to help access the information in the JSON file
    @objc class TestClass: NSObject { }
    let bundle = Bundle(for: TestClass.self)
    ///if the supplied file is a json file
    if let path = bundle.path(forResource: filename, ofType: "json") {
        ///attempt to return the contents of the file
        return (try? Data(contentsOf: URL(fileURLWithPath: path)))
    }
    return nil
}

///describes what a HelpTable contains
class HelpTable {
    var appFeatures: String?
    var helpSection: String?
    var howWellDoesClewWork: String?
    var recordingARoute: String?
    var stoppingARecording: String?
    var pausingARouteOrRecordingALandmark: String?
    var resumingARoute: String?
    var theSavedRoutesMenu: String?
    var followingARoute: String?
    var appSoundsAndTheirMeanings: String?
    var ratingYourNavigationExperience: String?
    var providingFeedbackToTheDevelopmentTeam: String?
    
    ///initalizer which sets the state of the help table based on the data provided
    init?(data: Data) {
        do {
            ///try to interpret the JSON data
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let body = json["data"] as? [String: Any] {
                
                ///TODO: CHANGE ALL THIS TO REFLECT A HELP MENU
                
                ///initalize the properties of the profile
                self.appFeatures = body["appFeatures"] as? String
                self.helpSection = body["helpSection"] as? String
                self.howWellDoesClewWork = body["howWellDoesClewWork"] as? String
                self.recordingARoute = body["recordingARoute"] as? String
                self.stoppingARecording = body["stoppingARecording"] as? String
                self.pausingARouteOrRecordingALandmark = body["pausingARouteOrRecordingALandmark"] as? String
                self.resumingARoute = body["resumingARoute"] as? String
                self.theSavedRoutesMenu = body["theSavedRoutesMenu"] as? String
                self.followingARoute = body["followingARoute"] as? String
                self.appSoundsAndTheirMeanings = body["appSoundsAndTheirMeanings"] as? String
                self.ratingYourNavigationExperience = body["ratingYourNavigationExperience"] as? String
                self.providingFeedbackToTheDevelopmentTeam = body["providingFeedbackToTheDevelopmentTeam"] as? String
                
                
            }
        } catch {
            ///if there was an error with parsing the JSON
            print("Error deserializing JSON: \(error)")
            return nil
        }
    }
}

///describes the properties of an attribute
class Attribute {
    ///private variables
    var key: String?
    var value: String?
    
    ///initalizer to set the private variables
    init(json: [String: Any]) {
        self.key = json["key"] as? String
        self.value = json["value"] as? String
    }
}
