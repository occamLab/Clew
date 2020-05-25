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
/// This wrapping functionality is required to that we can have all elements related
/// to a specific route stored in a single encoded file ready to be shared throughout
/// iOS
class RouteDocumentData: NSObject, NSSecureCoding {
    /// This is needed to use NSSecureCoding
    static var supportsSecureCoding = true
    
    /// the main route itself
    public var route: SavedRoute
    
    /// the world map
    public var map: Any?
    
    /// first landmark audio note
    public var beginVoiceNote: String?
    
    /// second landmark audio note
    public var endVoiceNote: String?
    
    /// Initialize the sharing document.
    ///
    /// - Parameters:
    ///   - route: the route data
    ///   - map: the arkit world map
    public init(route: SavedRoute, map: Any? = nil, beginVoiceNote: String? = nil, endVoiceNote: String? = nil) {
        self.route = route
        self.map = map
        self.beginVoiceNote = beginVoiceNote
        self.endVoiceNote = endVoiceNote
    }
    
    /// Encodes the object to the specified coder object. Here, we combine each essential element
    /// of a saved route to a single file, encoding each of them with a key known to clew so that we
    /// can handle decoding later.
    /// - Parameter aCoder: the object used for encoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(route, forKey: "route")
        aCoder.encode(map, forKey: "map")
        aCoder.encode(beginVoiceNote as NSString?, forKey: "beginVoiceNote")
        aCoder.encode(endVoiceNote as NSString?, forKey: "endVoiceNote")
    }
    
    /// Initialize an object based using data from a decoder.
    /// (Begin reconstruction of a saved route from a crd file)
    /// - Parameter aDecoder: the decoder object
    required convenience init?(coder aDecoder: NSCoder) {
        /// use a guard for decoding route as we know that it cannot be nil
        guard let route = aDecoder.decodeObject(of: SavedRoute.self, forKey: "route") else {
            return nil
        }
        
        /// decode map, beginning landmark voice note, and ending landmark voice note,
        /// knowing that the map may not necessarily exist
        var newMap: Any? = nil
        
        if #available(iOS 12.0, *) {
            newMap = aDecoder.decodeObject(of: ARWorldMap.self, forKey: "map")
        }

        let beginNote = aDecoder.decodeObject(of: NSString.self, forKey: "beginVoiceNote")
        let endNote = aDecoder.decodeObject(of: NSString.self, forKey: "endVoiceNote")
        
        /// construct a new saved route from the decoded data
        self.init(route: route, map: newMap, beginVoiceNote: beginNote as String?, endVoiceNote: endNote as String?)
    }
}
