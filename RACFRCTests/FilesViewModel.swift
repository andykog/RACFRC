//
//  FilesViewModel.swift
//  RACFRC
//
//  Created by Andrey Kogut on 3/17/16.
//  Copyright © 2016 ONE FREELANCE LTD. All rights reserved.
//

import Foundation
import CoreData
@testable import RACFRC

class FilesViewModel {
    
    lazy var files: MutableCollectionProperty<RACFRCSection<File>> = MutableCollectionProperty([RACFRCSection<File>(objects: [], sectionName: nil, indexTitle: nil)])
    
    lazy var frc: NSFetchedResultsController? = {
        
        NSFetchedResultsController.deleteCacheWithName("FILES")
        
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName("File", inManagedObjectContext: CoreDataHelper.managedObjectContext)
        fetchRequest.returnsObjectsAsFaults = true // <!>
        fetchRequest.fetchBatchSize = 30
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "id", ascending: true)
        ]
        fetchRequest.predicate = NSPredicate(value: true)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataHelper.managedObjectContext, sectionNameKeyPath: nil, cacheName: "FILES")
        
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
            return nil
        }
        
        return fetchedResultsController
    }()
    
    var frcBridge: RACFRC<File>! = nil
    
    init() {
        self.frcBridge = RACFRC(frc: self.frc, property: self.files)
    }
    
}
