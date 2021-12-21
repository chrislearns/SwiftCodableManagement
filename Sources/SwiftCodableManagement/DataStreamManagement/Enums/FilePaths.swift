//
//  SwiftUIView.swift
//  
//
//  Created by Christopher Guirguis on 12/20/21.
//

import SwiftUI

extension FileManagementService {
  private static var documentDirectory: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
  
  private static var cacheDirectory: URL? {
    if let url = documentDirectory {
      
      let directory = url
        .appendingPathComponent(FilePaths.cache.rawValue, isDirectory: true)
      
      if FileManager.default.fileExists(atPath: directory.path, isDirectory: nil) == false {
        
        do {
          try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        } catch {
          return nil
        }
      }
      
      return directory
      
    }
    
    return nil
  }
  
  static var cachedRequestsURL: URL? {
    return cacheDirectory?
      .appendingPathComponent(FilePaths.requests.rawValue, isDirectory: false)
  }
  
  enum FilePaths: String {
    //MARK: Directories
    case cache
    
    //MARK: Files
    case requests = "requests.json"
  }
  
}
