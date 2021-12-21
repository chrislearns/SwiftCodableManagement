//
//  SwiftUIView.swift
//  
//
//  Created by Chris Guirguis on 10/13/21.
//

import SwiftUI
import SweetSimpleSwift

public extension String {
    
    func iso8601withFractionalSecondsToDate(encodingService: EncodingService? = nil) throws -> Date {
        let encodingService = encodingService ?? .init()
        encodingService.encoder.dateEncodingStrategy = .iso8601withFractionalSeconds
        encodingService.decoder.dateDecodingStrategy = .iso8601withFractionalSeconds
        let data = try encodingService.encoder.encode(self)
       
        let decodedDate = try encodingService.decoder.decode(Date.self, from: data)
       
        return decodedDate
    }
}
