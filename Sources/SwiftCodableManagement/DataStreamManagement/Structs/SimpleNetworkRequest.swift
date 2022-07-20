//
//  SwiftUIView.swift
//  
//
//  Created by Christopher Guirguis on 1/13/22.
//

import SwiftUI
import Alamofire

public struct SimpleNetworkRequest: Codable, Hashable {
  public init(urlConstructor: APIURLConstructor,
              preferredCacheDuration: Double? = nil,
              prepopulateWithCache: Bool = false,
              httpBody: Data?,
              authHeader: [String : String],
              method: HTTPMethod,
              auxiliaryHeaders: [String : String],
              cachePathSuffix: String? = nil
  ) {
    self.prepopulateWithCache = prepopulateWithCache
    self.preferredCacheDuration = preferredCacheDuration
    self.urlConstructor = urlConstructor
    self.httpBody = httpBody
    self.authHeader = authHeader
    self.method = method
    self.auxiliaryHeaders = auxiliaryHeaders
    self.cachePathSuffix = cachePathSuffix
  }
  
  ///`preferredCacheDuration` vs `prepopulateWithCache`
  ///Using `preferredCacheDuration` will only use the cached info if it fits the time limit  criteria
  ///Using `prepopulateWithCache` will use the cache if its there regardless of its age, while also fetching new info and running the same completion handler with that info when it returns asynchronously
  
  ///If preferredCacheDuration is nil then we will never prefer cached info over fresh info.
  public var preferredCacheDuration: Double?
  ///If you set this to true then the completion handler will run once using your last cached information (if you have any) and then again when the network comes back with fresh information.
  public var prepopulateWithCache: Bool
  public var cachePathSuffix: String?
  public var urlConstructor: APIURLConstructor
  public var httpBody: Data?
  public var authHeader: [String: String]
  public var method: HTTPMethod
  public var auxiliaryHeaders: [String: String]
  public var allHeaders:[String:String]{
    authHeader.mergeDicts(auxiliaryHeaders)
  }
  
  public var cacheURL: URL? {
    let baseURL = FileManagementService.cacheDirectory
    let subfolderURL = FileManagementService.directoryForPathString(baseURL: baseURL, pathString: self.urlConstructor.path.relativeToRoot.pathString)
    let cacheSuffixURL:URL? = {
      guard let cachePathSuffix = self.cachePathSuffix else {
        return subfolderURL
      }
      return FileManagementService.directoryForPathString(baseURL: subfolderURL, pathString: cachePathSuffix)
    }()
    
    return cacheSuffixURL?.appendingPathComponent("object.json", isDirectory: false)
  }
  
  ///This requires the networking service because the esrvice (on launch) is given header values that this will pul from for context
  public func toURLRequest(networkingService: NetworkingService) -> URLRequest? {
    guard let url = URL(string: self.urlConstructor.path.absolute) else {
      return nil
    }
    
    ///Reaching this point means the URL is valid and you can assemble the URLRequest
    URLCache.shared.removeAllCachedResponses()
    
    var urlRequest = URLRequest(url: url)
    
    ///Add request headers
    let allHeaders = networkingService.headerValues.merging(self.allHeaders) { selfVal, paramVal in
      paramVal
    }
    urlRequest.headers = HTTPHeaders(allHeaders)
    
    ///Add requestbody
    urlRequest.httpBody = self.httpBody
    
    ///Remove CachedResponses from URLCache. Note, this has nothing to do with the custom caching mechanism we have created using the FileSystem
    URLCache.shared.removeCachedResponse(for: urlRequest)
    
    ///Set the Request Method (.get, .post, etc.)
    urlRequest.httpMethod = self.method.rawValue
    return urlRequest
  }
}
