//
//  SwiftUIView.swift
//  
//
//  Created by Christopher Guirguis on 9/2/21.
//

import SwiftUI

public extension Data {
    init(reading input: InputStream) throws {
        self.init()
        input.open()
        defer {
            input.close()
        }
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            if read < 0 {
                //Stream error occured
                throw input.streamError!
            } else if read == 0 {
                //EOF
                break
            }
            self.append(buffer, count: read)
        }
    }
    
    func toObject<T:Codable>(type: T.Type, encodingService: EncodingService?) -> T?{
        (encodingService ?? EncodingService()).decodeData(self, type: T.self)
    }
}
