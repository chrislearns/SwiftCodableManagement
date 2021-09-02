//
//  UnkeyedDecodingContainer+Extensions.swift
//  Revenite
//
//  Created by Christopher Guirguis on 4/21/21.
//

import SwiftUI

extension UnkeyedDecodingContainer {
    mutating func decodeNested<T>(_ type: T.Type, keyString: String) throws -> T where T : Decodable {
        let nestedContainer = try self.nestedContainer(keyedBy: AnyCodingKey.self)
        return try nestedContainer.decode(T.self, forKey: .init(keyString))
    }
}

func decodeNestedHeterogenousArray<U:InheritanceDecodeTypable>(container: KeyedDecodingContainer<AnyCodingKey>, forKey: AnyCodingKey, heterogenousSuperType:U.Type) -> [U.T] {
    do {
        var encodedHeterogenousArray = try container.nestedUnkeyedContainer(forKey: forKey)
        var copiedArray = encodedHeterogenousArray
        
        var decodedObjects = [U.T]()
        while(!encodedHeterogenousArray.isAtEnd){
            let heterogenousType = try encodedHeterogenousArray.decodeNested(U.self, keyString: U.codedKey())
//            print("type -> \(heterogenousType)")
            decodedObjects.append(try copiedArray.decode(heterogenousType.toType()))
        }
        
        return decodedObjects
        
    }
    catch {
        return []
    }
}

func decodeNestedHeterogenousObject<U:InheritanceDecodeTypable>(container: KeyedDecodingContainer<AnyCodingKey>, forKey: AnyCodingKey, heterogenousSuperType:U.Type) throws -> U.T {
    _ = UUID().uuidString.prefix(4)
//    print("decoding nested object -> \(heterogenousSuperType.codedKey()) + \(uniqueRoundID)")
//    print("Looking for object at key -> \(forKey.stringValue) + \(uniqueRoundID)")
    let containerCopy = container
    let encodedHeterogenousObject = try container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: forKey)
//    print("heterogenousObject = \(encodedHeterogenousObject) + \(uniqueRoundID)")
//    print("HERE: \(uniqueRoundID)")
    let heterogenousType = try encodedHeterogenousObject.decode(U.self, forKey: .init(U.codedKey()))
//        print("superType -> \(heterogenousSuperType) + \(uniqueRoundID)")
//    print("subType -> \(heterogenousType.toType()) + \(uniqueRoundID)")
    
    let object = try heterogenousType.toType().init(from: containerCopy.superDecoder(forKey: forKey))
    
//    print(object)
    
    return object
            
       
        
    
    
}


protocol InheritanceDecodeTypable:Decodable {
    associatedtype T:Decodable
    func toType() -> T.Type
    static func codedKey() -> String
}

//This protocol requires the presence of a CacheNameConstructor which allows for easy generation of the constructed cache name via a computed variable
protocol CacheConstructorReversible:Codable {
    var cacheNameConstructor:CacheNameConstructor { get }
}

//This is a convenience protocol that should be adhered to for every struct/class that needs to load from the internet or get cached. It ensures that there is convenience constructor for the CacheName and the APIURL as well as a value for the last time the object was cached
protocol GettableByUUID{
    associatedtype T:CacheConstructorReversible
    var filenameConstructor: CacheNameConstructor { get }
    var apiUrlConstructor: APIURLConstructor { get }
    var lastCached:Date? { get set }
}

extension GettableByUUID {
    func getFromNetwork(
        uuid:String,
        customApiUrlConstructor: APIURLConstructor?,
        completion: @escaping (T?) -> ()
    ){
        let endpoint:APIURLConstructor = customApiUrlConstructor ?? self.apiUrlConstructor
        print("getFromNetwork - dynamic")
        NetworkingService.getToObject(endpoint.path(uuid), type: T.self, cache: true){item in
            guard let item = item else {
                completion(nil)
                return
            }
            completion(item)
        }
    }
    
    static func getFromNetwork(
        uuid:String,
        customApiUrlConstructor: APIURLConstructor,
        completion: @escaping (T?) -> ()
    ){
        print("getFromNetwork - static")
        let endpoint:APIURLConstructor = customApiUrlConstructor
        
        NetworkingService.getToObject(endpoint.path(uuid), type: T.self, cache: true){item in
            guard let item = item else {
                completion(nil)
                return
            }
            completion(item)
        }
    }
    
