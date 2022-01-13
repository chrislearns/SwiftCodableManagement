//
//  SwiftUIView.swift
//  
//
//  Created by Christopher Guirguis on 1/13/22.
//

import SwiftUI

public struct QueuedNetworkRequest: Codable, Hashable {
  public var request: SimpleNetworkRequest
  public var executionTime: ExecutionTime
  
  public enum ExecutionTime: String, Codable, CaseIterable {
    case atStart
    case immediately
    
    case q5sec
    case q1min
    case q5min
    case q10min
    case q15min
    case q30min
    case q1h
    case q2h
    case q4h
    case q6h
    case q12h
    case q1daily
    
    public var interval: Int? {
      switch self {
      case .atStart:
        return nil
      case .immediately:
        return nil
      case .q5sec:
        return 5
      case .q1min:
        return 60
      case .q5min:
        return 300
      case .q10min:
        return 600
      case .q15min:
        return 900
      case .q30min:
        return 1800
      case .q1h:
        return 3600
      case .q2h:
        return 7200
      case .q4h:
        return 14400
      case .q6h:
        return 21600
      case .q12h:
        return 43200
      case .q1daily:
        return 86400
      }
    }
  }
}
