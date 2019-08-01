//
//  RoutesViewController.swift
//  Clew
//
//  Created by Khang Vu on 2/22/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import WebKit
import ARKit

/// The view controller that handles the saved routes view
class RoutesViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    /// The table that displays the routes
    @IBOutlet weak var tableView: UITableView!
    /// A handle back to the root view controller so that relevant events can be communicated back to the root
    var rootViewController: ViewController?
    /// The routes to display
    var routes = [SavedRoute]()
    
    /// When the view loads, the table view is populated and the title of the view is set.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        title = NSLocalizedString("Saved Routes List", comment: "The title to a list of routes that have been saved by the user.")
    }
    
    /// Called when the user selects an element from the routes table.
    ///
    /// - Parameters:
    ///   - tableView: the table view
    ///   - indexPath: the path that was selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        // Set title and message for the alert dialog
        let alertController = UIAlertController(title: NSLocalizedString("Route direction", comment: "The header of a pop-up"), message: "", preferredStyle: .alert)
        // The confirm action taking the inputs
        let startToEndAction = UIAlertAction(title: NSLocalizedString("Start to End", comment: "Option for user to select"), style: .default) { (_) in
            self.rootViewController?.onRouteTableViewCellClicked(route: self.routes[indexPath.row], navigateStartToEnd: true)
            self.dismiss(animated: true, completion: nil)
        }
        if routes[indexPath.row].beginRouteLandmark.transform == nil {
            startToEndAction.isEnabled = false
        }
        
        let endToStartAction = UIAlertAction(title: NSLocalizedString("End to Start", comment: "Option for user to select"), style: .default) { (_) in
            self.rootViewController?.onRouteTableViewCellClicked(route: self.routes[indexPath.row], navigateStartToEnd: false)
            self.dismiss(animated: true, completion: nil)
        }
        if routes[indexPath.row].endRouteLandmark.transform == nil {
            endToStartAction.isEnabled = false
        }
        
        // Add the action to dialogbox
        alertController.addAction(startToEndAction)
        alertController.addAction(endToStartAction)
        
        // Finally, present the dialog box
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// Called when the routes table is being populated
    ///
    /// - Parameters:
    ///   - tableView: the table being populated
    ///   - indexPath: the index path of the route whose data should be loaded
    /// - Returns: a cell that contains the route
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("yyyy-MM-dd HH:mm:ss")
        let cell = tableView.dequeueReusableCell(withIdentifier: "clew.RouteTableViewCell", for: indexPath) as! RouteTableViewCell
        cell.nameLabel.text = routes[indexPath.row].name as String
        cell.dateCreatedLabel.text = df.string(from: routes[indexPath.row].dateCreated as Date)
        return cell
    }
    
    /// Called when user performs an edit action on the row.  Currently, only delete is supported.
    ///
    /// - Parameters:
    ///   - tableView: a handle to the routes table
    ///   - indexPath: the path to the route being modified
    /// - Returns: a list of actions that were performed.
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            /// delete item at indexPath
            do {
                try self.rootViewController?.dataPersistence.delete(route: self.routes[indexPath.row])
                self.routes.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            } catch {
                print("Unexpectedly failed to persist the new routes data")
            }
        }
        
        let share = UITableViewRowAction(style: .normal, title: "Share") { (action, indexPath) in
            /// share item
            do {
                if #available(iOS 12.0, *) {
                    try self.rootViewController?.dataPersistence.exportToURL(route: self.routes[indexPath.row])
                } else {
                    // Fallback on earlier versions
                }
            } catch {
                print("well that didn't work!")
            }
        }
        return [delete, share]
        
    }
    
    /// The number of routes in the table (needed by `UITableViewDataSource`)
    ///
    /// - Parameters:
    ///   - tableView: the table view being managed
    ///   - section: the section (currently ignored)
    /// - Returns: the number of elements in the table view (i.e., the number of routes)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routes.count
    }
    
    /// Update the routes table, e.g., when the data is loaded from persistent storage.
    ///
    /// - Parameter routes: the new set of routes.
    func updateRoutes(routes: [SavedRoute]) {
        self.routes = routes.sorted(by: { $0.dateCreated as Date > $1.dateCreated as Date})
    }
    
    /// Called to dismiss the routes menu
    @objc func doneWithRoutes() {
        dismiss(animated: true, completion: nil)
    }
}
