//
//  Persons+CoreDataClass.swift
//  FaceRecognition
//
//  Created by Nicklas Körtge on 24.01.21.
//
//

import Foundation
import CoreData

@objc(Persons)
public class Persons: NSManagedObject {
    let imageStorageController = ImageStorageController()
        
    func saveProfileImage(image: FaceImage) {
        if let image = image.getUIImageReference() {
            do {
                self.profileImageReference = try imageStorageController.storeImage(image: image)
            } catch let error {
                print(error)
            }
            
        }
    }
    
    func loadProfileImage() -> FaceImage?  {
        if let ref = self.profileImageReference, let image =  try? imageStorageController.retrieveImage(uuid: ref) {
            return FaceImage(imageOfFace: image, headEulerAngleZ: .zero)
        } else {
            return nil
        }
    }
    
    func deleteProfileImage() throws {
        if let ref = self.profileImageReference {
            do {
                try imageStorageController.deleteImage(uuid: ref)
            } catch let error {
                throw error
            }
        }
    }
    
    func createFluctuatingReference() -> FluctuatingPersonReference {
        let detectedPerson = FluctuatingPersonReference(faceimage: self.loadProfileImage()!, faccode: self.faceCode!)
        detectedPerson.name = self.name
        return detectedPerson
    }
}

public class FluctuatingPersonReference {
    var faceImage : FaceImage?
    var faceCode: [Float32]?
    var name: String? = String()
    
    init(faceimage: FaceImage, faccode: [Float32]) {
        self.faceImage = faceimage
        self.faceCode = faccode
    }
    
    func makePersistent(){
        let person = Persons(context: Constants.appDelegatecontext)
        person.name = self.name
        person.faceCode = self.faceCode
        person.saveProfileImage(image: self.faceImage!)
    }
    
}
