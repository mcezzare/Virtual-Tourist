//
//  CoreDataManager.swift
//  Virtual Tourist
//
//  Created by Mario Cezzare on 05/04/19.
//  Copyright © 2019 Mario Cezzare. All rights reserved.
//  Build based on https://cocoacasts.com tutorial

import CoreData

// MARK: - CoreDataManager

struct CoreDataManager {
    
    // MARK: - Properties
    
    private let model: NSManagedObjectModel
    private let modelURL: URL
    
    internal let coordinator: NSPersistentStoreCoordinator
    internal let dbURL: URL
    internal let persistingContext: NSManagedObjectContext
    internal let backgroundContext: NSManagedObjectContext
    
    let context: NSManagedObjectContext
    
    // MARK: - Shared Instance
    
    static func shared() -> CoreDataManager {
        struct Singleton {
            static var shared = CoreDataManager(modelName: "Virtual_Tourist")!
        }
        return Singleton.shared
    }
    
    // MARK: - Initializers
    
    init?(modelName: String) {
        
        // Check if the model is in bundle application
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            print("Unable to find \(modelName)in the main bundle")
            return nil
        }
        self.modelURL = modelURL
        
        debugPrint("\(#function) \(modelURL)")
        
        // Create the model from the specified URL
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("unable to create a model from \(modelURL)")
            return nil
        }
        self.model = model
        
        // Create the store coordinator
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        // Create a persistingContext (private queue) and a child one (main queue)
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        // Create a context and connect it to the coordinator
        persistingContext.persistentStoreCoordinator = coordinator
        
        // Create a context and connect it to the coordinator
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = persistingContext
        
        // Create a background context child of main context
        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = context
        
        // Instantiate FileManager to access documents folder
        let fm = FileManager.default
        
        guard let documentsFolderUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to reach the documents folder")
            return nil
        }
        
        // Specify a SQLite store located in the documents folder
        self.dbURL = documentsFolderUrl.appendingPathComponent("model.sqlite")
        
        // Options for migration
        let options = [
            NSInferMappingModelAutomaticallyOption: true,
            NSMigratePersistentStoresAutomaticallyOption: true
        ]
        
        do {
            try addCoordinatorStore(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: options as [NSObject : AnyObject]?)
        } catch {
            print("unable to add store at \(dbURL)")
        }
    }
    
    // MARK: - Utils
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - storeType: A valid type for storage
    ///   - configuration: configuration description
    ///   - storeURL: a valid url inside documents folder
    ///   - options: array of options
    /// - Throws: throws value description
    func addCoordinatorStore(_ storeType: String, configuration: String?, storeURL: URL, options : [NSObject:AnyObject]?) throws {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: nil)
    }
    
    
    /// Fetch a specific Pin from DB using a predicate filter
    ///
    /// - Parameters:
    ///   - predicate: a filter
    ///   - entityName: a name for the Entity/Object
    ///   - sorting: sorting/field[s] value
    /// - Returns: a Pin Entity
    /// - Throws: an error
    func fetchPin(_ predicate: NSPredicate, entityName: String, sorting: NSSortDescriptor? = nil) throws -> Pin? {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fr.predicate = predicate
        if let sorting = sorting {
            fr.sortDescriptors = [sorting]
        }
        guard let pin = (try context.fetch(fr) as! [Pin]).first else {
            return nil
        }
        return pin
    }
    
    
    /// Fetch all Pins from DB
    ///
    /// - Parameters:
    ///   - predicate: predicate if used
    ///   - entityName: a name for the Entity/Object
    ///   - sorting: sorting/field[s] value
    /// - Returns: a Pin Entity
    /// - Throws: an error
    func fetchAllPins(_ predicate: NSPredicate? = nil, entityName: String, sorting: NSSortDescriptor? = nil) throws -> [Pin]? {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fr.predicate = predicate
        if let sorting = sorting {
            fr.sortDescriptors = [sorting]
        }
        guard let pin = try context.fetch(fr) as? [Pin] else {
            return nil
        }
        return pin
    }
    
    
    /// Fetch fotos from DB and external storage
    ///
    /// - Parameters:
    ///   - predicate: predicate if used
    ///   - entityName: a name for the Entity/Object
    ///   - sorting: sorting/field[s] value
    /// - Returns: a Photo Entity
    /// - Throws: an error
    func fetchPhotos(_ predicate: NSPredicate? = nil, entityName: String, sorting: NSSortDescriptor? = nil) throws -> [Photo]? {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fr.predicate = predicate
        if let sorting = sorting {
            fr.sortDescriptors = [sorting]
        }
        guard let photos = try context.fetch(fr) as? [Photo] else {
            return nil
        }
        return photos
    }
}

// MARK: - CoreDataManager (Removing Data)

internal extension CoreDataManager  {
    
    /// Description
    ///
    /// - Throws: and error
    func dropAllData() throws {
        // delete all the objects in the db. This won't delete the files, it will
        // just leave empty tables.
        try coordinator.destroyPersistentStore(at: dbURL, ofType:NSSQLiteStoreType , options: nil)
        try addCoordinatorStore(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
    }
}

// MARK: - CoreDataManager (Save Data)

extension CoreDataManager {
    
    /// Save the context to DB in async mode
    ///
    /// - Throws: and error
    func saveContext() throws {
        context.performAndWait() {
            
            if self.context.hasChanges {
                do {
                    try self.context.save()
                } catch {
                    print("Error while saving main context: \(error)")
                }
                
                // now we save in the background
                self.persistingContext.perform() {
                    do {
                        try self.persistingContext.save()
                    } catch {
                        print("Error while saving persisting context: \(error)")
                    }
                }
            }
        }
    }
    
    /// Auto save function, not used in this project
    ///
    /// - Parameter delayInSeconds: number of seconds
    func autoSave(_ delayInSeconds : Int) {
        
        if delayInSeconds > 0 {
            do {
                try saveContext()
                print("Autosaving")
            } catch {
                print("Error while autosaving")
            }
            
            let delayInNanoSeconds = UInt64(delayInSeconds) * NSEC_PER_SEC
            let time = DispatchTime.now() + Double(Int64(delayInNanoSeconds)) / Double(NSEC_PER_SEC)
            
            DispatchQueue.main.asyncAfter(deadline: time) {
                self.autoSave(delayInSeconds)
            }
        }
    }
}
