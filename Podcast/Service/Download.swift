//
//  Download.swift
//  Podcast
//
//  Created by Adrian Evensen on 24/05/2020.
//  Copyright © 2020 AdrianF. All rights reserved.
//

import Foundation
import CoreData

class Downloader: NSObject, URLSessionDelegate {
    static let shared = Downloader()
    
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Database")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                fatalError("loading of store failed: \(error)")
            }
        })
        return container
    }()
    
    func new(id: UUID, url: URL) {
        let config = URLSessionConfiguration.background(withIdentifier: "no.bondepike.telegraf.download\(id)")
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        
        
        
        
    }
    
    
}
