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
    case attribute
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
        //if there is an attributes section
        let attributes = helpTable.helpAttributes
        if !attributes.isEmpty {
            //set up the attributes section
            let attributesItem = HelpViewModelAttributeItem(attributes: attributes)
            items.append(attributesItem)
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
        ///depending on the section return a different type of cell
        switch item.type {
        case .about:
            if let cell = tableView.dequeueReusableCell(withIdentifier: AboutCell.identifier, for: indexPath) as? AboutCell {
                cell.item = item
                return cell
            }
        case .attribute:
            if let item = item as? HelpViewModelAttributeItem, let cell = tableView.dequeueReusableCell(withIdentifier: AttributeCell.identifier, for: indexPath) as? AttributeCell {
                cell.item = item.attributes[indexPath.row]
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

class HelpViewModelAttributeItem: HelpViewModelItem {
    
    var type: HelpViewModelItemType {
        return .attribute
    }
    
    var sectionTitle: String {
        return "Attributes"
    }
    
    var rowCount: Int {
        return attributes.count
    }
    
    var isCollapsed = true
    
    var attributes: [Attribute]
    
    init(attributes: [Attribute]) {
        self.attributes = attributes
    }
}
