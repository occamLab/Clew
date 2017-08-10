//
//  Utility.swift
//  BreadCrumbsTest
//
//  Created by Chris Seonghwan Yoon on 8/3/17.
//  Copyright © 2017 OccamLab. All rights reserved.
//

import Foundation

func roundToTenths(_ n: Float) -> Float {
    return roundf(10 * n)/10
}

func roundToThousandths(_ n: Double) -> Double {
    return round(1000 * n)/1000
}

func round10k(_ n: Float) -> Float {
    // round Float to then-thousandths
    return roundf(10000 * n)/10000
}

