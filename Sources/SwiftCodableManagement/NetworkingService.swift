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
        completion: @escaping (T?)->()
    ) where T: CacheConstructorReversible {
        print("submitting get")
        print("type: \(type.self)")
        print("url: \(url)")
        URLCache.shared.removeAllCachedResponses()
        let urlRequest = URLRequest(url: URL(string: url)!)
        URLCache.shared.removeCachedResponse(for: urlRequest)
        
        
        let request = AF.request(url)
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

