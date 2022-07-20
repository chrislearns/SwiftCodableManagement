//
//  SwiftUIView.swift
//  
//
//  Created by Christopher Guirguis on 6/21/22.
//

import SwiftUI

class SCMGeneralHelper {
  static var shared = SCMGeneralHelper()
  
}

//MARK: LOGGING
extension SCMGeneralHelper {
  private static func log(_ any: Any?){
    guard let any = any else { return }
      print("[LOG] 🍣 \(any)")
  }
  
  enum Log {
    static func timedEvent(_ any: Any?){
      if NetworkingService.logTypes.contains(.timedEvents){
        SCMGeneralHelper.Log.info(any)
      }
    }
    static func info(_ any: Any?){
      if NetworkingService.logTypes.contains(.info){
        SCMGeneralHelper.Log.info(any)
      }
    }
    
    static func verbose(_ any: Any?){
      if NetworkingService.logTypes.contains(.verbose){
        SCMGeneralHelper.Log.info(any)
      }
    }
    
  }
}
