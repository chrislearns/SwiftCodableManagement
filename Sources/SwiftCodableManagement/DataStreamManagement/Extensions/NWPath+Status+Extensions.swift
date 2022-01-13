//
//  SwiftUIView.swift
//  
//
//  Created by Christopher Guirguis on 1/13/22.
//

import SwiftUI
import Network

extension NWPath.Status {
  var isAvailableAsBool: Bool {
    switch self {
    case .satisfied:
      return true
    case .requiresConnection, .unsatisfied:
      return false
    @unknown default:
      return false
    }
  }
}
