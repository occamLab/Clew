//
//  JSONParser.swift
//  Clew
//
//  Created by Timothy Novak on 6/14/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation

public func dataFromFile(_ filename: String) -> Data? {
    @objc class TestClass: NSObject { }
    let bundle = Bundle(for: TestClass.self)
    if let path = bundle.path(forResource: filename, ofType: "json") {
        return (try? Data(contentsOf: URL(fileURLWithPath: path)))
    }
    return nil
}

class Profile {
    var fullName: String?
    var pictureUrl: String?
    var email: String?
    var about: String?
    var friends = [Friend]()
    var profileAttributes = [Attribute]()
}
class Friend {
    var name: String?
    var pictureUrl: String?
}
class Attribute {
    var key: String?
    var value: String?
}
