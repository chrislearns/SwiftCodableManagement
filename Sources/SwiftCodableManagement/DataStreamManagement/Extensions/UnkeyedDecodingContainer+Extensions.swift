//
//  UnkeyedDecodingContainer+Extensions.swift
//  Revenite
//
//  Created by Christopher Guirguis on 4/21/21.
//

import SwiftUI

public extension UnkeyedDecodingContainer {
    mutating func decodeNested<T>(_ type: T.Type, keyString: String) throws -> T where T : Decodable {
        let nestedContainer = try self.nestedContainer(keyedBy: AnyCodingKey.self)
        return try nestedContainer.decode(T.self, forKey: .init(keyString))
    }
}

public func decodeNestedHeterogenousArray<U:InheritanceDecodeTypable>(container: KeyedDecodingContainer<AnyCodingKey>, forKey: AnyCodingKey, heterogenousSuperType:U.Type) -> [U.T] {
    do {
        var encodedHeterogenousArray = try container.nestedUnkeyedContainer(forKey: forKey)
        var copiedArray = encodedHeterogenousArray
        
        var decodedObjects = [U.T]()
        while(!encodedHeterogenousArray.isAtEnd){
            let heterogenousType = try encodedHeterogenousArray.decodeNested(U.self, keyString: U.codedKey())
            decodedObjects.append(try copiedArray.decode(heterogenousType.toType()))
        }
        
        return decodedObjects
        
    }
    catch {
        return []
    }
}

public func decodeNestedHeterogenousObject<U:InheritanceDecodeTypable>(container: KeyedDecodingContainer<AnyCodingKey>, forKey: AnyCodingKey, heterogenousSuperType:U.Type) throws -> U.T {
    _ = UUID().uuidString.prefix(4)
    let containerCopy = container
    let encodedHeterogenousObject = try container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: forKey)
    let heterogenousType = try encodedHeterogenousObject.decode(U.self, forKey: .init(U.codedKey()))
    let object = try heterogenousType.toType().init(from: containerCopy.superDecoder(forKey: forKey))
    return object
            
       
        
    
    
}
