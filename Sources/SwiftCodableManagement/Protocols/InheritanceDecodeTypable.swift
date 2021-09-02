//
//  InheritanceDecodeTypable.swift
//  
//
//  Created by Christopher Guirguis on 9/2/21.
//

import SwiftUI

public protocol InheritanceDecodeTypable:Decodable {
    associatedtype T:Decodable
    func toType() -> T.Type
    static func codedKey() -> String
}
