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
        title = NSLocalizedString("savedRoutesListPop-UpHeading", comment: "The title to a list of routes that have been saved by the user.")
    }
    
    /// Called when the user selects an element from the routes table.
    ///
    /// - Parameters:
    ///   - tableView: the table view
    ///   - indexPath: the path that was selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        // Set title and message for the alert dialog
        let alertController = UIAlertController(title: NSLocalizedString("routeDirectionPop-UpHeader", comment: "The header of a pop-up where the user selects which direction they want to navigate their route"), message: "", preferredStyle: .actionSheet)
        let cellRect = tableView.rectForRow(at: indexPath)
        alertController.popoverPresentationController?.sourceView = tableView
        alertController.popoverPresentationController?.sourceRect = cellRect
        alertController.popoverPresentationController?.permittedArrowDirections  = UIPopoverArrowDirection.any

        // The confirm action taking the inputs
        let startToEndAction = UIAlertAction(title: NSLocalizedString("routeDirectionStartToEndButtonLabel", comment: "The text on a button in the select navigational direction menu of the app. This button allows the user to navigate a route in the same direction as it was originally recorded."), style: .default) { (_) in
            self.rootViewController?.onRouteTableViewCellClicked(route: self.routes[indexPath.row], navigateStartToEnd: true)
            self.dismiss(animated: true, completion: nil)
        }
        if routes[indexPath.row].beginRouteAnchorPoint.anchor?.transform == nil {
            startToEndAction.isEnabled = false
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancelPop-UpButtonLabel", comment: "A button which closes the current pop up"), style: .default) {action -> Void in
        }
        
        self.routes[indexPath.row].beginRouteAnchorPoint.loadImage()
        self.routes[indexPath.row].endRouteAnchorPoint.loadImage()
        var beginImageThumbnail: UIImage?
        var endImageThumbnail: UIImage?
        if let beginImage = self.routes[indexPath.row].beginRouteAnchorPoint.image {
            let imageHeight = CGFloat(100)
            let imageWidth = beginImage.size.width * imageHeight / beginImage.size.height
            beginImageThumbnail = beginImage.imageWithSize(scaledToSize: CGSize(width: imageWidth, height: imageHeight))
        }
        if let endImage = self.routes[indexPath.row].endRouteAnchorPoint.image {
            let imageHeight = CGFloat(100)
            let imageWidth = endImage.size.width * imageHeight / endImage.size.height
            endImageThumbnail = endImage.imageWithSize(scaledToSize: CGSize(width: imageWidth, height: imageHeight))
        }

        startToEndAction.setValue(beginImageThumbnail?.rotate(radians: Float.pi/2)?.withRenderingMode(.alwaysOriginal), forKey: "image")
        if routes[indexPath.row].beginRouteAnchorPoint.anchor?.transform == nil {
            startToEndAction.isEnabled = false
        }
        
        let endToStartAction = UIAlertAction(title: NSLocalizedString("routeDirectionEndToStartButtonLabel", comment: "The text on a button in the select navigational direction menu of the app. This button allows the user to navigate a route in the opposite direction as it was originally recorded."), style: .default) { (_) in
            self.rootViewController?.onRouteTableViewCellClicked(route: self.routes[indexPath.row], navigateStartToEnd: false)
            self.dismiss(animated: true, completion: nil)
        }
        endToStartAction.setValue(endImageThumbnail?.rotate(radians: Float.pi/2)?.withRenderingMode(.alwaysOriginal), forKey: "image")
        
        if routes[indexPath.row].endRouteAnchorPoint.anchor?.transform == nil {
            endToStartAction.isEnabled = false
        }
        
        // Add the action to dialogbox
        alertController.addAction(startToEndAction)
        alertController.addAction(endToStartAction)
        alertController.addAction(cancelAction)
        
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
        
        let delete = UITableViewRowAction(style: .destructive, title: NSLocalizedString("deleteActionText", comment: "This is the text that appears when a user tries to delete a saved route. This text is used in an option menu when a route is selected and it describes the action for deleting a route.")) { (action, indexPath) in
            
            let confirmAlert = UIAlertController(title: NSLocalizedString("deleteActionText", comment: "This is the text that appears when a user tries to delete a saved route. This text is used in an option menu when a route is selected and it describes the action for deleting a route."), message: NSLocalizedString("confirmDeletion", comment: "this is the text that asks the user if they are sure they want to delete the route"), preferredStyle: .alert)

            confirmAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                
                // delete item at indexPath
                do {
                    try self.rootViewController?.dataPersistence.delete(route: self.routes[indexPath.row])
                    self.routes.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                } catch {
                    print("Unexpectedly failed to persist the new routes data")
                }
            }))

            confirmAlert.addAction(UIAlertAction(title: NSLocalizedString("cancelPop-UpButtonLabel", comment: "A button which closes the current pop up"), style: .cancel, handler: { (action: UIAlertAction!) in
              
              }))

            self.present(confirmAlert, animated: true, completion: nil)
        }
        
        let share = UITableViewRowAction(style: .normal, title: NSLocalizedString("shareActionText", comment: "This is the text that appears when a user tries to share a saved route. This text is used in an option menu when a route is selected and it describes the action for share a route.")) { (action, indexPath) in
            /// share item
            let url = self.rootViewController?.dataPersistence.exportToURL(route: self.routes[indexPath.row])
            
            /// define share menu content and a message to show with it
            let activity = UIActivityViewController(
                activityItems: [NSLocalizedString("automaticEmailTextWhenSharingRoutes", comment: "The text added to an email for sharing routes."), url as Any],
                applicationActivities: nil
            )

            /// show the share menu
            self.present(activity, animated: true, completion: nil)
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
