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
  static func log(_ any: Any?){
      print("[SCM LOG] 🕸 \(any as Any)")
  }
}
