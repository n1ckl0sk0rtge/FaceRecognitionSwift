//
//  Constants.swift
//  Travellout
//
//  Created by Nicklas Körtge on 07.10.20.
//  Copyright © 2020 Nicklas Körtge. All rights reserved.
//

import Foundation
import UIKit
import CoreData

struct Constants {
    static let ALLOWED_AGE = 16
    
    static var appDelegatecontext: NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
}
