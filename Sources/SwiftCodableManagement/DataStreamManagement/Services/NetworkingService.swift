//
//  NetworkingService.swift
//  Revenite
//
//  Created by Christopher Guirguis on 4/20/21.
//

import SwiftUI
import Alamofire

public enum HeaderValues{
    case contentType_applicationJSONCharsetUTF8
    
    public func value() -> [String:String] {
        switch self {
        case .contentType_applicationJSONCharsetUTF8:
            return ["Content-Type":"application/json; charset=utf-8"]
        }
    }
}

public class NetworkingService: ObservableObject {
    public var headerValues: [String:String]
    
    public init(
        headerValues: [String:String] = HeaderValues.contentType_applicationJSONCharsetUTF8.value()
    ){
        self.headerValues = headerValues
    }
    
    public func getFromNetwork<T>(
        customApiUrlConstructor: APIURLConstructor,
        type:T.Type,
        uuid:UUID?,
        cache:Bool,
        encodingService: EncodingService?,
        httpBody: Data?,
        headerValues: [String:String],
        method: SCMHTTPMethod,
        completion: @escaping (T?)->()
    ) where T: CacheConstructorReversible {
        print("submitting \(method.rawValue) -- \(type.self) -- \(customApiUrlConstructor.path(uuid?.uuidString))")
        URLCache.shared.removeAllCachedResponses()
        var urlRequest = URLRequest(url: URL(string: customApiUrlConstructor.path(uuid?.uuidString))!)
        let allHeaders = self.headerValues.merging(headerValues) { selfVal, paramVal in
            paramVal
        }
        print("headers = \(allHeaders)")
        urlRequest.headers = HTTPHeaders(allHeaders)
        urlRequest.httpBody = httpBody
        URLCache.shared.removeCachedResponse(for: urlRequest)
        urlRequest.httpMethod = method.rawValue
        
        let request = AF.request(urlRequest)
        
        // 2
        
        request.responseJSON { (data) in
            
            guard let data = data.data else {
                completion(nil)
                print("\(method.rawValue) not valid")
                return
            }
            print(String(data: data, encoding: .utf8) ?? "data from rquest could not be unwrapped to string")
            print("\(method.rawValue) completed")
            
            let returnedObject = (encodingService ?? EncodingService()).decodeData(data, type: T.self)
            completion(returnedObject)
            
            print("completion handler executed")
            if cache, let decodedObject = returnedObject {
                _ = CachingService.saveObjectToCache(object: returnedObject, filenameConstructor: type.cacheNameConstructor(uuid), encodingService: encodingService)
            }
        }
    }
    
    public static func getFromCache<T:CacheConstructorReversible>(
        type: T.Type,
        uuid:UUID?,
        requiredCacheRecency: CacheRecency,
        customFilenameConstructor: CacheNameConstructor,
        encodingService: EncodingService?,
        completion: @escaping ((object: T, cacheReturn: (metRecencyRequirement: Bool, recency: TimeInterval, cacheDate: Date))?)->()){
            
            let cacheNameConstructor = customFilenameConstructor
            CachingService.retrieveFromCacheToObject(filenameConstructor: cacheNameConstructor, type: T.self, requiredCacheRecency: requiredCacheRecency, encodingService: encodingService){item in
                guard let item = item else {
                    completion(nil)
                    return
                }
                completion(item)
            }
        }
    
    public func get<T:CacheConstructorReversible>(
        type: T.Type,
        uuid:UUID?,
        desiredCacheRecency: CacheRecency,
        forceNetworkGrab:Bool,
        httpBody: Data?,
        headerValues: [String:String],
        customFilenameConstructor: CacheNameConstructor,
        customApiUrlConstructor: APIURLConstructor,
        encodingService: EncodingService?,
        method: SCMHTTPMethod = .get,
        completion: @escaping ((item: T, interval: TimeInterval, cacheDate: Date)?) -> ()){
            print("static \(method.rawValue) - \(T.self)")
            NetworkingService.getFromCache(
                type: type,
                uuid: uuid,
                requiredCacheRecency: desiredCacheRecency,
                customFilenameConstructor: customFilenameConstructor,
                encodingService: encodingService){cachedObject in
                    //Check if we got a cached object
                    //If we got it make sure it met our desired cache recency
                    if let cachedObject = cachedObject, cachedObject.cacheReturn.metRecencyRequirement, !forceNetworkGrab{
                        completion((cachedObject.object, cachedObject.cacheReturn.recency, cachedObject.cacheReturn.cacheDate))
                    } else {
                        //If our cached object was not present OR it was too old then try to grab something fresh from the network
                        self.getFromNetwork(
                            customApiUrlConstructor: customApiUrlConstructor,
                            type: T.self,
                            uuid: uuid,
                            cache: true,
                            encodingService: encodingService,
                            httpBody: httpBody,
                            headerValues: headerValues,
                            method: method){networkObject in
                            
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
    
    public func simpleRequestToObject<T: Codable>(
        type:T.Type,
        urlString: String,
        httpBody: Data? = nil,
        headerValues: [String:String] = [:],
        method: HTTPMethod = .get,
        encodingService: EncodingService? = nil,
        completion: @escaping (_ obj: T?, _ url: String, _ data: Data?, _ request: URLRequest?) -> ()){
        guard let url = URL(string: urlString) else {
            completion(nil, urlString, nil, nil)
            return 
        }
        
        
        
        URLCache.shared.removeAllCachedResponses()
        var urlRequest = URLRequest(url: url)
            let allHeaders = self.headerValues.merging(headerValues) { selfVal, paramVal in
                paramVal
            }
            print("headers = \(allHeaders)")
            urlRequest.headers = HTTPHeaders(allHeaders)
            urlRequest.httpBody = httpBody

        
        URLCache.shared.removeCachedResponse(for: urlRequest)
            urlRequest.httpMethod = method.rawValue

        let request = AF.request(urlRequest)

        // 2

        request.responseJSON { (data) in
            
            guard let unwrappedData = data.data else {
                print("\(method) not valid")
                completion(nil, urlString, data.data, urlRequest)
                return
            }
            print("\(method) to (\(T.self) completed")
            
            if let object = unwrappedData.toObject(type: T.self, encodingService: encodingService){
                
                completion(object, urlString, unwrappedData, urlRequest)
            } else {
                print("json data malformed")
                completion(nil, urlString, unwrappedData, urlRequest)
            }
            
        }

    }
}

