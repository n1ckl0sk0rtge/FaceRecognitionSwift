//
//  CoreDataStorageController.swift
//  Travellout
//
//  Created by Nicklas Körtge on 29.07.20.
//  Copyright © 2020 Nicklas Körtge. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class CoreDataStorageController<T : NSManagedObject> {
    
    func loadData() -> [Any]? {
        do {
            let data = try Constants.appDelegatecontext.fetch(T.fetchRequest())
            return data
        } catch let error {
            print(error)
            return nil
        }
    }
    
    func saveData() throws {
        do {
            try Constants.appDelegatecontext.save()
            print("CoreDataSaveData: successfull")
        } catch let error {
            throw error
        }
    }
    
    func delete(obj: T) throws {
        do {
            Constants.appDelegatecontext.delete(obj)
            try Constants.appDelegatecontext.save()
        } catch let error as NSError {
            throw error
        }
    }
    
    func deleteAllData() throws {
        do {
            let results = try Constants.appDelegatecontext.fetch(T.fetchRequest())
            for object in results {
                guard let objectData = object as? NSManagedObject else {continue}
                Constants.appDelegatecontext.delete(objectData)
            }
            try Constants.appDelegatecontext.save()
        } catch let error as NSError {
            throw error
        }
    }
    
}
