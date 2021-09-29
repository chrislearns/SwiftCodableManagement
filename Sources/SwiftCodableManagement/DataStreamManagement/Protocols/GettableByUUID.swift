//
//  SwiftUIView.swift
//  
//
//  Created by Christopher Guirguis on 9/2/21.
//

import SwiftUI

//This is a convenience protocol that should be adhered to for every struct/class that needs to load from the internet or get cached. It ensures that there is convenience constructor for the CacheName and the APIURL as well as a value for the last time the object was cached
public protocol GettableByUUID: CacheConstructorReversible{
    var apiUrlConstructor: APIURLConstructor { get }
    var lastCached:Date? { get set }
    var id: UUID { get set }
    
    static var cachePrefix: String { get }
    static var cacheSuffix: String { get }
    
}

public extension GettableByUUID {
    
    var cacheNameConstructor:CacheNameConstructor {
        .init(prefix: Self.cachePrefix, suffix: Self.cacheSuffix, uniqueIdentifier: id.uuidString)
    }
    
    
    //    static func getFromNetwork<T:CacheConstructorReversible>(
    //        type: T.Type,
    //        uuid:String?,
    //        customApiUrlConstructor: APIURLConstructor,
    //        httpBody: Data?,
    //        headerValues:[String:String],
    //        method: SCMHTTPMethod = .get,
    //        encodingService: EncodingService?,
    //        completion: @escaping (T?) -> ()
    //    ){
    //        print("getFromNetwork - static - \(T.self)")
    //        if let body = httpBody {
    //            print("BODY: \(String(data: body, encoding: .utf8) ?? "NONE")")
    //        }
    //        let endpoint:APIURLConstructor = customApiUrlConstructor
    //
    //        NetworkingService.getToObject(endpoint.path(uuid), type: T.self, cache: true, encodingService: encodingService, httpBody: httpBody, headerValues: headerValues, method: method){item in
    //            guard let item = item else {
    //                completion(nil)
    //                return
    //            }
    //            completion(item)
    //        }
    //    }
    
    
}

