//
//  HelpViewModel.swift
//  Clew
//
//  Created by tad on 6/18/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import UIKit

///describes what sections a profile can hold
enum HelpViewModelItemType {
    case appFeatures
    case helpSection
    case howWellDoesClewWork
    case recordingARoute
    case stoppingARecording
    case pausingARouteOrRecordingALandmark
    case resumingARoute
    case theSavedRoutesMenu
    case followingARoute
    case appSoundsAndTheirMeanings
    case ratingYourNavigationExperience
    case providingFeedbackToTheDevelopmentTeam
    
}

///describes one of the sections and its properties
protocol HelpViewModelItem {
    ///they have a type
    var type: HelpViewModelItemType { get }
    ///a designated section
    var sectionTitle: String { get }
    ///a number of cells that they have stored
    var rowCount: Int { get }
    ///a propertty which dictates whether or not they can collapse
    var isCollapsible: Bool { get }
    ///a property hich dictates whether or not they are collapsed
    var isCollapsed: Bool { get set }
}

///sets the default number of sub cells to one
extension HelpViewModelItem {
    var rowCount: Int {
        return 1
    }
    
    ///sets the default to a section which can be collapsed
    var isCollapsible: Bool {
        return true
    }
}

///creates a view model this handles the calculations and computations for the view but does not actually handle changing the view
class HelpViewModel: NSObject{
    
    //MARK: ProfileViewModel private variables
    var items = [HelpViewModelItem]()
    
    var reloadSections: ((_ section: Int) -> Void)?
    
    ///initializer
    override init() {
        ///calls defult behavior
        super.init()
        ///pulls the data from the file and initalizes a profile with that data
        guard let helpTable = HelpTable(dictionary: helpDictionary) else {
            return
        }
        ///if there is an helpSection section
//        if let helpSection = helpTable.helpSection {
//            ///set up the section
//            let helpSectionItem = HelpViewModelHelpSectionItem(helpSection: helpSection, sectionType: "HelpSection")
//            items.append(helpSectionItem)
//        }
        ///if there is an appFeatures section
        if let appFeatures = helpTable.appFeatures {
            ///set up the section
            let appFeaturesItem = HelpViewModelHelpSectionItem(helpSection: appFeatures, sectionType: "App Features")
            items.append(appFeaturesItem)
        }
        ///if there is an howWellDoesClewWork section
        if let howWellDoesClewWork = helpTable.howWellDoesClewWork {
            ///set up the section
            let howWellDoesClewWorkItem = HelpViewModelHelpSectionItem(helpSection: howWellDoesClewWork,sectionType: "How Well Does Clew Work")
            items.append(howWellDoesClewWorkItem)
        }
        ///if there is an recordingARoute section
        if let recordingARoute = helpTable.recordingARoute {
            ///set up the section
            let recordingARouteItem = HelpViewModelHelpSectionItem(helpSection: recordingARoute,sectionType: "Recording A Route")
            items.append(recordingARouteItem)
        }
        ///if there is an stoppingARecording section
        if let stoppingARecording = helpTable.stoppingARecording {
            ///set up the section
            let stoppingARecordingItem = HelpViewModelHelpSectionItem(helpSection: stoppingARecording,sectionType: "Stopping A Recording")
            items.append(stoppingARecordingItem)
        }
        ///if there is an pausingARouteOrRecordingALandmark section
        if let pausingARouteOrRecordingALandmark = helpTable.pausingARouteOrRecordingALandmark {
            ///set up the section
            let pausingARouteOrRecordingALandmarkItem = HelpViewModelHelpSectionItem(helpSection: pausingARouteOrRecordingALandmark,sectionType: "Pausing A Route Or Recording A Landmark")
            items.append(pausingARouteOrRecordingALandmarkItem)
        }
        ///if there is an resumingARoute section
        if let resumingARoute = helpTable.resumingARoute {
            ///set up the section
            let resumingARouteItem = HelpViewModelHelpSectionItem(helpSection: resumingARoute,sectionType: "Resuming A Route")
            items.append(resumingARouteItem)
        }
        ///if there is an theSavedRoutesMenu section
        if let theSavedRoutesMenu = helpTable.theSavedRoutesMenu {
            ///set up the section
            let theSavedRoutesMenuItem = HelpViewModelHelpSectionItem(helpSection: theSavedRoutesMenu,sectionType: "The Saved Routes Menu")
            items.append(theSavedRoutesMenuItem)
        }
        ///if there is an sfollowingARoute section
        if let followingARoute = helpTable.followingARoute {
            ///set up the section
            let followingARouteItem = HelpViewModelHelpSectionItem(helpSection: followingARoute,sectionType: "Following A Route")
            items.append(followingARouteItem)
        }
        ///if there is an ratingYourNavigationExperience section
        if let appSoundsAndTheirMeanings = helpTable.appSoundsAndTheirMeanings {
            ///set up the section
            let appSoundsAndTheirMeaningsItem = HelpViewModelHelpSectionItem(helpSection: appSoundsAndTheirMeanings,sectionType: "App Sounds And Their Meanings")
            items.append(appSoundsAndTheirMeaningsItem)
        }
        ///if there is an ratingYourNavigationExperience section
        if let ratingYourNavigationExperience = helpTable.ratingYourNavigationExperience {
            ///set up the section
            let ratingYourNavigationExperienceItem = HelpViewModelHelpSectionItem(helpSection: ratingYourNavigationExperience,sectionType: "Rating Your Navigation Experience")
            items.append(ratingYourNavigationExperienceItem)
        }
        ///if there is an providingFeedbackToTheDevelopmentTeam section
        if let providingFeedbackToTheDevelopmentTeam = helpTable.providingFeedbackToTheDevelopmentTeam {
            ///set up the section
            let providingFeedbackToTheDevelopmentTeamItem = HelpViewModelHelpSectionItem(helpSection: providingFeedbackToTheDevelopmentTeam,sectionType: "Providing Feedback To The Development Team")
            items.append(providingFeedbackToTheDevelopmentTeamItem)
        }

    }
}

