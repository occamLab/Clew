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
    case about
    case appFeatures
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
        guard let data = dataFromFile("ServerData"), let helpTable = HelpTable(data: data) else {
            return
        }
        ///if there is an about section
        if let about = helpTable.about {
            ///set up the abbout section
            let aboutItem = HelpViewModelAboutItem(about: about)
            items.append(aboutItem)
        }
        ///if there is an appFeatures section
        if let appFeatures = helpTable.appFeatures {
            ///set up the abbout section
            let appFeaturesItem = HelpViewModelAppFeaturesItem(appFeatures: appFeatures)
            items.append(appFeaturesItem)
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
        case .about:
            if let cell = tableView.dequeueReusableCell(withIdentifier: AboutCell.identifier, for: indexPath) as? AboutCell {
                cell.item = item
                return cell
            }
        case .appFeatures:
            if let item = item as? HelpViewModelAppFeaturesItem, let cell = tableView.dequeueReusableCell(withIdentifier: AppFeaturesCell.identifier, for: indexPath) as? AppFeaturesCell {
                cell.item = item
                return cell
            }
        default:
            print("hello")
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
///creates an about section
class HelpViewModelAboutItem: HelpViewModelItem {
    
    ///sets the type
    var type: HelpViewModelItemType {
        return .about
    }
    
    ///sets the name of the section
    var sectionTitle: String {
        return "About"
    }
    
    ///sets whether or not it is collapseable
    var isCollapsible: Bool {
        return true
    }
    
    ///sets the state to be collapsed
    var isCollapsed = true
    
    ///sets the text value
    var about: String
    init(about: String) {
        self.about = about
    }
}
///creates an appFeatures section
class HelpViewModelAppFeaturesItem: HelpViewModelItem {
    
    ///sets the type
    var type: HelpViewModelItemType {
        return .appFeatures
    }
    
    ///sets the name of the section
    var sectionTitle: String {
        return "AppFeatures"
    }
    
    ///sets whether or not it is collapseable
    var isCollapsible: Bool {
        return true
    }
    
    ///sets the state to be collapsed
    var isCollapsed = true
    
    ///sets the text value
    var appFeatures: String
    init(appFeatures: String) {
        self.appFeatures = appFeatures
    }
}
