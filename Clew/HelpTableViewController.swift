//
//  HelpTableViewController.swift
//  Clew
//
//  Created by tad on 6/13/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation

class HelpTableViewController: UIViewController,UITableViewDelegate {
    
    //loads the view
    override func viewDidLoad() {
        
        super.viewDidLoad()

    }
    //MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    
    
    //loads the UI programatically (not used currently)
    private func loadUI() {
        
        let margines = view.layoutMarginsGuide
        
        ///declare the table view
        var tableView: UITableView  = UITableView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), style: UITableView.Style.plain)
        ///assign the constraints
        tableView.leadingAnchor.constraint(equalTo:margines.leadingAnchor)
        tableView.trailingAnchor.constraint(equalTo:margines.trailingAnchor)
        tableView.topAnchor.constraint(equalTo:margines.topAnchor)
        tableView.bottomAnchor.constraint(equalTo:margines.bottomAnchor)
        tableView.backgroundColor = UIColor(red: 1, green: 0, blue: 1, alpha: 1)
    }
    
    /// This is called when the view should close.  This method posts a notification "ClewPopoverDismissed" that can be listened to if an object needs to know that the view is being closed.
    @objc func doneWithHelp() {
        dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: Notification.Name("ClewPopoverDismissed"), object: nil)
    }
    
}
