//
//  ClewDelegateProtocol.swift
//  Clew
//
//  Created by OccamLab on 7/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation

protocol ClewDelegate : ClewObserver {
    func allowRouteRating()->Bool
}
