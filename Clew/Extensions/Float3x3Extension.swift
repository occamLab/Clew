//
//  Float3x3Extension.swift
//  Clew
//
//  Created by Kawin Nikomborirak on 7/25/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation

extension float3x3 {
    func toString()->String {
        return """
        \(self[0, 0]),\(self[1, 0]),\(self[2, 0])
        \(self[0, 1]),\(self[1, 1]),\(self[2, 1])
        \(self[0, 2]),\(self[1, 2]),\(self[2, 2])
        """
    }
}
