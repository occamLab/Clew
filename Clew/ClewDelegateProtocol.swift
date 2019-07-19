//
//  ClewDelegateProtocol.swift
//  Clew
//
//  Created by SCOPE on 7/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation

protocol ClewDelegate : ClewObserver {
    func allowRouteRating()->Bool
}
