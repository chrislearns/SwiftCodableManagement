//
//  CacheConstructorReversible.swift
//  
//
//  Created by Christopher Guirguis on 9/2/21.
//

import SwiftUI

//This protocol requires the presence of a CacheNameConstructor which allows for easy generation of the constructed cache name via a computed variable
public protocol CacheConstructorReversible:Codable {
    var cacheNameConstructor:CacheNameConstructor { get }
}
