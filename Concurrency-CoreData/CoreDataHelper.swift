//
//  CoreDataHelper.swift
//  Concurrency-CoreData
//
//  Created by vishnusankar on 27/04/18.
//  Copyright © 2018 vishnusankar. All rights reserved.
//

import Foundation
import CoreData

class CoreDataHelper {
    
    //2nd level Child
    lazy var workerMOC : NSManagedObjectContext = {
        var tempworkerMOC = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
        tempworkerMOC.parent = self.mainMOC
        return tempworkerMOC
    }()
    
    //1st level Child
    lazy var mainMOC : NSManagedObjectContext = {
        var tempMainMOC = NSManagedObjectContext(concurrencyType:.mainQueueConcurrencyType)
        tempMainMOC.parent = self.writerMOC
        return tempMainMOC
    }()
    
    lazy var writerMOC : NSManagedObjectContext = {
        var tempMainMOC = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
        tempMainMOC.persistentStoreCoordinator = self.persistentStoreCoordinator

        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        var docURL = urls[urls.endIndex-1]
        /* The directory the application uses to store the Core Data store file.
         This code uses a file named "DataModel.sqlite" in the application's documents directory.
         */

        let storeURL = docURL.appendingPathComponent("DataModel.sqlite")
        do {
            try tempMainMOC.persistentStoreCoordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
        } catch {
            fatalError("Error migrating store: \(error)")
        }

        return tempMainMOC
    }()
    
    private lazy var applicationDocumentDirectory : URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    private lazy var managedObjectModel : NSManagedObjectModel = {
        let modelUrl = Bundle.main.url(forResource: "TagsModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelUrl)!
    }()
    
    private lazy var persistentStoreCoordinator : NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        return coordinator
    }()
    
    lazy var storeContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TagsModel")
        container.loadPersistentStores(completionHandler: { (storeDescriptor, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error")
            }
        })
        return container
    }()
    
    func saveWorkerContext() {
        //2nd level child save
        guard workerMOC.hasChanges else { return }
        
        workerMOC.perform({
            do {
                print("worker started")
                try self.workerMOC.save()
                print("worker Saved")
            } catch let nserror as NSError {
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            
            //1st level child save
            guard self.mainMOC.hasChanges else { return }
                
            do {
                print("Main started")
                try self.mainMOC.save()
                print("Main Saved")
            } catch let nserror as NSError {
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            
            //Root level save
            guard self.writerMOC.hasChanges else { return }
            
            self.writerMOC.perform({
                do {
                    print("writer started")
                    try self.writerMOC.save()
                    print("writer Saved")
                } catch let nserror as NSError {
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            })
        })
    }
    
    func saveMainContext() -> Bool {
        
        //1st level child save
        guard mainMOC.hasChanges else { return false }
        
        do {
            try mainMOC.save()
        } catch let nserror as NSError {
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        //Root level save
        guard writerMOC.hasChanges else { return false }
        
        
        do {
            try writerMOC.save()
        } catch let nserror as NSError {
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return true
    }
    
    func saveWriterContext() -> Bool {
        
        //Root level save
        guard writerMOC.hasChanges else { return false }
        
        do {
            print("writer started")
            try writerMOC.save()
            print("writer saved")
        } catch let nserror as NSError {
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return true
    }
    
    
}
