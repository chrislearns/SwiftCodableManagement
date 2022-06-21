//
//  SwiftUIView.swift
//  
//
//  Created by Christopher Guirguis on 1/13/22.
//

import SwiftUI

extension Encodable {
  public func writeToFile(url: URL, forLocalContentCache: Bool = false) -> Bool {
    guard let data = EncodingService.shared.encode(self, forLocalContentCache: forLocalContentCache) else { return false }
    do {
      try data.write(to: url)
      return true
    } catch {
      SCMGeneralHelper.log(error)
      return false
    }
  }
}
