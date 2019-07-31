//
//  DataPersistance.swift
//  Clew
//
//  Created by Khang Vu on 3/14/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import ARKit

/// This class handles saving and loading routes.
/// TODO: make this a singleton
class DataPersistence {
    
    /// The list of routes.  This should not be modified directly to avoid divergence of this object from the data that is stored persistently.
    var routes = [SavedRoute]()

    /// Create the object by loading the saved routes from the URL returned by getRoutesURL()
    init() {
        do {
            // if anything goes wrong with the unarchiving, stick with an emptly list of routes
            let data = try Data(contentsOf: getRoutesURL())
            if let routes = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [SavedRoute] {
                self.routes = routes
            }
        } catch {
            print("couldn't unarchive saved routes")
        }
    }
    
    /// Save the specified route with the optional ARWorldMap.  The variable class attribute routes will automatically be updated by this function.
    ///
    /// - Parameters:
    ///   - route: the route to save
    ///   - worldMapAsAny: an optional ARWorldMap.  The Any? type is used to allow for backward compatibility with iOS 11.3
    /// - Throws: an error if the route could not be saved
    func archive(route: SavedRoute, worldMapAsAny: Any?) throws {
        // Save route to the route list
        if !update(route: route) {
            self.routes.append(route)
        }
        let data = try NSKeyedArchiver.archivedData(withRootObject: self.routes, requiringSecureCoding: true)
        try data.write(to: self.getRoutesURL(), options: [.atomic])
        // Save the world map corresponding to the route
        if #available(iOS 12.0, *) {
            if let worldMapAsAny = worldMapAsAny {
                let data = try NSKeyedArchiver.archivedData(withRootObject: worldMapAsAny, requiringSecureCoding: true)
                try data.write(to: self.getWorldMapURL(id: route.id as String), options: [.atomic])
            }
        }
    }
    
    /// handler for importing routes from an external temporary file
    /// called in the case of a route being shared from the UIActivityViewController
    /// library
    static func importData(from url: URL) {
        /// attempt to fetch data from temporary import from external source
        /// TODO: convert to a NSSecureCoding Decoding object instead of plain writing the data to the file.
        guard
            let savedArray = try? NSArray(contentsOf: url as URL) as! [[Any]]
            else { return }
        
        /// add to the saved route list here
        
        /// remove from temp storage the file gets automatically placed into
        /// otherwise the file sticks there and won't be deleted automatically,
        /// causing app bloat.
        try? FileManager.default.removeItem(at: url)
    }
    
    /// handler for exporting routes to a external temporary file
    /// called in the case of a route being shared from the UIActivityViewController
    /// library
    func exportToURL(route: SavedRoute) -> URL? {
        /// fetch the world map if it exists
        /// is this legal given that unarchiveMap can be nil
        let worldMap = self.unarchiveMap(id: route.id as String)
        
        /// aggregated file data
        /// assemble object we want to write, (all route info with world map)
        /// voice note data is contained in the landmark crumbs
        /// TODO: convert to a NSSecureCoding Encoded object instead of plain writing the data to the file.
        let sharedData = [[route.name, route.id, route.crumbs, route.dateCreated,route.beginRouteLandmark, route.endRouteLandmark, worldMap]]
        
        /// fetch the documents directory where apple stores temp files
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
            ).first
        
        /// set temp path as name of route
        /// will be sent via the share menu
        guard let path = documents?.appendingPathComponent("/\(route.name).crd") else {
            return nil
        }
        
        /// write route to file
        /// and return the path of the created temp file
        /// TODO: error handling with NSArrays?
        do {
            (sharedData as NSArray).write(to: path as URL, atomically: true)
//            try (routeData as NSArray).write(to: path as URL, atomically: true)
            return path
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    /// Load the map from the app's local storage.  If we are on a platform that doesn't support ARWorldMap, this function always returns nil
    ///
    /// - Parameter id: the map id to fetch
    /// - Returns: the stored map as Any?
    func unarchiveMap(id: String) -> Any? {
        if #available(iOS 12.0, *) {
            do {
                let data = try Data(contentsOf: getWorldMapURL(id: id))
                guard let unarchivedObject = ((try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)) as ARWorldMap??),
                    let worldMap = unarchivedObject else { return nil }
                return worldMap
            } catch {
                print("Error retrieving world map data.")
                return nil
            }
        } else {
            return nil
        }
    }
    
    /// Update the specified route.
    ///
    /// - Parameter route: the route to update
    /// - Returns: true if the route was updated successfully, false if the route could not be found in the routes list
    func update(route: SavedRoute) -> Bool {
        /// Updates the route in the list based on matching ids.  The return value is true if the route was found and updates and false otherwise from the route list
        if let indexOfRoute = routes.firstIndex(where: {$0.id == route.id || $0.name == route.name }) {
            routes[indexOfRoute] = route
            return true
        }
        return false
    }
    
    /// Delete the specified route
    ///
    /// - Parameter route: the route do delete
    /// - Throws: an error if deletion cannot be performed
    func delete(route: SavedRoute) throws {
        // Remove route from the route list
        self.routes = self.routes.filter { $0.id != route.id }
        let data = try NSKeyedArchiver.archivedData(withRootObject: self.routes, requiringSecureCoding: true)
        try data.write(to: self.getRoutesURL(), options: [.atomic])
        // Remove the world map corresponding to the route.  We use try? to continue execution even if this fails, since it is not strictly necessary for continued operation
        try? FileManager().removeItem(atPath: self.getWorldMapURL(id: route.id as String).path)
        if let beginRouteLandmarkVoiceNote = route.beginRouteLandmark.voiceNote {
            try? FileManager().removeItem(at: beginRouteLandmarkVoiceNote.documentURL)
        }
        if let endRouteLandmarkVoiceNote = route.endRouteLandmark.voiceNote {
            try? FileManager().removeItem(at: endRouteLandmarkVoiceNote.documentURL)
        }
    }
    
    /// A utility method to map a file name into a URL in the app's document directory.
    ///
    /// - Parameter filename: the filename that should be converted to a URL
    /// - Returns: A URL to the filename within the document directory of the app
    private func getURL(filename: String) -> URL {
        return FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(filename)
    }
    
    /// Returns the URL used to persist the ARWorldMap corresponding to the specified route id.
    ///
    /// - Parameter id: the id of the route
    /// - Returns: the URL used to store the ARWorldMap for the route
    private func getWorldMapURL(id: String) -> URL {
        return getURL(filename: id)
    }
    
    /// Returns URL at which to store the file that contains the routes.  The ARWorldMap object are stored elsewhere.
    ///
    /// - Returns: the URL of the routes file
    private func getRoutesURL() -> URL {
        return getURL(filename: "routeList")
    }
    
}
