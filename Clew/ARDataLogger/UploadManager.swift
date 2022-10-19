//
//  UploadManager.swift
//  LidarCane
//
//  Created by Paul Ruvolo on 5/10/21.
//
//  This class manages uploading files to Firebase in a persistent fashion.  It will automatically stop uploading data if not connected to the Internet, can retry multiple times, and persists the list of pending uploads if the app enters the background

import Foundation
import FirebaseStorage
import SWCompression
import FirebaseAuth

fileprivate func getURL(filename: String) -> URL {
    return FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(filename)
}

/// The upload manager takes care of sending data to Firebase.  Currently we have commented out the section that allows upload jobs to be serialized to local storage: The manager will write the files that should be upload to the phone's local storage if the data cannot be uploaded to Firebase (e.g., if the app enters the background or if the Internet connection drops)
class UploadManager {
    public static let maximumRetryCount = 3
    public static let overrideAllRetries = true
    public static let useCompression = false
    var writeDataToDisk = true
    public static var shared = UploadManager()
    let serialQueue = DispatchQueue(label: "upload.serial.queue", qos: .background)

    var localDataDir: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("filesToUpload")
    }

    var localMetaDataDir: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("uploadQueue")
    }
    
    private init() {
        if !FileManager.default.fileExists(atPath: localDataDir.path) {
            do {
                try FileManager.default.createDirectory(atPath: localDataDir.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
        if !FileManager.default.fileExists(atPath: localMetaDataDir.path) {
            do {
                try FileManager.default.createDirectory(atPath: localMetaDataDir.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    /// Add an upload job to the manager.  The manager will persist the job across the app entering the background or the internet conenction failing.
    /// - Parameters:
    ///   - uploadData: the data to upload
    ///   - contentType: the MIME content type
    ///   - fullPath: the path to the data on the storage bucket
    func putData(_ uploadData: Data, contentType: String, fullPath: String) {
        doUploadJob(data: uploadData, contentType: contentType, fullPath: fullPath, retriesLeft: UploadManager.maximumRetryCount)
        // Debug statement
        print("Data uploaded \(fullPath)")
    }
    
    func doUploadJob(data: Data, contentType: String, fullPath: String, retriesLeft: Int, delayInSeconds: Double = 0) {
        UploadManager.shared.serialQueue.asyncAfter(deadline: .now() + delayInSeconds) {
            
            if self.writeDataToDisk {
                let path = self.localDataDir.appendingPathComponent(UUID().uuidString)
                guard let jsonData = try? JSONSerialization.data(withJSONObject: ["localFile": path.lastPathComponent, "remotePath": fullPath, "contentType": contentType], options: .prettyPrinted) else {
                    return
                }
                let metaDataPath = self.localMetaDataDir.appendingPathComponent(UUID().uuidString + ".json")
                do {
                    try data.write(to: path)
                    try jsonData.write(to: metaDataPath)
                } catch {
                    print("error \(error)")
                }
                return
            }
            
            if !InternetConnectionUtil.isConnectedToNetwork() {
                if !UploadManager.overrideAllRetries {
                    self.doUploadJob(data: data, contentType: contentType, fullPath: fullPath, retriesLeft: retriesLeft, delayInSeconds: 20)
                }
                return
            }

            let fileType = StorageMetadata()
            fileType.contentType = contentType
            let storageRef = Storage.storage().reference().child(fullPath)
                
            storageRef.putData(data, metadata: fileType) { (metadata, error) in
                if error != nil && retriesLeft > 0 && !UploadManager.overrideAllRetries {
                    // Note: this block is usually never executed
                    print("Error: \(error)")
                    self.doUploadJob(data: data, contentType: contentType, fullPath: fullPath, retriesLeft: retriesLeft-1, delayInSeconds: 20)
                }
            }
        }
    }
    
    func hasLocalDataToUploadToCloud()->Bool {
        if let enumerator = try? FileManager.default.contentsOfDirectory(at: self.localMetaDataDir, includingPropertiesForKeys: nil) {
            return !enumerator.isEmpty
        }
        return false
    }
    
    func uploadLocalDataToCloud(completion: ((StorageMetadata?, Error?) -> Void)?) {
        DispatchQueue.global(qos: .userInteractive).async {
            if let enumerator = try? FileManager.default.contentsOfDirectory(at: self.localMetaDataDir, includingPropertiesForKeys: nil) {
                if enumerator.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // TODO: need some announcement to let client know what happened
                    }
                    if let completion = completion {
                        completion(nil, nil)
                    }
                    return
                }
                // TODO: perhaps tell the client what is happening
                var files: [TarEntry] = []
                var cleanupFiles: [URL] = []
                for url in enumerator {
                    if let metadata = try? Data(contentsOf: url), let json = try? JSONSerialization.jsonObject(with: metadata, options: []) as? [String: String] {
                        let localURL = self.localDataDir.appendingPathComponent(json["localFile"]!)
                        if let fileData = try? Data(contentsOf: localURL) {
                            // TODO: might not set the appropriate MIME type, but whatever
                            var info = TarEntryInfo(name: json["remotePath"]!, type: .regular)
                            info.permissions = Permissions.readOwner.union([.writeOwner])
                            let tarEntry = TarEntry(info: info, data: fileData)
                            files.append(tarEntry)
                        }
                        cleanupFiles.append(url)
                        cleanupFiles.append(localURL)
                    }
                }
                let container = TarContainer.create(from: files)
                let storageRef = Storage.storage().reference().child(ARLogger.shared.dataDir ?? "").child(Auth.auth().currentUser!.uid).child("\(UUID().uuidString).tar" + (Self.useCompression ? ".gz" : ""))
                let fileType = StorageMetadata()
                let dataToUpload: Data
                if Self.useCompression {
                    fileType.contentType = "application/x-gzip"
                    let compressed = try? GzipArchive.archive(data: container, fileName: "\(UUID().uuidString).tar", isTextFile: false)
                    dataToUpload = compressed!
                } else {
                    fileType.contentType = "application/x-tar"
                    dataToUpload = container
                }
                let _ = storageRef.putData(dataToUpload, metadata: fileType) { (metadata, error) in
                    if error == nil {
                        for cleanupFile in cleanupFiles {
                            try? FileManager.default.removeItem(at: cleanupFile)
                        }
                    }
                    if let completion = completion {
                        completion(metadata, error)
                    }
                }
            }
        }
    }
}
