//
//  CachingService.swift
//  Revenite
//
//  Created by Christopher Guirguis on 4/24/21.
//

import SwiftUI


public class CachingService: ObservableObject {
    public static func saveObjectToCache<T:Encodable>(
        object:T,
        filenameConstructor:CacheNameConstructor,
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        subfolder: [FileManagementService.SubfolderPaths] = [],
        encodingService: EncodingService?
    ) -> URL? {
        FileManagementService.saveObjectToDisc(
            object: object,
            filename: filenameConstructor.constructedCacheName,
            directory: .documentDirectory,
            subfolder: subfolder,
            encodingService: encodingService
        )
    }
    
    public static func retrieveFromCache(
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
    
    public static func retrieveFromCacheToObject<T>(
        filenameConstructor:CacheNameConstructor,
        type:T.Type,
        requiredCacheRecency:CacheRecency,
        encodingService: EncodingService?,
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
            if let returnedObject = (encodingService ?? EncodingService()).decodeData(cachedData.data, type: T.self){
                completion((returnedObject, cachedData.cacheReturn))
            } else {
                completion(nil)
            }
        } else {
            completion(nil)
        }
        
        
    }
    
    public static func wipeDocumentsDirectory(pathExtension: String? = nil) {
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
    
    public static func saveDataToCache(data:Data, pathConstructor:CacheNameConstructor, completion: (GeneralOutcomes) -> ()){
        print("attempting to cache \(pathConstructor.prefix)")
        guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        
        let fileUrl = cacheURL.appendingPathComponent("\(pathConstructor.constructedCacheName)")
        do {
            try data.write(to: fileUrl, options: [])
            print("successfully cached \(pathConstructor.constructedCacheName)")
        } catch {
            print(error)
        }
    }
    
    #if os(iOS)
    public static func saveImageToCache(
        image: UIImage,
        identifier:UUID,
        prefix: String? = nil,
        suffix: String? = nil,
        completion: (GeneralOutcomes) -> ()
    ){
        if let data = image.pngData() {
            let constructor = CacheNameConstructor(
                prefix: prefix ?? ".image",
                suffix: suffix ?? ".png",
                uniqueIdentifier: identifier.uuidString
            )
            
            saveDataToCache(
                data: data,
                pathConstructor: constructor,
                completion: completion
            )
        }
    }
    #endif
    
}




