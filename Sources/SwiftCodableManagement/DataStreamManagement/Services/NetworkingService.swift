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
  
  public static let NoNetworkAvailableCode = -100
  public var headerValues: [String:String]
  private var timers: [Timer] = []
  @Published public var sharedNetworkingQueue: [UUID:QueuedNetworkRequest] = [:]
  var queueAction: ((QueuedNetworkRequest) -> ())?
  let monitor = NWPathMonitor()
  @Published public var networkAvailable: Bool
  
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
        if let item: [UUID: QueuedNetworkRequest] = FileManagementService.readFile(from: cacheURL) {
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
       let item: [UUID: QueuedNetworkRequest] = FileManagementService.readFile(from: cacheURL) {
      self.sharedNetworkingQueue = item
    }
  }
  
}

//MARK: - Request Related Items
public extension NetworkingService {
  
  func simpleRequestToObject<T: Codable>(
    type:T.Type,
    requestObject: SimpleNetworkRequest,
    cacheRequestObject: Bool = false,
    retryInterval: QueuedNetworkRequest.ExecutionTime?,
    encodingService: EncodingService? = nil,
    completion: @escaping (_ obj: T?, _ url: String, _ data: Data?, _ request: URLRequest?, _ statusCode: Int?) -> ()){
      simpleRequest(requestObject: requestObject, retryInterval: retryInterval) { url, data, request, statusCode in
        let baseURL = FileManagementService.cacheDirectory
        let subfolderURL = FileManagementService.directoryForPathString(baseURL: baseURL, pathString: requestObject.urlConstructor.path.relativeToRoot.pathString)
        let cacheSuffixURL:URL? = {
          guard let cachePathSuffix = requestObject.cachePathSuffix else {
            return subfolderURL
          }

          return FileManagementService.directoryForPathString(baseURL: subfolderURL, pathString: cachePathSuffix)
          
          
        }()
        
        let cacheURL = cacheSuffixURL?.appendingPathComponent("object.json", isDirectory: false)
        guard let object = data?.toObject(type: T.self, encodingService: encodingService) else {
          let cachedItem: T? = {
            if let cacheURL = cacheURL {
              let cachedItem: T? = FileManagementService.readFile(from: cacheURL)
              if let _ = cachedItem {
                print("Fetched cached item as packup: \(type) @ \(requestObject.urlConstructor.path.relativeToRoot.pathString)")
              }
              return cachedItem
            } else {
              return nil
            }
          }()
          
          completion(cachedItem, url, data, request, statusCode)
          return
        }
        
        if cacheRequestObject, let cacheURL = cacheURL {
          if object.writeToFile(url: cacheURL, forLocalContentCache: true) {
            print("Cached \(type) @ \(requestObject.urlConstructor.path.relativeToRoot.pathString)")
          } else {
            print("Failed to cache \(type) @ \(cacheURL)")
          }
        }
        completion(object, url, data, request, statusCode)
      }
    }
  
  func simpleRequest(
    requestObject: SimpleNetworkRequest,
    retryInterval: QueuedNetworkRequest.ExecutionTime?,
    completion: @escaping (_ url: String, _ data: Data?, _ request: URLRequest?, _ statusCode: Int?) -> ()){
      
      guard networkAvailable else {
        if let retryInterval = retryInterval {
          sharedNetworkingQueue[UUID()] = .init(request: requestObject, executionTime: retryInterval)
          self.saveQueueAndRefresh()
        }
        completion(requestObject.urlConstructor.path.absolute, nil, nil, NetworkingService.NoNetworkAvailableCode)
        return
      }
      
      guard let url = URL(string: requestObject.urlConstructor.path.absolute) else {
        completion(requestObject.urlConstructor.path.absolute, nil, nil, nil)
        return
      }
      
      URLCache.shared.removeAllCachedResponses()
      var urlRequest = URLRequest(url: url)
      let allHeaders = self.headerValues.merging(requestObject.allHeaders) { selfVal, paramVal in
        paramVal
      }
//      print("headers = \(allHeaders)")
      urlRequest.headers = HTTPHeaders(allHeaders)
      urlRequest.httpBody = requestObject.httpBody
      
      
      URLCache.shared.removeCachedResponse(for: urlRequest)
      urlRequest.httpMethod = requestObject.method.rawValue
      
      let request = AF.request(urlRequest)
      
      request.responseJSON { (data) in
        completion(requestObject.urlConstructor.path.absolute, data.data, urlRequest, request.response?.statusCode)
      }
    }
}
