//
//  APIURLConstructor.swift
//  
//
//  Created by Christopher Guirguis on 9/2/21.
//

import SwiftUI

public struct APIURLConstructor: Codable, Equatable, Hashable{
    public init(
        root: String,
        constructorPathItems: [String]
        
    ){
        self.constructorPathItems = constructorPathItems
        self.root = root
    }
    public var root:String
    public var constructorPathItems:[String]
    
  public var path: (absolute: String, relativeToRoot: String){
    let relative = constructorPathItems.map{$0}.joined()
        
    let absolute = root + relative
    
    return (absolute, relative)
    }
}

