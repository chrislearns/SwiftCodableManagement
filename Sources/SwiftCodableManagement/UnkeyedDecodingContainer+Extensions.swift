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
//            print("type -> \(heterogenousType)")
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
//    print("decoding nested object -> \(heterogenousSuperType.codedKey()) + \(uniqueRoundID)")
//    print("Looking for object at key -> \(forKey.stringValue) + \(uniqueRoundID)")
    let containerCopy = container
    let encodedHeterogenousObject = try container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: forKey)
//    print("heterogenousObject = \(encodedHeterogenousObject) + \(uniqueRoundID)")
//    print("HERE: \(uniqueRoundID)")
    let heterogenousType = try encodedHeterogenousObject.decode(U.self, forKey: .init(U.codedKey()))
//        print("superType -> \(heterogenousSuperType) + \(uniqueRoundID)")
//    print("subType -> \(heterogenousType.toType()) + \(uniqueRoundID)")
    
    let object = try heterogenousType.toType().init(from: containerCopy.superDecoder(forKey: forKey))
    
//    print(object)
    
    return object
            
       
        
    
    
}
