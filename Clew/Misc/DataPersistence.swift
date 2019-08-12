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
    ///   - worldMap: an optional ARWorldMap to associate with the route
    /// - Throws: an error if the route could not be saved
    func archive(route: SavedRoute, worldMap: ARWorldMap?) throws {
        // Save route to the route list
        if !update(route: route) {
            self.routes.append(route)
        }
        let data = try NSKeyedArchiver.archivedData(withRootObject: self.routes, requiringSecureCoding: true)
        try data.write(to: self.getRoutesURL(), options: [.atomic])
        // Save the world map corresponding to the route
        if let worldMap = worldMap {
            let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
            try data.write(to: self.getWorldMapURL(id: route.id as String), options: [.atomic])
        }
    }
    
    /// Load the map from the app's local storage.  If we are on a platform that doesn't support ARWorldMap, this function always returns nil
    ///
    /// - Parameter id: the map id to fetch
    /// - Returns: the stored map
    func unarchiveMap(id: String) -> ARWorldMap? {
        do {
            let data = try Data(contentsOf: getWorldMapURL(id: id))
            guard let unarchivedObject = ((try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)) as ARWorldMap??),
                let worldMap = unarchivedObject else { return nil }
            return worldMap
        } catch {
            print("Error retrieving world map data.")
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
        if let beginRouteAnchorPointVoiceNote = route.beginRouteAnchorPoint.voiceNote {
            try? FileManager().removeItem(at: beginRouteAnchorPointVoiceNote.documentURL)
        }
        if let endRouteAnchorPointVoiceNote = route.endRouteAnchorPoint.voiceNote {
            try? FileManager().removeItem(at: endRouteAnchorPointVoiceNote.documentURL)
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