extension HelpViewModel: UITableViewDataSource {
    ///returns the number of sections to generate based on the number of sections generated
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    ///returns the number of cells in a section based on the current state of the section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let item = items[section]
        ///if the section is not collapseable
        guard item.isCollapsible else {
            ///return the number of cells in the section
            return item.rowCount
        }
        ///if the section is collapsed it has no rows
        if item.isCollapsed {
            return 0
        } else {
            ///if the section is expanded it has the number of rows that it has
            return item.rowCount
        }
    }
    ///finds a cell at a location
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        ///grabs the path to look into
        let item = items[indexPath.section]
        ///depending on the section this creates a different type of cell
        switch item.type {
        case .appFeatures:
            if let item = item as? HelpViewModelHelpSectionItem, let cell = tableView.dequeueReusableCell(withIdentifier: HelpSectionCell.identifier, for: indexPath) as? HelpSectionCell {
                cell.section = indexPath.section
                cell.item = item
                return cell
            }
        case .helpSection:
            if let item = item as? HelpViewModelHelpSectionItem, let cell = tableView.dequeueReusableCell(withIdentifier: HelpSectionCell.identifier, for: indexPath) as? HelpSectionCell {
                cell.section = indexPath.section
                cell.item = item
                return cell
            }
        case .howWellDoesClewWork:
            if let item = item as? HelpViewModelHelpSectionItem, let cell = tableView.dequeueReusableCell(withIdentifier: HelpSectionCell.identifier, for: indexPath) as? HelpSectionCell {
                cell.section = indexPath.section
                cell.item = item
                return cell
            }
        case .recordingARoute:
            if let item = item as? HelpViewModelHelpSectionItem, let cell = tableView.dequeueReusableCell(withIdentifier: HelpSectionCell.identifier, for: indexPath) as? HelpSectionCell {
                cell.section = indexPath.section
                cell.item = item
                return cell
            }
        case .stoppingARecording:
            if let item = item as? HelpViewModelHelpSectionItem, let cell = tableView.dequeueReusableCell(withIdentifier: HelpSectionCell.identifier, for: indexPath) as? HelpSectionCell {
                cell.section = indexPath.section
                cell.item = item
                return cell
            }
        case .pausingARouteOrRecordingALandmark:
            if let item = item as? HelpViewModelHelpSectionItem, let cell = tableView.dequeueReusableCell(withIdentifier: HelpSectionCell.identifier, for: indexPath) as? HelpSectionCell {
                cell.section = indexPath.section
                cell.item = item
                return cell
            }
        case .resumingARoute:
            if let item = item as? HelpViewModelHelpSectionItem, let cell = tableView.dequeueReusableCell(withIdentifier: HelpSectionCell.identifier, for: indexPath) as? HelpSectionCell {
                cell.section = indexPath.section
                cell.item = item
                return cell
            }
        case .theSavedRoutesMenu:
            if let item = item as? HelpViewModelHelpSectionItem, let cell = tableView.dequeueReusableCell(withIdentifier: HelpSectionCell.identifier, for: indexPath) as? HelpSectionCell {
                cell.section = indexPath.section
                cell.item = item
                return cell
            }
        case .followingARoute:
            if let item = item as? HelpViewModelHelpSectionItem, let cell = tableView.dequeueReusableCell(withIdentifier: HelpSectionCell.identifier, for: indexPath) as? HelpSectionCell {
                cell.section = indexPath.section
                cell.item = item
                return cell
            }
        case .appSoundsAndTheirMeanings:
            if let item = item as? HelpViewModelHelpSectionItem, let cell = tableView.dequeueReusableCell(withIdentifier: HelpSectionCell.identifier, for: indexPath) as? HelpSectionCell {
                cell.section = indexPath.section
                cell.item = item
                return cell
            }
        case .ratingYourNavigationExperience:
            if let item = item as? HelpViewModelHelpSectionItem, let cell = tableView.dequeueReusableCell(withIdentifier: HelpSectionCell.identifier, for: indexPath) as? HelpSectionCell {
                cell.section = indexPath.section
                cell.item = item
                return cell
            }
        case .providingFeedbackToTheDevelopmentTeam:
            if let item = item as? HelpViewModelHelpSectionItem, let cell = tableView.dequeueReusableCell(withIdentifier: HelpSectionCell.identifier, for: indexPath) as? HelpSectionCell {
                cell.section = indexPath.section
                cell.item = item
                return cell
            }
        }
        ///return an empty cell
        return UITableViewCell()
    }
}
///generate a header for each section
extension HelpViewModel: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        /// creates a header
        if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderView.identifier) as? HeaderView {
            ///sets the section of the header
            let item = items[section]
            ///sets the state/text of the header
            headerView.item = item
            headerView.section = section
            headerView.delegate = self
            
            return headerView
        }
        return UIView()
    }
}

///describes what happens when a header is toggled
extension HelpViewModel: HeaderViewDelegate {
    func toggleSection(header: HeaderView, section: Int) {
        ///finds a section
        var item = items[section]
        ///if the section is collapseable
        if item.isCollapsible {
            
            // Toggle collapse
            let collapsed = !item.isCollapsed
            item.isCollapsed = collapsed
            header.setCollapsed(collapsed: collapsed)
            
            // Adjust the number of the rows inside the section
            reloadSections?(section)
        }
    }
}

//MARK: Creating types of sections

///creates a Generic Section section
class HelpViewModelHelpSectionItem: HelpViewModelItem {
    
    ///sets the type
    var type: HelpViewModelItemType {
        return .helpSection
    }
    
    ///sets the name of the section
    var sectionTitle: String
    
    ///sets whether or not it is collapseable
    var isCollapsible: Bool {
        return true
    }
    
    ///sets the state to be collapsed
    var isCollapsed = true
    
    ///sets the text value
    var helpSection: String
    init(helpSection: String,sectionType: String) {
        self.helpSection = helpSection
        self.sectionTitle = sectionType
    }
}
