//
//  HelpModel.swift
//  Clew
//
//  Created by tad on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
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
    
    ///initalizer which sets the state of the help table based on the dictionary
    init?(dictionary: [String:String]) {
        
        ///initalize the properties of the profile
        self.appFeatures = dictionary["appFeatures"]
        self.helpSection = dictionary["helpSection"]
        self.howWellDoesClewWork = dictionary["howWellDoesClewWork"]
        self.recordingARoute = dictionary["recordingARoute"]
        self.stoppingARecording = dictionary["stoppingARecording"]
        self.pausingARouteOrRecordingALandmark = dictionary["pausingARouteOrRecordingALandmark"]
        self.resumingARoute = dictionary["resumingARoute"]
        self.theSavedRoutesMenu = dictionary["theSavedRoutesMenu"]
        self.followingARoute = dictionary["followingARoute"]
        self.appSoundsAndTheirMeanings = dictionary["appSoundsAndTheirMeanings"]
        self.ratingYourNavigationExperience = dictionary["ratingYourNavigationExperience"]
        self.providingFeedbackToTheDevelopmentTeam = dictionary["providingFeedbackToTheDevelopmentTeam"]

    }
}