    func getFromCache(
        uuid:String,
        requiredCacheRecency: CacheRecency,
        customFilenameConstructor: CacheNameConstructor?,
        completion: @escaping ((object: T, cacheReturn: (metRecencyRequirement: Bool, recency: TimeInterval, cacheDate: Date))?)->()){
        let cacheNameConstructor = customFilenameConstructor ?? self.filenameConstructor
        CachingService.retrieveFromCacheToObject(filenameConstructor: cacheNameConstructor, type: T.self, requiredCacheRecency: requiredCacheRecency){item in
            guard let item = item else {
                completion(nil)
                return
            }
            completion(item)
        }
    }
    
    static func getFromCache(
        uuid:String,
        requiredCacheRecency: CacheRecency,
        customFilenameConstructor: CacheNameConstructor,
        completion: @escaping ((object: T, cacheReturn: (metRecencyRequirement: Bool, recency: TimeInterval, cacheDate: Date))?)->()){
        let cacheNameConstructor = customFilenameConstructor
        CachingService.retrieveFromCacheToObject(filenameConstructor: cacheNameConstructor, type: T.self, requiredCacheRecency: requiredCacheRecency){item in
            guard let item = item else {
                completion(nil)
                return
            }
            completion(item)
        }
    }
    
    func get(
        uuid:String,
        desiredCacheRecency: CacheRecency,
        forceNetworkGrab:Bool = false,
        customFilenameConstructor: CacheNameConstructor? = nil,
        customApiUrlConstructor: APIURLConstructor? = nil,
        completion: @escaping ((item: T, interval: TimeInterval, cacheDate: Date)?) -> ()){
        print("dynamic get")
        getFromCache(
            uuid: uuid,
            requiredCacheRecency: desiredCacheRecency,
            customFilenameConstructor: customFilenameConstructor){cachedObject in
            //Check if we got a cached object
            //If we got it make sure it met our desired cache recency && we werenet going to force a network grab anyway
            if let cachedObject = cachedObject, cachedObject.cacheReturn.metRecencyRequirement, !forceNetworkGrab{
                completion((cachedObject.object, cachedObject.cacheReturn.recency, cachedObject.cacheReturn.cacheDate))
            } else {
                //If our cached object was not present OR it was too old then try to grab something fresh from the network
                getFromNetwork(uuid: uuid, customApiUrlConstructor: customApiUrlConstructor){networkObject in
                    
                    //If the network failed to get us our object then check if we can even use the old backup as a very old backup
                    if let networkObject = networkObject{
                        //We are here if the network object was present when we asked for it
                        completion((networkObject, TimeInterval.zero, Date()))
                    } else {
                        print("could not fetch from network as backup for cache")
                        //If the cache we are here it means the cached object existed but it failed the first conditional because of its age
                        if let oldCachedObject = cachedObject {
                            //Run completion with old object
                            completion((oldCachedObject.object, oldCachedObject.cacheReturn.recency, oldCachedObject.cacheReturn.cacheDate))
                        } else {
                            //Run completion with nil
                            completion(nil)
                        }
                    }
                }
            }
        }
    }
    
    static func get(
        uuid:String,
        desiredCacheRecency: CacheRecency,
        forceNetworkGrab:Bool,
        customFilenameConstructor: CacheNameConstructor,
        customApiUrlConstructor: APIURLConstructor,
        completion: @escaping ((item: T, interval: TimeInterval, cacheDate: Date)?) -> ()){
        print("static get")
        getFromCache(
            uuid: uuid,
            requiredCacheRecency: desiredCacheRecency,
            customFilenameConstructor: customFilenameConstructor){cachedObject in
            //Check if we got a cached object
            //If we got it make sure it met our desired cache recency
            if let cachedObject = cachedObject, cachedObject.cacheReturn.metRecencyRequirement, !forceNetworkGrab{
                completion((cachedObject.object, cachedObject.cacheReturn.recency, cachedObject.cacheReturn.cacheDate))
            } else {
                //If our cached object was not present OR it was too old then try to grab something fresh from the network
                getFromNetwork(uuid: uuid, customApiUrlConstructor: customApiUrlConstructor){networkObject in
                    
                    //If the network failed to get us our object then check if we can even use the old backup as a very old backup
                    if let networkObject = networkObject{
                        //We are here if the network object was present when we asked for it
                        completion((networkObject, TimeInterval.zero, Date()))
                    } else {
                        print("could not fetch from network as backup for cache")
                        //If the cache we are here it means the cached object existed but it failed the first conditional because of its age
                        if let oldCachedObject = cachedObject {
                            //Run completion with old object
                            completion((oldCachedObject.object, oldCachedObject.cacheReturn.recency, oldCachedObject.cacheReturn.cacheDate))
                        } else {
                            //Run completion with nil
                            completion(nil)
                        }
                    }
                }
            }
        }
    }
}

