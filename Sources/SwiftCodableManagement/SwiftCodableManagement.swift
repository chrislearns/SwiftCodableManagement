import SwiftUI

//This struct is critical to flexible de-nesting of codable objects that may need to be flexibly decoded due to patterns of superclass -> subclass inheritance
public struct AnyCodingKey: CodingKey {
    public var stringValue: String
    public var intValue: Int?
    
    public init(_ string: String) {
        stringValue = string
    }
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    public init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}
