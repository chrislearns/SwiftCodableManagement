//
//  SwiftUIView.swift
//  
//
//  Created by Christopher Guirguis on 6/21/22.
//

import SwiftUI

class SCMGeneralHelper {
  static var shared = SCMGeneralHelper()
  
  var shouldLog = false
}

//MARK: LOGGING
extension SCMGeneralHelper {
  static func log(_ any: Any?){
    if SCMGeneralHelper.shared.shouldLog {
      print("🕸 \(any as Any)")
    }
  }
}
