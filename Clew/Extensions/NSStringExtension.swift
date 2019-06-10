//
//  NSStringExtension.swift
//  Clew
//
//  Created by Dieter Brehm on 6/4/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation

extension NSString {
    /// the URL associated in the document directory associated with the particular NSString (note: this is non-sensical for some NSStrings).
    var documentURL: URL {
        return FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(self as String)
    }
}
