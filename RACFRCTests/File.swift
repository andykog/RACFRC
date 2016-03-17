//
//  File.swift
//  RACFRC
//
//  Created by Andrey Kogut on 3/16/16.
//  Copyright © 2016 ONE FREELANCE LTD. All rights reserved.
//

import Foundation
import CoreData

class File: NSManagedObject {

    @NSManaged var id: NSNumber
    @NSManaged var section: String

}
