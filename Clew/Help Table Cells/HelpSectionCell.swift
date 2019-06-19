//
//  HelpSectionCell.swift
//  Clew
//
//  Created by tad on 6/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import UIKit

class HelpSectionCell: UITableViewCell {
    
    @IBOutlet weak var informationLabel: UILabel!
    
    
    var item: HelpViewModelItem? {
        didSet {
            guard  let item = item as? HelpViewModelHelpSectionItem else {
                return
            }
            
            informationLabel?.text = item.helpSection
        }
    }
    
    static var nib:UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
}
