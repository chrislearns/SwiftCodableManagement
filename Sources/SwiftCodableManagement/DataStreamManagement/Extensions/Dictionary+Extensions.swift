//
//  File.swift
//  
//
//  Created by Christopher Guirguis on 11/22/21.
//

import Foundation

public extension Dictionary{
    public func toJSON(encoder: JSONEncoder) throws -> Data? where Value: Codable, Key == String{
        
        let data = try encoder.encode(self)
        return data
        
        
    }
    
    public func data(encodingService: EncodingService) throws -> Data {
        try JSONSerialization.data(withJSONObject:self)
        
    }
    
    
    public func mergeDicts(_ dict2: [Key: Value]) -> [Key: Value] {
        var result = self
        for (key, value) in dict2 {
            if let resultValue = result[key] {
                result[key] = resultValue
            } else {
                result[key] = value
            }
        }
        return result
    }
    
    
    
    
    
}
