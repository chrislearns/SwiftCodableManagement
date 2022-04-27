//
//  NetworkingService.swift
//  Revenite
//
//  Created by Christopher Guirguis on 4/20/21.
//

import SwiftUI
import Alamofire
import Network

public class NetworkingService: ObservableObject {
  
  public var logTypes: [LogTypes]
  
  public static let shared = NetworkingService()
  
  public var headerValues: [String:String]
  
  
  //MARK: - Request Queue
  @Published public var sharedNetworkingQueue: [UUID:QueuedNetworkRequest] = [:]
  var queueAction: ((QueuedNetworkRequest) -> ())?
  private var timers: [Timer] = []
  
  //MARK: - Network Availability
  let monitor = NWPathMonitor()
  @Published public var networkAvailable: Bool
  
  //MARK: - Initializer
  public init(
    logTypes: [LogTypes] = [],
    headerValues: [String:String] = HeaderValues.contentType_applicationJSONCharsetUTF8.value(),
    queueAction: ((QueuedNetworkRequest) -> ())? = nil
  ){
    self.logTypes = logTypes
    self.headerValues = headerValues
    self.queueAction = queueAction
    
    //Network available is default set to false to populate all properties of class. It will be computed below in the .init()
    self.networkAvailable = false
    
    self.setupTimers()
    self.setupNetworkMonitor()
    withAnimation {
      self.networkAvailable = monitor.currentPath.status.isAvailableAsBool
    }
    
    self.refreshQueue()
    print("Fetched queue from filesystem - \(sharedNetworkingQueue.count) items queued")
    
  }
}

//MARK: - Queue Related Items
public extension NetworkingService {
  
  func setupNetworkMonitor(){
    monitor.pathUpdateHandler = { path in
      DispatchQueue.main.async {
        withAnimation {
          self.networkAvailable = path.status.isAvailableAsBool
        }
        
      }
    }
    self.monitor.start(queue: .global())
  }
  func setupTimers(){
    let allIntervals = QueuedNetworkRequest.ExecutionTime.allCases.compactMap{$0.interval}
    print("setting up timers for the following items")
    for interval in allIntervals {
      print("setup timer: \(interval)")
      let timer = Timer.scheduledTimer(
        withTimeInterval: Double(interval),
        repeats: true
      ){ timer in
        DispatchQueue.main.async{
          let itemsOnThisInterval = self.sharedNetworkingQueue.filter{$0.value.executionTime.interval == interval}
          self.executeQueuedRequests(interval: interval, requests: itemsOnThisInterval)
        }
      }
      timers.append(timer)
    }
  }
  
  func executeQueuedRequests(interval: Int, requests: [UUID:QueuedNetworkRequest]){
    if logTypes.contains(.timedEvents) {
    print("Executing items queued on interval of \(interval) - count: \(requests.count)")
    }
    for thisRequestEntry in requests {
      let queuedRequest = thisRequestEntry.value
      if let queueAction = queueAction {
        queueAction(queuedRequest)
      } else {
        simpleRequest(
          requestObject: queuedRequest.request,
          retryInterval: nil) { url, data, request, statusCode in
            guard statusCode == 200 else { return }
            
            self.sharedNetworkingQueue[thisRequestEntry.key] = nil
            self.saveQueueAndRefresh()
          }
      }
      
    }
  }
  func saveQueueAndRefresh(){
    if let cacheURL = FileManagementService.cachedRequestsURL {
      
      //This caches the requests and returns a Bool which represents the success of this process.
      let successfullyWroteCachedRequests = self.sharedNetworkingQueue.writeToFile(url: cacheURL)
      
      if successfullyWroteCachedRequests {
        if let item: [UUID: QueuedNetworkRequest] = FileManagementService.readFileToObject(from: cacheURL) {
          self.sharedNetworkingQueue = item
        }
      }
    }
  }
  func saveQueue() -> Bool{
    if let cacheURL = FileManagementService.cachedRequestsURL {
      //This caches the requests and returns a Bool which represents the success of this process.
      return self.sharedNetworkingQueue.writeToFile(url: cacheURL)
    } else {
      
      return false
    }
  }
  func refreshQueue(){
    if let cacheURL = FileManagementService.cachedRequestsURL,
       let item: [UUID: QueuedNetworkRequest] = FileManagementService.readFileToObject(from: cacheURL) {
      self.sharedNetworkingQueue = item
    }
  }
  
}

//MARK: - Request Related Items
public extension NetworkingService {
  
