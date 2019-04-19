//
//  DataPersistance.swift
//  Clew
//
//  Created by Khang Vu on 3/14/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import ARKit

class DataPersistence {
    
    var routes = [SavedRoute]()

    init() {
        do {
            // if anything goes wrong with the unarchiving, stick with an emptly list of routes
            let data = try Data(contentsOf: self.getRoutesURL())
            if let routes = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [SavedRoute] {
                self.routes = routes
            }
        } catch {
            print("couldn't unarchive saved routes")
        }
    }
    
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
    
    func update(route: SavedRoute) -> Bool {
        /// Updates the route in the list based on matching ids.  The return value is true if the route was found and updates and false otherwise from the route list
        if let indexOfRoute = routes.firstIndex(where: {$0.id == route.id || $0.name == route.name }) {
            routes[indexOfRoute] = route
            return true
        }
        return false
    }
    
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
    
    private func getURL(url: String) -> URL {
        return FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(url)
    }
    
    private func getWorldMapURL(id: String) -> URL {
        return getURL(url: id)
    }
    
    private func getRoutesURL() -> URL {
        return getURL(url: "routeList")
    }
    
}
