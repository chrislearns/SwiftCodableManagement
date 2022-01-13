//
//  SwiftUIView.swift
//  
//
//  Created by Christopher Guirguis on 1/13/22.
//

import SwiftUI

public enum HeaderValues{
  case contentType_applicationJSONCharsetUTF8
  
  public func value() -> [String:String] {
    switch self {
    case .contentType_applicationJSONCharsetUTF8:
      return ["Content-Type":"application/json; charset=utf-8"]
    }
  }
}
