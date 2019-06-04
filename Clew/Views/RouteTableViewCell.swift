//
//  RouteTableViewCell.swift
//  Clew
//
//  Created by Khang Vu on 2/25/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit

/// A table cell that holds the route data
class RouteTableViewCell: UITableViewCell {

    /// The route label (i.e. the name)
    @IBOutlet weak var nameLabel: UILabel!
    /// The route creation date
    @IBOutlet weak var dateCreatedLabel: UILabel!
}
