//
//  Persons+CoreDataProperties.swift
//  FaceRecognition
//
//  Created by Nicklas Körtge on 24.01.21.
//
//

import Foundation
import CoreData


extension Persons {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Persons> {
        return NSFetchRequest<Persons>(entityName: "Persons")
    }

    @NSManaged public var faceCode: [Float32]?
    @NSManaged public var name: String?
    @NSManaged public var profileImageReference: UUID?

}

extension Persons : Identifiable {

}
