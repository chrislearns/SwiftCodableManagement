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
              httpBody: Data?,
              authHeader: [String : String],
              method: HTTPMethod,
              auxiliaryHeaders: [String : String],
              cachePathSuffix: String? = nil
  ) {
    self.urlConstructor = urlConstructor
    self.httpBody = httpBody
    self.authHeader = authHeader
    self.method = method
    self.auxiliaryHeaders = auxiliaryHeaders
    self.cachePathSuffix = cachePathSuffix
  }
  
  public var cachePathSuffix: String?
  public var urlConstructor: APIURLConstructor
  public var httpBody: Data?
  public var authHeader: [String: String]
  public var method: HTTPMethod
  public var auxiliaryHeaders: [String: String]
  public var allHeaders:[String:String]{
    authHeader.mergeDicts(auxiliaryHeaders)
  }
}
