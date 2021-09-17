//
//  CacheNameConstructor.swift
//  
//
//  Created by Christopher Guirguis on 9/2/21.
//

import SwiftUI

public struct CacheNameConstructor{
    public init(prefix: String, suffix: String, uniqueIdentifier: String? = nil) {
        self.prefix = prefix
        self.suffix = suffix
        self.uniqueIdentifier = uniqueIdentifier
    }
    public var prefix:String
    public var suffix:String
    
    public var uniqueIdentifier:String?
    
    public var constructedCacheName:String{
        return prefix
            + (uniqueIdentifier == nil ? "" : "_") + (uniqueIdentifier ?? "")
            + suffix
    }
}
