//
//  DataPersistance.swift
//  Clew
//
//  Created by Khang Vu on 3/14/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import Foundation
import ARKit
import Firebase

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
    func archive(route: SavedRoute, worldMap: Any?) throws {
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
    
    func importData(withData data: Data) {
        // TODO: Do this same setClass thing for Clew documents
        #if APPCLIP
        let className: String = "Clew_More"
        #else
        let className: String = "Clew_Dev"
        #endif
        
        NSKeyedUnarchiver.setClass(RouteDocumentData.self, forClassName: "\(className).RouteDocumentData")
        NSKeyedUnarchiver.setClass(SavedRoute.self, forClassName: "\(className).SavedRoute")
        NSKeyedUnarchiver.setClass(LocationInfo.self, forClassName: "\(className).LocationInfo")
        NSKeyedUnarchiver.setClass(RouteAnchorPoint.self, forClassName: "\(className).RouteAnchorPoint")

        var documentData: RouteDocumentData
        
        /// attempt to fetch data from temporary import from external source
        do {
            print("attempting unarchive")
            // if anything goes wrong with the unarchiving, stick with an emptly list of routes
            print("this is the data: ")
            print(data.description)
            print("that was the data! ")
            if let document = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? RouteDocumentData {
                documentData = document
                
                /// save into the route storage
                print("name of import route:", documentData.route.name)
                
                do {
                    try archive(route: documentData.route, worldMap: documentData.map)
                } catch {
                    print("failed to archive import route")
                }
                
                if let beginNote = documentData.beginVoiceNote {
                    let voiceData = Data(base64Encoded: beginNote)
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let path = documentData.route.beginRouteAnchorPoint.voiceNote! as String
                    let url = documentsDirectory.appendingPathComponent(path)
                    do {
                        try voiceData?.write(to: url)
                    } catch {
                        print("couldn't write file")
                    }
                }
                
                if let endNote = documentData.endVoiceNote {
                    let voiceData = Data(base64Encoded: endNote)
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let path = documentData.route.endRouteAnchorPoint.voiceNote! as String
                    let url = documentsDirectory.appendingPathComponent(path)
                    do {
                        try voiceData?.write(to: url)
                    } catch {
                        print("couldn't write file")
                    }
                }
                
                for (i, voiceNote) in documentData.routeVoiceNotes.enumerated() {
                    let voiceData = Data(base64Encoded: voiceNote as String)
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let path = documentData.route.intermediateAnchorPoints[i].voiceNote! as String
                    let url = documentsDirectory.appendingPathComponent(path)
                    do {
                        try voiceData?.write(to: url)
                    } catch {
                        print("couldn't write file")
                    }
                }
                NotificationCenter.default.post(name: NSNotification.Name("shouldOpenRoute"), object: nil)
                print("posted")
            }

        } catch {
            print("couldn't unarchive route document \(error)")
        }

    }

    /// handler for importing routes from an external temporary file
    /// called in the case of a route being shared from the UIActivityViewController
    /// library
    /// TODO: Does this need to be a static function?
    func importData(from url: URL) {
        /// attempt to fetch data from temporary import from external source
        do {
            print("attempting unarchive")
            // if anything goes wrong with the unarchiving, stick with an empty list of routes
            let data = try Data(contentsOf: url)
            importData(withData: data)
        } catch {
            print("couldn't unarchive route document \(error)")
        }
        
        /// remove from temp storage the file gets automatically placed into
        /// otherwise the file sticks there and won't be deleted automatically,
        /// causing app bloat.
        try? FileManager.default.removeItem(at: url)
    }
    
    /// handler for encoding routes to a .crd file
    /// - Parameters:
    ///     - route: a `SavedRoute` representing the route to save as a .crd
    /// - Returns: `codedData`, representing `route` encoded as a .crd file
    func exportToCrd(route: SavedRoute) -> Data {
        /// fetch the world map if it exists. Otherwise, value is nil
        let worldMap = self.unarchiveMap(id: route.id as String)
        
        /// paths to the beginning and ending landmark files
        var beginVoiceFile: String?
        var endVoiceFile: String?
        
        /// fetch beginning voice notefile if it exists
        if let beginVoiceURL = route.beginRouteAnchorPoint.voiceNote {
            /// build a full valid path the found url from the landmark
            let voiceurl = beginVoiceURL.documentURL
            
            /// encode audio file into a base64 string to be written to
            /// a shareable file
            if let data = try? Data(contentsOf: voiceurl) {
                beginVoiceFile = data.base64EncodedString()
            }
        }
        
        /// fetch beginning voice notefile if it exists
        if let endVoiceURL = route.endRouteAnchorPoint.voiceNote {
            /// build a full valid path the found url from the landmark
            let voiceurl = endVoiceURL.documentURL
            
            /// encode audio file into a base64 string to be written to
            /// a shareable file
            if let data = try? Data(contentsOf: voiceurl) {
                endVoiceFile = data.base64EncodedString()
            }
        }
        
        var routeVoiceNotes: [NSString] = []
        for routeAnchorPoint in route.intermediateAnchorPoints {
            /// build a full valid path the found url from the landmark
            if let voiceurl = routeAnchorPoint.voiceNote?.documentURL {
                /// encode audio file into a base64 string to be written to
                /// a shareable file
                if let data = try? Data(contentsOf: voiceurl) {
                    routeVoiceNotes.append(data.base64EncodedString() as NSString)
                }
            }
        }
        
        /// TODO: need to fix to include functionality for phones which don't support
        /// world maps (> iOS 12)
        let routeData = RouteDocumentData(route: route,
                                          map: worldMap,
                                          beginVoiceNote: beginVoiceFile,
                                          endVoiceNote: endVoiceFile,
                                          routeVoiceNotes: routeVoiceNotes)
        
        /// encode our route data before writing to disk, then return it
        return try! NSKeyedArchiver.archivedData(withRootObject: routeData, requiringSecureCoding: true)
    }
    
    /// handler for exporting routes to a external temporary file
    /// called in the case of a route being shared from the UIActivityViewController
    /// library
    func exportToURL(route: SavedRoute) -> URL? {

        let codedData = exportToCrd(route: route)
        
        /// fetch the documents directory where Apple stores temporary files
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
            ).first
        
        /// set temporary path as name of route
        /// will then later be sent via the share menu
        guard let path = documents?.appendingPathComponent("/\(route.name).crd") else {
            return nil
        }
        
        /// write route to file
        /// and return the path of the created temp file
        do {
            try codedData.write(to: path as URL)
            return path
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func uploadToFirebase(route: SavedRoute) {
        /// Called when the Upload Route button is pressed
        
        let routeRef = Storage.storage().reference().child("AppClipRoutes")
        let codedData = exportToCrd(route: route)
        
        ///creates a reference to the location we want to save the new files
        let fileRef = routeRef.child("\(route.id).crd")

        /// creates a reference to the location we want the .json to live
        let appClipRef = routeRef.child("\(route.appClipCodeID).json")
        
        /// initialize this
        let fileType = StorageMetadata()
        
        /// Initializes routesFile list of [route.id: route.name] dictionaries
        var existingRoutes: [[String: String]] = []
     
        /// attempt to download .json file from Firebase
        appClipRef.getData(maxSize: 100000000000) { appClipJson, error in
            do {
                if let appClipJson = appClipJson {
                    /// unwrap NSData, if it exists, to a list, and set equal to existingRoutes
                    let routesFile = try JSONSerialization.jsonObject(with: appClipJson, options: [])
                    
                    if let routesFile = routesFile as? [[String: String]] {
                        existingRoutes = routesFile
                    }
                }
                let routeInfo = [route.id: route.name] as? [String: String]
                if !existingRoutes.contains(routeInfo!) {
                    existingRoutes.append(routeInfo!)
                }
                /// encode existingRoutes to Data
                let updatedRoutesFile = try JSONSerialization.data(withJSONObject: existingRoutes, options: [])
                
                /// Upload JSON
                fileType.contentType = "application/json"
                let _ = appClipRef.putData(updatedRoutesFile, metadata: fileType){ (metadata, error) in
                    if metadata == nil {
                        print("could not upload .json to Firebase", error!.localizedDescription)
                    } else {
                        print("uploaded .json successfully @", appClipRef.fullPath, "with content", existingRoutes)
                        /// upload .crd route file
                        fileType.contentType = "application/crd"
                        let _ = fileRef.putData(codedData, metadata: fileType){ (metadata, error) in
                            if metadata == nil {
                                print("could not upload route to Firebase", error!.localizedDescription)
                            } else {
                                print("uploaded route successfully @", fileRef.fullPath)
                            }
                        }
                    }
                }
            } catch {
                print("Unable to upload routes \(error)")
            }
        }
    }
    
    /// Load the map from the app's local storage.  If we are on a platform that doesn't support ARWorldMap, this function always returns nil
    ///
    /// - Parameter id: the map id to fetch
    /// - Returns: the stored map
    func unarchiveMap(id: String) -> Any? {
        if #available(iOS 12.0, *) {
            do {
                let data = try Data(contentsOf: getWorldMapURL(id: id))
                guard let unarchivedObject = ((try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)) as ARWorldMap??),
                    let worldMap = unarchivedObject else { return nil }
                return worldMap
            } catch {
                print("Error retrieving world map data.")
            }
        }
        return nil
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
