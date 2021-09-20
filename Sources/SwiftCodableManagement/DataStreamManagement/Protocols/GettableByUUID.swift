//
//  SwiftUIView.swift
//  
//
//  Created by Christopher Guirguis on 9/2/21.
//

import SwiftUI

//This is a convenience protocol that should be adhered to for every struct/class that needs to load from the internet or get cached. It ensures that there is convenience constructor for the CacheName and the APIURL as well as a value for the last time the object was cached
public protocol GettableByUUID: CacheConstructorReversible{
    associatedtype T:CacheConstructorReversible
    var apiUrlConstructor: APIURLConstructor { get }
    var lastCached:Date? { get set }
}

public extension GettableByUUID {
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
        print("getFromNetwork - static - \(T)")
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
        let thisCacheNameConstructor = customFilenameConstructor ?? self.cacheNameConstructor
        CachingService.retrieveFromCacheToObject(filenameConstructor: thisCacheNameConstructor, type: T.self, requiredCacheRecency: requiredCacheRecency){item in
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
        print("static get - \(T)")
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

