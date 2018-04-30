//
//  ViewController.swift
//  Concurrency-CoreData
//
//  Created by vishnusankar on 27/04/18.
//  Copyright © 2018 vishnusankar. All rights reserved.
//

import UIKit
import Foundation
import CoreData


class ViewController: UIViewController {

    var fetchedResultCont = NSFetchedResultsController<TagEntity>()
    var context : NSManagedObjectContext?
    
    @IBOutlet weak var tabelView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.fetchedResultCont = self.tagEntityFetchedResultController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func descendingOrderButtonMethod(_ sender: Any) {
       self.sortingManagedObjects(ascendingOrder: false)
    }
    @IBAction func ascendingOrderButtonMethod(_ sender: Any) {
        
        self.sortingManagedObjects(ascendingOrder: true)
    }
    
    func sortingManagedObjects(ascendingOrder:Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let fetchrequest = NSFetchRequest<TagEntity>(entityName: "TagEntity")
        let sortDescriptor = NSSortDescriptor(key: #keyPath(TagEntity.tag), ascending: ascendingOrder)
        fetchrequest.sortDescriptors = [sortDescriptor]
        fetchedResultCont.delegate = nil
        fetchedResultCont = NSFetchedResultsController(fetchRequest: fetchrequest, managedObjectContext: (appDelegate.coreDataHelperObj?.mainMOC)!, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultCont.delegate = self
        
        do {
            try fetchedResultCont.performFetch()
            appDelegate.coreDataHelperObj?.saveMainContext()
            self.tabelView.reloadData()
        } catch let error as NSError {
            fatalError("\(error.userInfo)")
        }
    }
    @IBAction func copyButtonMethod(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
        appDelegate.coreDataHelperObj?.writerMOC.perform({
            
            do {
                let fetchReq = NSFetchRequest<TagEntity>(entityName: "TagEntity")
                
                if let allTagsArray = try appDelegate.coreDataHelperObj?.mainMOC.fetch(fetchReq) {
                    for tagObj  in allTagsArray {
                        let unwrapTagObj : TagEntity = tagObj
                        var index = 0
                        for _ in 0...10 {
                            unwrapTagObj.copyManagedObject(copyToManagedObjectContext: (appDelegate.coreDataHelperObj?.writerMOC)!)
                            index += 1

                            if (index % 10) == 0 {
                                appDelegate.coreDataHelperObj?.saveWriterContext()
                            }
                        }
                    }
                    if appDelegate.coreDataHelperObj?.writerMOC.hasChanges == true {
                        appDelegate.coreDataHelperObj?.saveWriterContext()
                    }
                }
            } catch let error as NSError {
                fatalError("Unresoved error")
            }
        })
        
    }
    @IBAction func addTagButtonMethdo(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let randomNo = arc4random()%100
        self.createNewTagEntity(tagName: "Tag\(randomNo)",context: (appDelegate.coreDataHelperObj?.mainMOC)!)
        if (self.context?.hasChanges)! {
            do {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                try appDelegate.coreDataHelperObj?.saveMainContext()
                
            } catch let error as NSError {
                fatalError("context save failed \(error)")
            }
            
        }
    }
    
    
    func createNewTagEntity(tagName : String, context : NSManagedObjectContext) -> TagEntity {

        let newTagEntry = TagEntity(context:context)
        newTagEntry.lastUpdated = Date()
        newTagEntry.tag = tagName
        
        return newTagEntry
    }
    
    func tagEntityFetchedResultController() -> NSFetchedResultsController<TagEntity> {
        let fetchedResultCont = NSFetchedResultsController(fetchRequest: self.tagFetchRequest(), managedObjectContext: context!, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultCont.delegate = self
        do {
            try fetchedResultCont.performFetch()
        } catch let error as NSError {
            fatalError("Unresolved error: \(error)")
        }
        return fetchedResultCont
    }
    
    func tagFetchRequest() -> NSFetchRequest<TagEntity>{
        let fetchReq = NSFetchRequest<TagEntity>(entityName: "TagEntity")
        fetchReq.fetchBatchSize = 20
        
        let sortDescriptor = NSSortDescriptor(key: #keyPath(TagEntity.tag), ascending: true)
        fetchReq.sortDescriptors = [sortDescriptor]
        return fetchReq
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        let viewCont = segue.destination as! DetailViewController
        let selectedCell = sender as? UITableViewCell
        let view = selectedCell?.contentView.subviews
        if let label = view?.first as? UILabel {
            viewCont.tagValue = label.text!
        }
        let indexPath = self.tabelView.indexPath(for: selectedCell!)
        let objectId = self.fetchedResultCont.object(at: indexPath!)
        
        do {
            viewCont.managedObject = try appDelegate.coreDataHelperObj?.mainMOC.existingObject(with: objectId.objectID) as! TagEntity
        } catch let error as NSError {
            fatalError("Selected object ID not available at context")
        }
        
    }
}

extension ViewController : NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tabelView.reloadData()
    }
}

extension ViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultCont.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tagTableViewCellIdentifier")
        let tagObj = fetchedResultCont.object(at: indexPath)
        
        let subviews = cell?.contentView.subviews.filter({ $0.tag == 1})
        let label : UILabel = subviews?.first as! UILabel
        label.text = tagObj.tag
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultCont.sections?[section].numberOfObjects ?? 0
    }
}
