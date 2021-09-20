//
//  EncodingService.swift
//  Revenite
//
//  Created by Christopher Guirguis on 4/24/21.
//

import SwiftUI

public class EncodingService:ObservableObject {
    
    public init(
        dateDecodingStrategy:JSONDecoder.DateDecodingStrategy = .iso8601,
        dataDecodingStrategy:JSONDecoder.DataDecodingStrategy = .base64,
        dateEncodingStrategy:JSONEncoder.DateEncodingStrategy = .iso8601,
        dataEncodingStrategy:JSONEncoder.DataEncodingStrategy = .base64
    ){
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = dataEncodingStrategy
        encoder.dateEncodingStrategy = dateEncodingStrategy
        
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = dataDecodingStrategy
        decoder.dateDecodingStrategy = dateDecodingStrategy
        
        self.encoder = encoder
        self.decoder = decoder
    }
    
    var encoder: JSONEncoder
    var decoder: JSONDecoder
    
    //Example of use: EncodingService.encode(dummyMattUser)
    public func encode<T:Encodable>(_ object: T) -> Data?{
        do {
            let encodedObject = try encoder.encode(object)
            return encodedObject
        }
        catch {
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
        print("decoding -> \(type.self)")
        do {
            let unwrap = try decoder.decode(T.self, from: data)
            print("object decoded")
            return unwrap
        }
        catch {
            print(String(decoding: data, as: UTF8.self))
            print("failed to decode object -> \(type.self)")
        }
        return nil
    }
}
