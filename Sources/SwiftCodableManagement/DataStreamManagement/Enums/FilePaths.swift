//
//  SwiftUIView.swift
//  
//
//  Created by Christopher Guirguis on 12/20/21.
//

import SwiftUI

extension FileManagementService {
  static var documentDirectory: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
  
  static var cacheDirectory: URL? {
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
  
  static func directoryForPathString(baseURL: URL?, pathString: String) -> URL? {
    
    if let url = baseURL {
      
      let directory = url
        .appendingPathComponent(pathString, isDirectory: true)
      
      if FileManager.default.fileExists(atPath: directory.path, isDirectory: nil) == false {
        do {
          try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        } catch {
          return nil
        }
      }
      
      return directory
      
    } else {
      return nil
    }
  }
  
}
