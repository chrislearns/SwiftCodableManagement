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
  
  public static let shared = NetworkingService()
  
  public static let NoNetworkAvailableCode = -100
  public var headerValues: [String:String]
  private var timers: [Timer] = []
  @Published public var sharedNetworkingQueue: [UUID:QueuedNetworkRequest] = [:]
  var queueAction: ((QueuedNetworkRequest) -> ())?
  let monitor = NWPathMonitor()
  @Published public var networkAvailable: Bool
  
  public init(
    headerValues: [String:String] = HeaderValues.contentType_applicationJSONCharsetUTF8.value(),
    queueAction: ((QueuedNetworkRequest) -> ())? = nil
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
    print("Executing items queued on interval of \(interval) - count: \(requests.count)")
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
  
  func simpleRequest(
    requestObject: SimpleNetworkRequest,
    retryInterval: QueuedNetworkRequest.ExecutionTime?,
    completion: @escaping (_ url: String, _ data: Data?, _ request: URLRequest?, _ statusCode: Int?) -> ()){
      
      guard networkAvailable else {
        if let retryInterval = retryInterval {
          sharedNetworkingQueue[UUID()] = .init(request: requestObject, executionTime: retryInterval)
          self.saveQueueAndRefresh()
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
    @unknown default:
      return false
    }
  }
}
