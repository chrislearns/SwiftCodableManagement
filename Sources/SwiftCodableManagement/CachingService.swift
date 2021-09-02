//
//  CachingService.swift
//  Revenite
//
//  Created by Christopher Guirguis on 4/24/21.
//

import SwiftUI


class CachingService: ObservableObject {
    static func saveObjectToCache<T:Encodable>(
        object:T,
        filenameConstructor:CacheNameConstructor,
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        subfolder: [FileManagementService.SubfolderPaths] = []
    ) -> URL? {
        FileManagementService.saveObjectToDisc(
            object: object,
            filename: filenameConstructor.constructedCacheName,
            directory: .documentDirectory,
            subfolder: subfolder
        )
    }
    
    static func retrieveFromCache(
        filenameConstructor:CacheNameConstructor,
        requiredCacheRecency:CacheRecency
    ) -> (
        data: Data,
        cacheReturn: (
            metRecencyRequirement: Bool,
            recency: TimeInterval,
            cacheDate: Date
        )
    )? {
        guard let documentsDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {return nil}
        let fileUrl = documentsDirectoryUrl.appendingPathComponent("\(filenameConstructor.constructedCacheName)")
        do {
            //Try to check for this files attributes
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileUrl.path)
            //Try to find the date this cache was created
            if let fileCacheDate = fileAttributes[.modificationDate] as? Date {
                let timeSinceCache = Date().timeIntervalSince(fileCacheDate)
                print("Time Since Cache -> \(timeSinceCache)")
                
                guard let stream = InputStream(url: fileUrl) else {return nil}
                stream.open()
                defer {
                    stream.close()
                }
                
                // Read data from .json file and transform data into an array
                let data = try Data.init(reading: stream)
                
                
                
                
                if timeSinceCache > TimeInterval(requiredCacheRecency.rawValue) {
                    print("cache present but too old \(timeSinceCache) > \(TimeInterval(requiredCacheRecency.rawValue))")
                    return (data, (false, timeSinceCache, fileCacheDate))
                } else {
                    return (data, (true, timeSinceCache, fileCacheDate))
                }
            }
            return nil
        } catch {
            print(error)
            return nil
        }
        
        
    }
    
    static func retrieveFromCacheToObject<T>(
        filenameConstructor:CacheNameConstructor,
        type:T.Type,
        requiredCacheRecency:CacheRecency,
        completion: @escaping (
            (
                object: T,
                cacheReturn: (
                    metRecencyRequirement: Bool,
                    recency: TimeInterval,
                    cacheDate: Date)
            )?) -> ()
    ) where T: CacheConstructorReversible {
        
        if let cachedData = retrieveFromCache(filenameConstructor: filenameConstructor, requiredCacheRecency: requiredCacheRecency){
            
            print("cached data retrieved")
            if let returnedObject = EncodingService.decodeData(cachedData.data, type: T.self){
                completion((returnedObject, cachedData.cacheReturn))
            } else {
                completion(nil)
            }
        } else {
            completion(nil)
        }
        
        
    }
    
    static func wipeDocumentsDirectory(pathExtension: String? = nil) {
        if let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first{
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                           includingPropertiesForKeys: nil,
                                                                           options: .skipsHiddenFiles)
                for fileURL in fileURLs {
                    
                    
                    //Filter by extension if necessary
                    if let pathExtension = pathExtension {
                        if fileURL.pathExtension == pathExtension {
                            try FileManager.default.removeItem(at: fileURL)
                        }
                    } else {
                        //If pathExtension is nil then we are not discriminating by pathExtension
                        try FileManager.default.removeItem(at: fileURL)
                    }
                    
                        
//

                }
            } catch  { print(error) }
        } else {
            print("failed to wipe documents directory")
        }

    }
    
    static func saveDataToCache(data:Data, pathConstructor:CacheNameConstructor, completion: (GeneralOutcomes) -> ()){
        print("attempting to cache \(pathConstructor.prefix.rawValue)")
        guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        
        let fileUrl = cacheURL.appendingPathComponent("\(pathConstructor.constructedCacheName)")
        do {
            try data.write(to: fileUrl, options: [])
            print("successfully cached \(pathConstructor.constructedCacheName)")
        } catch {
            print(error)
        }
    }
    
    static func saveImageToCache(image: UIImage, identifier:UUID, completion: (GeneralOutcomes) -> ()){
        if let data = image.pngData() {
            let constructor = CacheNameConstructor(prefix: .image, suffix: .png, uniqueIdentifier: identifier.uuidString)
            saveDataToCache(data: data, pathConstructor: constructor, completion: completion)
        }
    }
    
    
}

struct CacheNameConstructor{
    var prefix:CachePrefix
    var suffix:CacheSuffix
    
    var uniqueIdentifier:String?
    
    var constructedCacheName:String{
        return prefix.rawValue
            + (uniqueIdentifier == nil ? "" : "_") + (uniqueIdentifier ?? "")
            + suffix.rawValue
    }
}


enum CachePrefix:String{
    case patient
    case recoveryProtocol
    case megaStructure
    case image
    case obj
}

enum CacheSuffix:String{
    case json = ".json"
    case none = ""
    case png = ".png"
}

enum CacheRecency:Int {
    case minute = 60
    case minute5 = 300
    case minute15 = 900
    case minute30 = 1800
    case hour = 3600
    case hour2 = 7200
    case hour4 = 14400
    case hour8 = 28800
    case hour12 = 43200
    case day = 86400
    case week = 604800
    case infinity = 9999999999
    
    func comparedTimeIsExpired(_ comparedTime: TimeInterval) -> Bool{
        let desiredCacheTime = self.rawValue
        let comparedTime = Int(comparedTime)
        
        return comparedTime >= desiredCacheTime
    }
}





enum GeneralOutcomes {
    case success
    case error
    case ambiguous
}


extension Data {
    init(reading input: InputStream) throws {
        self.init()
        input.open()
        defer {
            input.close()
        }
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            if read < 0 {
                //Stream error occured
                throw input.streamError!
            } else if read == 0 {
                //EOF
                break
            }
            self.append(buffer, count: read)
        }
    }
}
