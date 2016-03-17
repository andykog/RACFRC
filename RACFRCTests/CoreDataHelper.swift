//
//  CoreDataHelper.swift
//  RACFRC
//
//  Created by Andrey Kogut on 3/16/16.
//  Copyright © 2016 ONE FREELANCE LTD. All rights reserved.
//

import Foundation
import CoreData

class CoreDataHelper {
    
    static var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    static var managedObjectModel: NSManagedObjectModel = {
        let bundle = NSBundle(forClass: CoreDataHelper.self)
        let modelURL = bundle.URLForResource("Model", withExtension: "momd") ?? bundle.URLForResource("Model", withExtension: "mom")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    static var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: CoreDataHelper.managedObjectModel)
        let url = CoreDataHelper.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        var error: NSError? = nil
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch var error1 as NSError {
            error = error1
            CoreDataHelper.swipeAndRecreateStore()
        } catch {
            fatalError()
        }
        
        return coordinator
    }()
    
    static var managedObjectContext: NSManagedObjectContext = {
        let coordinator = CoreDataHelper.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    private static func swipeAndRecreateStore() -> NSPersistentStoreCoordinator? {
        let storeURL = CoreDataHelper.applicationDocumentsDirectory.URLByAppendingPathComponent("Model")
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: CoreDataHelper.managedObjectModel)
        
        do {
            try NSFileManager.defaultManager().removeItemAtURL(storeURL)
        } catch let error as NSError {
            print(error.localizedDescription)
            return nil
        }
        
        do {
            try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
        } catch let error as NSError {
            print(error.localizedDescription)
            return nil
        } catch _ { return nil }
        
        return persistentStoreCoordinator
    }

    
    static func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    static func fetchItems(modelName:String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> [AnyObject] {
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName(modelName, inManagedObjectContext: self.managedObjectContext)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        var fetchError: NSError?
        do {
            let result = try self.managedObjectContext.executeFetchRequest(request)
            return result
        } catch let error1 as NSError {
            fetchError = error1
            if let error = fetchError {
                print("Fetch error: \(error.description)")
            }
            return []
        }
    }
    
    static func fetchItem(modelName:String, predicate: NSPredicate? = nil) -> NSManagedObject? {
        
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entityForName(modelName, inManagedObjectContext: self.managedObjectContext)
        request.predicate = predicate
        request.fetchLimit = 1
        var fetchError: NSError?
        do {
            let result = try self.managedObjectContext.executeFetchRequest(request)
            return result.first as? NSManagedObject
        } catch let error1 as NSError {
            fetchError = error1
            if let error = fetchError {
                print("Fetch error: \(error.description)")
            }
            return nil
        }
    }
    
    static func removeItems(modelName: String, predicate: NSPredicate) {
        for object in self.fetchItems(modelName, predicate: predicate) {
            self.managedObjectContext.deleteObject(object as! NSManagedObject)
        }
    }
    
    static func findOrCreateInstance(modelName: String, predicate: NSPredicate) -> NSManagedObject {
        var object = self.fetchItem(modelName, predicate: predicate)
        if object == nil {
            object = (NSEntityDescription.insertNewObjectForEntityForName(modelName, inManagedObjectContext: self.managedObjectContext) )
        }
        return object!
    }

}