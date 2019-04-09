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

class RoutesViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var rootViewController: ViewController?
    var routes = [SavedRoute]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        title = "Saved Routes List"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        // Set title and message for the alert dialog
        let alertController = UIAlertController(title: "Route direction", message: "", preferredStyle: .alert)
        // The confirm action taking the inputs
        let startToEndAction = UIAlertAction(title: "Start to End", style: .default) { (_) in
            self.rootViewController?.onRouteTableViewCellClicked(route: self.routes[indexPath.row], navigateStartToEnd: true)
            self.dismiss(animated: true, completion: nil)
        }
        if routes[indexPath.row].beginRouteLandmarkTransform == nil {
            startToEndAction.isEnabled = false
        }
        
        let endToStartAction = UIAlertAction(title: "End to Start", style: .default) { (_) in
            self.rootViewController?.onRouteTableViewCellClicked(route: self.routes[indexPath.row], navigateStartToEnd: false)
            self.dismiss(animated: true, completion: nil)
        }
        if routes[indexPath.row].endRouteLandmarkTransform == nil {
            endToStartAction.isEnabled = false
        }
        
        // Add the action to dialogbox
        alertController.addAction(startToEndAction)
        alertController.addAction(endToStartAction)
        
        // Finally, present the dialog box
        self.present(alertController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        print(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "clew.RouteTableViewCell", for: indexPath) as! RouteTableViewCell
        cell.nameLabel.text = routes[indexPath.row].name as String
        cell.dateCreatedLabel.text = df.string(from: routes[indexPath.row].dateCreated as Date)
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            // delete item at indexPath
            do {
                try self.rootViewController?.dataPersistence.delete(route: self.routes[indexPath.row])
                self.routes.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            } catch {
                print("Unexpectedly failed to persist the new routes data")
            }
        }
        return [delete]
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routes.count
    }
    
    func updateRoutes(routes: [SavedRoute]) {
        self.routes = routes.sorted(by: { $0.dateCreated as Date > $1.dateCreated as Date})
    }
    
    @objc
    func doneWithRoutes() {
        dismiss(animated: true, completion: nil)
    }
}