  func simpleRequestToObject<T: Codable>(
    type:T.Type,
    requestObject: SimpleNetworkRequest,
    shouldCacheReturnValue: Bool = false,
    retryInterval: QueuedNetworkRequest.ExecutionTime?,
    encodingService: EncodingService? = nil,
    completion: @escaping (_ obj: T?, _ url: String, _ data: Data?, _ request: URLRequest?, _ statusCode: Int?) -> ()){
      ///Execute the simpleRequest function and try to convert the return to the proper 'type'
      simpleRequest(requestObject: requestObject, retryInterval: retryInterval) { url, data, request, statusCode in
        
        ///Decode the data to its proper type
        let object = data?.toObject(type: T.self, encodingService: encodingService)
        
        ///If this request was expected to cache its return value
        ///Unwrap the status code
        ///The status code did not indicate one of our erroneous custom status codes
        ///The cacheURL gets unwrapped
        DispatchQueue.global(qos: .utility).async {
          if shouldCacheReturnValue,
             let statusCode = statusCode,
             ![NetworkingService.StatusUsingFallbackCache,
               NetworkingService.StatusURLFailedToUnwrap,
               NetworkingService.StatusUsingCacheBaseRequestObjectPreference, NetworkingService.StatusNoNetworkAvailableCode].contains(statusCode),
             let cacheURL = requestObject.cacheURL {
            
            
            
            
            ///Try writing this item to the FileSystem/Cache
            if object.writeToFile(url: cacheURL, forLocalContentCache: true) {
              let writeTime = FileManagementService.fileModificationDate(atPath: cacheURL)?.description
              print("Cached \(type) @ \(cacheURL.path) -- Time: \(writeTime ?? "nil")")
            } else {
              print("Failed to cache \(type) @ \(cacheURL.path)")
            }
          }
        }
        
        ///Move-on to the completion
        completion(object, url, data, request, statusCode)
      }
    }
  
  func simpleRequest(
    requestObject: SimpleNetworkRequest,
    retryInterval: QueuedNetworkRequest.ExecutionTime?,
    completion: @escaping (_ url: String, _ data: Data?, _ request: URLRequest?, _ statusCode: Int?) -> ()){
      
      ///No matter what we are going to grab the last cache of this request. Whether or not we use it will be determined
      let cachedData: Data? = {
        if let cacheURL = requestObject.cacheURL {
          return FileManagementService.readFileToData(from: cacheURL)
        } else {
          return nil
        }
      }()
      ///If this request would prefer a cached version, then we will use that without pinging the network. A potential use-case here is if you want an item that could have previously been stored and should be pretty stable (think about things like static objects on the server). This can help prevent issues like 429 status codes from the served if we don't expect an item to change too frequently.
      ///We will also try to unwrap the creationDate value for the file that was cached so we can compare it against our preference for how old of a cache we'd like to consider
      ///Lastly we will do the comparison mentioned above to see if it fresh enough. If not, we will move to the guard
      if let preferredCacheDuration = requestObject.preferredCacheDuration,
         let cacheURL = requestObject.cacheURL,
         let cacheModificationDate = FileManagementService.fileModificationDate(atPath: cacheURL),
         Date().timeIntervalSince(cacheModificationDate) <= preferredCacheDuration {
        
        completion(requestObject.urlConstructor.path.absolute, cachedData, nil, NetworkingService.StatusUsingCacheBaseRequestObjectPreference)
        return
        
      } else {
        
        ///Check if the network is available
        guard networkAvailable else {
          
          ///If we have designated a retry interval for this request to execute, then add this item to the sharedNetworkingQueue. The purpose of this is for uploading information that is crucial to the client's usage, regardless of any UI changes. Note, this will allow the request to fire but has no knowledge of the completion handler, so use this for requests like sending up information about the client that can be refreshed locally using some sort of fetch for that info again (i.e. sending patient info up in healthcare or user preferences for following other users).
          if let retryInterval = retryInterval {
            sharedNetworkingQueue[UUID()] = .init(request: requestObject, executionTime: retryInterval)
            self.saveQueueAndRefresh()
          }
          
          ///Execute the completion handler, notifying the recipient of the URL used and the local/custom status code signifying that no network is available
          completion(requestObject.urlConstructor.path.absolute, cachedData, nil, NetworkingService.StatusNoNetworkAvailableCode)
          return
        }
        
        ///Reaching this point means we have a network connection. If so, unwrap the URL. If you fail, once more, notify the recipient/execute the callback with the code designated for URLFailedToUnwrap
        guard let url = URL(string: requestObject.urlConstructor.path.absolute) else {
          completion(requestObject.urlConstructor.path.absolute, cachedData, nil, NetworkingService.StatusURLFailedToUnwrap)
          return
        }
        
        ///Reaching this point means the URL is valid and you can assemble the URLRequest
        URLCache.shared.removeAllCachedResponses()
        var urlRequest = URLRequest(url: url)
        
        ///Add request headers
        let allHeaders = self.headerValues.merging(requestObject.allHeaders) { selfVal, paramVal in
          paramVal
        }
        urlRequest.headers = HTTPHeaders(allHeaders)
        
        ///Add requestbody
        urlRequest.httpBody = requestObject.httpBody
        
        ///Remove CachedResponses from URLCache. Note, this has nothing to do with the custom caching mechanism we have created using the FileSystem
        URLCache.shared.removeCachedResponse(for: urlRequest)
        
        ///Set the Request Method (.get, .post, etc.)
        urlRequest.httpMethod = requestObject.method.rawValue
        
        ///Run the request with Alamofire
        let request = AF.request(urlRequest)
        
        request.responseJSON { (data) in
          ///Run the completion handler with the response of the request
          completion(requestObject.urlConstructor.path.absolute, (data.data ?? cachedData), urlRequest, request.response?.statusCode)
        }
      }
    }
}

//MARK: - Status Code
public extension NetworkingService {
  @available(*, unavailable, renamed: "StatusNoNetworkAvailableCode")
  static let NoNetworkAvailableCode = -9283615282
  
  static let StatusNoNetworkAvailableCode = -9283615282
  static let StatusURLFailedToUnwrap = -3710235719
  static let StatusUsingFallbackCache = -7355019231
  static let StatusUsingCacheBaseRequestObjectPreference = -4628701921
}
