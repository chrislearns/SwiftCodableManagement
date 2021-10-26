//
//  SwiftUIView.swift
//  
//
//  Created by Christopher Guirguis on 9/17/21.
//

import SwiftUI
import Alamofire

public enum SCMHTTPMethod: String {
    case get = "GET"
    case post = "POST"
    
    var httpMethod: HTTPMethod {
        switch self {
        case .get:
            return .get
        case .post:
            return .post
        }
    }
}
