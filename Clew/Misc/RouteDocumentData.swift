//
//  RouteDocumentData.swift
//  Clew
//
//  Created by Dieter Brehm on 7/31/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

/// class for handling the selection of data to be stored in UIActivityShare Menus
@available(iOS 12.0, *)
class RouteDocumentData: NSObject, NSCoding {
    /// This is needed to use NSSecureCoding
    static var supportsSecureCoding = true
    
    /// the main route itself
    public var route: SavedRoute
    
    /// the world map
    public var map: ARWorldMap
    
    /// Initialize the sharing document.
    ///
    /// - Parameters:
    ///   - route: the route data
    ///   - map: the arkit world map
    public init(route: SavedRoute, map: ARWorldMap) {
        self.route = route
        self.map = map
    }
    
    /// Encodes the object to the specified coder object
    ///
    /// - Parameter aCoder: the object used for encoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(route, forKey: "route")
        aCoder.encode(map, forKey: "map")
    }
    
    /// Initialize an object based using data from a decoder
    ///
    /// - Parameter aDecoder: the decoder object
    required convenience init?(coder aDecoder: NSCoder) {
        guard let route = aDecoder.decodeObject(of: SavedRoute.self, forKey: "route") else {
            return nil
        }
        guard let map = aDecoder.decodeObject(of: ARWorldMap.self, forKey: "map") else {
            return nil
        }
        self.init(route: route, map: map)
    }
}
