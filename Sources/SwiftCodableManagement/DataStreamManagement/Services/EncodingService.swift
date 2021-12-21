//
//  EncodingService.swift
//  Revenite
//
//  Created by Christopher Guirguis on 4/24/21.
//

import SwiftUI

public class EncodingService:ObservableObject {
  
  public static let shared = EncodingService(
    dateDecodingStrategy: .iso8601withFractionalSeconds,
    dateEncodingStrategy: .iso8601withFractionalSeconds
  )
  
  public init(
    dateDecodingStrategy:JSONDecoder.DateDecodingStrategy = .iso8601,
    dataDecodingStrategy:JSONDecoder.DataDecodingStrategy = .base64,
    dateEncodingStrategy:JSONEncoder.DateEncodingStrategy = .iso8601,
    dataEncodingStrategy:JSONEncoder.DataEncodingStrategy = .base64
  ){
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    encoder.dataEncodingStrategy = dataEncodingStrategy
    encoder.dateEncodingStrategy = dateEncodingStrategy
    
    let cacheingEncoder = CacheingEncoder()
    encoder.outputFormatting = .prettyPrinted
    encoder.dataEncodingStrategy = dataEncodingStrategy
    encoder.dateEncodingStrategy = dateEncodingStrategy
    
    let decoder = JSONDecoder()
    decoder.dataDecodingStrategy = dataDecodingStrategy
    decoder.dateDecodingStrategy = dateDecodingStrategy
    
    self.encoder = encoder
    self.cacheingEncoder = cacheingEncoder
    self.decoder = decoder
  }
  
  public var encoder: JSONEncoder
  public var cacheingEncoder: JSONEncoder
  public var decoder: JSONDecoder
  
  //Example of use: EncodingService.encode(dummyMattUser)
  public func encode<T:Encodable>(_ object: T, forLocalContentCache: Bool = false) -> Data?{
    do {
      let encodedObject: Data = try {
        if forLocalContentCache {
          return try cacheingEncoder.encode(object)
        } else {
          return try encoder.encode(object)
        }
      }()
      return encodedObject
    } catch {
      print("failed to encode")
    }
    return nil
  }
  
  public func decodeData<T>(
    _ data:Data,
    type:T.Type,
    dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil,
    dataDecodingStrategy: JSONDecoder.DataDecodingStrategy? = nil
  ) -> T? where T: Decodable{
    do {
      let unwrap = try decoder.decode(T.self, from: data)
      return unwrap
    }
    catch {
      print(String(decoding: data, as: UTF8.self))
      print("failed to decode object -> \(type.self)")
    }
    return nil
  }
}

public class CacheingEncoder: JSONEncoder {
}
