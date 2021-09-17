//
//  APIURLConstructor.swift
//  
//
//  Created by Christopher Guirguis on 9/2/21.
//

import SwiftUI

public class APIURLConstructor{
    public init(
        root: String,
        constructorPathItems: [String]
    ){
        self.constructorPathItems = constructorPathItems
        self.root = root
    }
    public var root:String
    public var constructorPathItems:[String]
    
    public func path(_ itemID:String) -> String{
        root + constructorPathItems.map{$0}.joined() + itemID
    }
}

