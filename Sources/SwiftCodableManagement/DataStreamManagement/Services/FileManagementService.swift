//
//  FileManagementService.swift
//  Revenite
//
//  Created by Christopher Guirguis on 8/6/21.
//

import SwiftUI

public class FileManagementService: ObservableObject {
    public enum SubfolderPaths: String {
        case sequences = "/sequences"
    }
    
    public static func saveObjectToDisc<T:Encodable>(
        object:T,
        filename:String,
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        subfolder: [SubfolderPaths] = []
    ) -> URL? {
        print("beginning to save \(filename)")
        guard let data = EncodingService.encode(object) else { return nil}
        
        guard let documentDirectoryUrl = FileManager.default.urls(for: directory, in: .userDomainMask).first else { return nil}
        
        let subfolderUrl = documentDirectoryUrl.appendingPathComponent(subfolder.map{$0.rawValue}.joined())
        FileManagementService.createSubfolder(subfolder: subfolderUrl.relativePath)
        let fileUrl = subfolderUrl.appendingPathComponent("\(filename)")
        
        do {
            
            try data.write(to: fileUrl, options: [])
            print("successfully saved \(filename)")
            return fileUrl
        } catch {
            print(error)
        }
        return nil
    }
    
    public static func retrieveObjectFromDisc(
        filename:String,
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        subfolder: [SubfolderPaths] = []
    ) -> Data? {
        guard let documentDirectoryUrl = FileManager.default.urls(for: directory, in: .userDomainMask).first else { return nil}
        
        let subfolderUrl = documentDirectoryUrl.appendingPathComponent(subfolder.map{$0.rawValue}.joined())
        let fileUrl = subfolderUrl.appendingPathComponent("\(filename)")
        do {
            //Try to check for this files attributes
            guard let stream = InputStream(url: fileUrl) else {return nil}
            stream.open()
            defer {
                stream.close()
            }
            
            // Read data from .json file and transform data into an array
            let data = try Data.init(reading: stream)
            return data
            
            
        } catch {
            print(error)
            return nil
        }
        
    }
    
    public static func retrieveObjectFromDisc(url: URL) -> Data? {
        do {
            //Try to check for this files attributes
            guard let stream = InputStream(url: url) else {return nil}
            stream.open()
            defer {
                stream.close()
            }
            
            // Read data from .json file and transform data into an array
            let data = try Data.init(reading: stream)
            return data
            
            
        } catch {
            print(error)
            return nil
        }
        
    }
    
    public static func enumerateFilesInFolder(
        for directory: FileManager.SearchPathDirectory,
        subfolder: [FileManagementService.SubfolderPaths] = [],
        skipsHiddenFiles: Bool = true ) -> [URL]? {
        let documentsURL = FileManager.default.urls(for: directory, in: .userDomainMask)[0].appendingPathComponent(subfolder.map{$0.rawValue}.joined())
        let fileURLs = try? FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [])
        return fileURLs
    }
    
    public static func createSubfolder(subfolder: String){
        if !FileManager.default.fileExists(atPath: subfolder) {
            do{
                try FileManager.default.createDirectory(atPath: subfolder, withIntermediateDirectories: true, attributes: nil)
            }
            catch (let error){
                print("Failed to create Directory: \(error.localizedDescription)")
            }
        }
        
    }
}