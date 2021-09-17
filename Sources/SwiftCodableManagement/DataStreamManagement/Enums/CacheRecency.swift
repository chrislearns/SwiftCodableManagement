//
//  CacheRecency.swift
//  
//
//  Created by Christopher Guirguis on 9/2/21.
//

import SwiftUI

public enum CacheRecency:Int {
    case minute = 60
    case minute5 = 300
    case minute15 = 900
    case minute30 = 1800
    case hour = 3600
    case hour2 = 7200
    case hour4 = 14400
    case hour8 = 28800
    case hour12 = 43200
    case day = 86400
    case week = 604800
    case infinity = 9999999999
    
    public func comparedTimeIsExpired(_ comparedTime: TimeInterval) -> Bool{
        let desiredCacheTime = self.rawValue
        let comparedTime = Int(comparedTime)
        
        return comparedTime >= desiredCacheTime
    }
}
