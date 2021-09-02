//
//  NetworkingService.swift
//  Revenite
//
//  Created by Christopher Guirguis on 4/20/21.
//

import SwiftUI
import Alamofire

public class NetworkingService: ObservableObject {
//    static func get(_ url:String, completion: @escaping (Data?)->()){
//        print("submitting get")
//        let urlRequest = URLRequest(url: URL(string: url)!)
//        URLCache.shared.removeCachedResponse(for: urlRequest)
//
//
//        let request = AF.request(url)
//        // 2
//        request.responseJSON { (data) in
//            //            print(data)
//            if let data = data.data{
//                print("get completed")
//                completion(data)
//            }
//        }
//        completion(nil)
//
//    }
    
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

public class APIURLConstructor{
    init(
        constructorPathItems:[String]
    ){
        self.constructorPathItems = constructorPathItems
    }
    var root = "https://chrisguirguis.com/revenitedummyapi/"
    var constructorPathItems:[String]
    
    func path(_ itemID:String) -> String{
        root + constructorPathItems.map{$0}.joined() + itemID
    }
}

public enum APIPathComponents:String {
    case user = "user/"
    case image = "image/"
    case recoveryProtocol = "recoveryprotocol/"
}
