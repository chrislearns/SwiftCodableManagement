//
//  SwiftUIView.swift
//  
//
//  Created by Christopher Guirguis on 9/2/21.
//

import SwiftUI

public class APIURLConstructor{
    public init(
        constructorPathItems:[String]
    ){
        self.constructorPathItems = constructorPathItems
    }
    public var root = "https://chrisguirguis.com/revenitedummyapi/"
    public var constructorPathItems:[String]
    
    public func path(_ itemID:String) -> String{
        root + constructorPathItems.map{$0}.joined() + itemID
    }
}

