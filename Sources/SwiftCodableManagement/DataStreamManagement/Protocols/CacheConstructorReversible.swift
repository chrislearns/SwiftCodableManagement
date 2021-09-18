//
//  CacheConstructorReversible.swift
//  
//
//  Created by Christopher Guirguis on 9/2/21.
//

import SwiftUI

//This protocol requires the presence of a CacheNameConstructor which allows for easy generation of the constructed cache name via a computed variable
public protocol CacheConstructorReversible:Codable {
    var id: UUID { get set }
    
    static var cachePrefix: String { get }
    static var cacheSuffix: String { get }
}

extension CacheConstructorReversible {
    public var cacheNameConstructor:CacheNameConstructor {
        .init(prefix: Self.cachePrefix, suffix: Self.cacheSuffix, uniqueIdentifier: id.uuidString)
    }
}
