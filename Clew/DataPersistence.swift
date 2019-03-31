//
//  DataPersistance.swift
//  Clew
//
//  Created by Khang Vu on 3/14/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import ARKit

@available(iOS 12.0, *)
class DataPersistence {
    
    var routes = [SavedRoute]()

    init() {
        guard let newRoutes = NSKeyedUnarchiver.unarchiveObject(withFile: self.getRoutesURL().path) as? [SavedRoute] else {return}
        self.routes = newRoutes
    }
    
    func archive(route: SavedRoute, worldMap: ARWorldMap) throws {
        // Save route to the route list
        if try !update(route: route) {
            self.routes.append(route)
            NSKeyedArchiver.archiveRootObject(self.routes, toFile: self.getRoutesURL().path)
        }
        // Save the world map corresponding to the route
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        try data.write(to: self.getWorldMapURL(id: route.id as String), options: [.atomic])
    }
    
    @available(iOS 12.0, *)
    func unarchive(id: String) -> ARWorldMap? {
        do {
            let data = try Data(contentsOf: getWorldMapURL(id: id))
            guard let unarchivedObject = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data),
                let worldMap = unarchivedObject else { return nil }
            return worldMap
        } catch {
            print("Error retrieving world map data.")
            return nil
        }
    }
    
    func update(route: SavedRoute) throws -> Bool {
        /// Updates the route in the list based on matching ids.  The return value is route from the route list
        if let indexOfRoute = routes.firstIndex(where: {$0.id == route.id || $0.name == route.name }) {
            routes[indexOfRoute] = route
            NSKeyedArchiver.archiveRootObject(self.routes, toFile: self.getRoutesURL().path)
            return true
        }
        return false
    }
    
    func delete(route: SavedRoute) throws {
        // Remove route from the route list
        self.routes = self.routes.filter { $0.id != route.id }
        NSKeyedArchiver.archiveRootObject(self.routes, toFile: self.getRoutesURL().path)
        // Remove the world map corresponding to the route
        try FileManager().removeItem(atPath: self.getWorldMapURL(id: route.id as String).path)
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
