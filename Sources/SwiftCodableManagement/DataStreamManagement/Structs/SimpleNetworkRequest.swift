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
              httpBody: Data?,
              authHeader: [String : String],
              method: HTTPMethod,
              auxiliaryHeaders: [String : String],
              cachePathSuffix: String? = nil
  ) {
    self.preferredCacheDuration = preferredCacheDuration
    self.urlConstructor = urlConstructor
    self.httpBody = httpBody
    self.authHeader = authHeader
    self.method = method
    self.auxiliaryHeaders = auxiliaryHeaders
    self.cachePathSuffix = cachePathSuffix
  }
  ///If preferredCacheDuration is nil then we will never prefer cached info over fresh info
  public var preferredCacheDuration: Double?
  public var cachePathSuffix: String?
  public var urlConstructor: APIURLConstructor
  public var httpBody: Data?
  public var authHeader: [String: String]
  public var method: HTTPMethod
  public var auxiliaryHeaders: [String: String]
  public var allHeaders:[String:String]{
    authHeader.mergeDicts(auxiliaryHeaders)
  }
  
  var cacheURL: URL? {
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
}
