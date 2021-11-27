//
//  NetworkingService.swift
//  Revenite
//
//  Created by Christopher Guirguis on 4/20/21.
//

import SwiftUI
import Alamofire
import Network
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
    
    public static let NoNetworkAvailableCode = -100
    public var headerValues: [String:String]
    private var timers: [Timer] = []
    @Published public var sharedNetworkingQueue: [QueuedNetworkRequest] = []
    var queueAction: ((QueuedNetworkRequest) -> ())?
    let monitor = NWPathMonitor()
    @Published public var networkAvailable: Bool
    
    public init(
        headerValues: [String:String] = HeaderValues.contentType_applicationJSONCharsetUTF8.value(),
        queueAction: ((QueuedNetworkRequest) -> ())?
    ){
        self.headerValues = headerValues
        self.queueAction = queueAction
        
        //Network available is default set to false to populate all properties of class. It will be computed below in the .init()
        self.networkAvailable = false
        
        self.setupTimers()
        self.setupNetworkMonitor()
        withAnimation {
            self.networkAvailable = monitor.currentPath.status.isAvailableAsBool
        }
        
    }
}

//MARK: - Queue Related Items
public extension NetworkingService {
    
    public func setupNetworkMonitor(){
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                withAnimation {
                    self.networkAvailable = path.status.isAvailableAsBool
                }
                
            }
        }
        self.monitor.start(queue: .global())
    }
    public func setupTimers(){
        let allIntervals = QueuedNetworkRequest.ExecutionTime.allCases.compactMap{$0.interval}
        print("setting up timers for the following items")
        for interval in allIntervals {
            print("setup timer: \(interval)")
            let timer = Timer.scheduledTimer(
                withTimeInterval: Double(interval),
                repeats: true
            ){ timer in
                DispatchQueue.main.async{
                    let itemsOnThisInterval = self.sharedNetworkingQueue.filter{$0.executionTime.interval == interval}
                    self.executeQueuedRequests(interval: interval, requests: itemsOnThisInterval)
                }
            }
            timers.append(timer)
        }
    }
    
    func executeQueuedRequests(interval: Int, requests: [QueuedNetworkRequest]){
        print("Executing items queued on interval of \(interval) - count: \(requests.count)")
        for queuedRequest in requests {
            queueAction?(queuedRequest)
        }
    }
}

//MARK: - Request Related Items
public extension NetworkingService {
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
            
//            print("completion handler executed")
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
        requestObject: SimpleNetworkRequest,
        retryInterval: QueuedNetworkRequest.ExecutionTime?,
        encodingService: EncodingService? = nil,
        completion: @escaping (_ obj: T?, _ url: String, _ data: Data?, _ request: URLRequest?, _ statusCode: Int?) -> ()){
            simpleRequest(requestObject: requestObject, retryInterval: retryInterval) { url, data, request, statusCode in
                    guard let unwrappedData = data else {
                        completion(nil, url, data, request, statusCode)
                        return
                    }
                    
                    guard let object = unwrappedData.toObject(type: T.self, encodingService: encodingService) else {
                        completion(nil, url, unwrappedData, request, statusCode)
                        return
                    }
                    
                    completion(object, url, unwrappedData, request, statusCode)
                }
    }
    
    public func simpleRequest(
        requestObject: SimpleNetworkRequest,
        retryInterval: QueuedNetworkRequest.ExecutionTime?,
        completion: @escaping (_ url: String, _ data: Data?, _ request: URLRequest?, _ statusCode: Int?) -> ()){
            
            guard networkAvailable else {
                if let retryInterval = retryInterval {
                    sharedNetworkingQueue.append(.init(request: requestObject, executionTime: retryInterval))
                }
                completion(requestObject.urlString, nil, nil, NetworkingService.NoNetworkAvailableCode)
                return
            }
            
            guard let url = URL(string: requestObject.urlString) else {
                completion(requestObject.urlString, nil, nil, nil)
                return
            }
            
            URLCache.shared.removeAllCachedResponses()
            var urlRequest = URLRequest(url: url)
            let allHeaders = self.headerValues.merging(requestObject.allHeaders) { selfVal, paramVal in
                paramVal
            }
            print("headers = \(allHeaders)")
            urlRequest.headers = HTTPHeaders(allHeaders)
            urlRequest.httpBody = requestObject.httpBody
            
            
            URLCache.shared.removeCachedResponse(for: urlRequest)
            urlRequest.httpMethod = requestObject.method.rawValue
            
            let request = AF.request(urlRequest)
            
            request.responseJSON { (data) in
                completion(requestObject.urlString, data.data, urlRequest, request.response?.statusCode)
            }
        }
}

public struct SimpleNetworkRequest: Codable, Hashable {
    public init(urlString: String,
                httpBody: Data?,
                authHeader: [String : String],
                method: HTTPMethod,
                auxiliaryHeaders: [String : String]
    ) {
        self.urlString = urlString
        self.httpBody = httpBody
        self.authHeader = authHeader
        self.method = method
        self.auxiliaryHeaders = auxiliaryHeaders
    }
    
    public var urlString: String
    public var httpBody: Data?
    public var authHeader: [String: String]
    public var method: HTTPMethod
    public var auxiliaryHeaders: [String: String]
    public var allHeaders:[String:String]{
        authHeader.mergeDicts(auxiliaryHeaders)
    }
}


public struct QueuedNetworkRequest: Codable, Hashable {
    public var request: SimpleNetworkRequest
    public var executionTime: ExecutionTime
    
    public enum ExecutionTime: String, Codable, CaseIterable {
        case atStart
        case immediately
        
        case q5sec
        case q1min
        case q5min
        case q10min
        case q15min
        case q30min
        case q1h
        case q2h
        case q4h
        case q6h
        case q12h
        case q1daily
        
        public var interval: Int? {
            switch self {
            case .atStart:
                return nil
            case .immediately:
                return nil
            case .q5sec:
                return 5
            case .q1min:
                return 60
            case .q5min:
                return 300
            case .q10min:
                return 600
            case .q15min:
                return 900
            case .q30min:
                return 1800
            case .q1h:
                return 3600
            case .q2h:
                return 7200
            case .q4h:
                return 14400
            case .q6h:
                return 21600
            case .q12h:
                return 43200
            case .q1daily:
                return 86400
            }
        }
    }
}


extension HTTPMethod: Codable { }

extension NWPath.Status {
    var isAvailableAsBool: Bool {
        switch self {
        case .satisfied:
            return true
        case .requiresConnection, .unsatisfied:
            return false
        }
    }
}
