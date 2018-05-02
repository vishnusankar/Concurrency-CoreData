//
//  DetailViewController.swift
//  Concurrency-CoreData
//
//  Created by vishnusankar on 29/04/18.
//  Copyright © 2018 vishnusankar. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class DetailViewController : UIViewController {
    var tagValue : String = ""
    var managedObject : TagEntity?
    @IBOutlet weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.tagValue
        self.textField.text = self.tagValue
    }
    
    @IBAction func updateButtonMethod(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        managedObject?.tag = self.textField.text
        managedObject?.lastUpdated = Date()
        appDelegate.coreDataHelperObj?.saveWriterContext()
    }
}
