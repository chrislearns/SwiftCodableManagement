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
    
    static func getToObject<T>(
        _ url:String,
        type:T.Type,
        cache:Bool,
        completion: @escaping (T?)->(),
        headerValues:[String:String] = [:],
        method: SCMHTTPMethod = .get
    ) where T: CacheConstructorReversible {
        print("submitting get")
        print("type: \(type.self)")
        print("url: \(url)")
        URLCache.shared.removeAllCachedResponses()
        var urlRequest = URLRequest(url: URL(string: url)!)
        for val in headerValues {
            urlRequest.addValue(val.value, forHTTPHeaderField: val.key)
        }
        URLCache.shared.removeCachedResponse(for: urlRequest)
        urlRequest.httpMethod = method.rawValue
        
        let request = AF.request(urlRequest)
        // 2
        
        request.responseJSON { (data) in
            
            guard let data = data.data else {
                completion(nil)
                return
            }
            print("get completed")
            
            let returnedObject = EncodingService.decodeData(data, type: T.self)
            completion(returnedObject)
            
            print("completion handler executed")
            if cache, let decodedObject = returnedObject {
                _ = CachingService.saveObjectToCache(object: returnedObject, filenameConstructor: decodedObject.cacheNameConstructor)
            }
        }
    }
    
    
}

