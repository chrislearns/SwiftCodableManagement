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
        Global.printDev(String(data: data, encoding: .utf8)!)
        return data
        
        
    }
    
    public func data(encodingService: EncodingService) throws -> Data {
        try JSONSerialization.data(withJSONObject:self)
        
    }
    
}
