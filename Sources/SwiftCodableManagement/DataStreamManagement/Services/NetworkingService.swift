//
//  NetworkingService.swift
//  Revenite
//
//  Created by Christopher Guirguis on 4/20/21.
//

import SwiftUI
import Alamofire

public class NetworkingService: ObservableObject {
    
    public init(){}
    
    public static func getToObject<T>(
        _ url:String,
        type:T.Type,
        cache:Bool,
        encodingService: EncodingService?,
        httpBody: Data?,
        headerValues:[String:String] = [:],
        method: SCMHTTPMethod,
        completion: @escaping (T?)->()
    ) where T: CacheConstructorReversible {
        print("submitting \(method.rawValue) -- \(type.self) -- \(url)")
        URLCache.shared.removeAllCachedResponses()
        var urlRequest = URLRequest(url: URL(string: url)!)
        for val in headerValues {
            urlRequest.addValue(val.value, forHTTPHeaderField: val.key)
            
        }
        
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
                _ = CachingService.saveObjectToCache(object: returnedObject, filenameConstructor: decodedObject.cacheNameConstructor, encodingService: encodingService)
            }
        }
    }
    
    
}

