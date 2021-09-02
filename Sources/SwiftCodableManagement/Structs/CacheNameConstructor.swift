//
//  CacheNameConstructor.swift
//  
//
//  Created by Christopher Guirguis on 9/2/21.
//

import SwiftUI

public struct CacheNameConstructor{
    public init(prefix: CachePrefix, suffix: CacheSuffix, uniqueIdentifier: String? = nil) {
        self.prefix = prefix
        self.suffix = suffix
        self.uniqueIdentifier = uniqueIdentifier
    }
    public var prefix:CachePrefix
    public var suffix:CacheSuffix
    
    public var uniqueIdentifier:String?
    
    public var constructedCacheName:String{
        return prefix.rawValue
            + (uniqueIdentifier == nil ? "" : "_") + (uniqueIdentifier ?? "")
            + suffix.rawValue
    }
}
