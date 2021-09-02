//
//  EncodingService.swift
//  Revenite
//
//  Created by Christopher Guirguis on 4/24/21.
//

import SwiftUI

class EncodingService:ObservableObject {
    
    //Example of use: EncodingService.encode(dummyMattUser)
    static func encode<T:Encodable>(_ object: T) -> Data?{
        let encoder = JSONEncoder()
        do {
            let encodedObject = try encoder.encode(object)
            return encodedObject
        }
        catch {
            print("failed to encode")
        }
        return nil
    }

    static func decodeData<T>(_ data:Data, type:T.Type) -> T? where T: Decodable{
        print("decoding -> \(type.self)")
        
        let decoder = JSONDecoder()
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
