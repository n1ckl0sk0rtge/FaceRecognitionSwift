//
//  FileSystemController.swift
//  Travellout
//
//  Created by Nicklas Körtge on 29.07.20.
//  Copyright © 2020 Nicklas Körtge. All rights reserved.
//

import Foundation
import UIKit

class ImageStorageController {
    
    enum ImageStorageControllerError : Error {
        case storeImage(message: String)
        case retrieveImage(message: String)
        case deleteImage(message: String)
    }
    
    func storeImage(image: UIImage) throws -> UUID {
        let uuid = UUID()
        
        if let pngRepresentation = image.pngData() {
            if let filePath = filePath(forKey: uuid.uuidString) {
                do  {
                    try pngRepresentation.write(to: filePath, options: .atomic)
                } catch let err {
                    throw err
                }
                return uuid
            } else {
                throw ImageStorageControllerError.storeImage(message: "Error: File could not found.")
            }
        } else {
            throw ImageStorageControllerError.storeImage(message: "Error: Could not extract pngdata from UIImage.")
        }
    }
    
    func retrieveImage(uuid: UUID) throws -> UIImage {
        if let filePath = self.filePath(forKey: uuid.uuidString),
           let fileData = FileManager.default.contents(atPath: filePath.path),
           let image = UIImage(data: fileData) {
                return image
            } else {
                throw ImageStorageControllerError.retrieveImage(message: "Error: Could not load image from UUID")
        }
        
    }
    
    func deleteImage(uuid: UUID) throws {
        if let filePath = self.filePath(forKey: uuid.uuidString) {
            do {
                try FileManager.default.removeItem(atPath: filePath.path)
                print("Info: (deleteImage) File \(filePath.lastPathComponent) deleted")
            } catch let err {
                throw err
            }
        } else {
            throw ImageStorageControllerError.deleteImage(message: "Error: (deleteImage) file not found")
        }
        
    }
    
    private func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        return documentURL.appendingPathComponent(key + ".png")
    }
    
    
}
