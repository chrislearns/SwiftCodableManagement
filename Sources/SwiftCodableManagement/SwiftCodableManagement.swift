import SwiftUI

//This struct is critical to flexible de-nesting of codable objects that may need to be flexibly decoded due to patterns of superclass -> subclass inheritance
struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init(_ string: String) {
        stringValue = string
    }
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}
