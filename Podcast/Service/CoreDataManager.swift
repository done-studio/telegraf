//
//  CoreDataManager.swift
//  Podcast
//
//  Created by Adrian Evensen on 17/03/2018.
//  Copyright © 2018 AdrianF. All rights reserved.
//

import CoreData
import UIKit

class CoreDataManager {
    
    static let shared = CoreDataManager()
    
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PodcastModels")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                fatalError("loading of store failed: \(error)")
            }
        })
        return container
    }()
    
    
    //MARK:- Update
    func updatePodcastWithNotifications(_ podcast: Podcast, isEnabled: Bool, completionHandler: (Error?) -> ()) {
        let context = persistentContainer.viewContext
        podcast.notificationsEnabled = isEnabled
        
        do {
            try context.save()
            completionHandler(nil)
        } catch let err {
            completionHandler(err)
        }
    }
    
    
    func updateEpisodeTimes(episode: Episode, elapsedTime: Double, episodeLength: Double, completionHandler: (Double)->()) {
        let context = persistentContainer.viewContext
        episode.timeElapsed = elapsedTime
        episode.timeLength = episodeLength
        
        do {
            try context.save()
            completionHandler(elapsedTime)
        } catch let error {
            print("failed to update episode time: \n", error)
        }
    }
    
    func updateEpisodeLength(episode: Episode, length: Double) {
        let context = persistentContainer.viewContext
        episode.timeLength = length
       
        do {
            try context.save()
            print("sucessfully saved length: ", length)
        } catch let error {
            print("failed to save length", error)
        }
    }
    
    func updateEpisodeDownloadProgress(episode: Episode, downloadProgress: Double) {
        let context = persistentContainer.viewContext
        episode.downloadProgress = downloadProgress
       
        do {
            try context.save()
        } catch let error {
            print("failed to update download progress", error)
        }
    }
    
    
    //MARK:- Save
    func saveNewPodcast(podcastModel: PodcastsDataSource, image: UIImage, completionHandler: (Podcast?, Error?) -> ()) {
        let context = persistentContainer.viewContext
        let podcastEntity = NSEntityDescription.insertNewObject(forEntityName: "Podcast", into: context) as! Podcast
        podcastEntity.name = podcastModel.name ?? ""
        podcastEntity.feed = podcastModel.feed ?? ""
        podcastEntity.artist = podcastModel.artist ?? ""
        podcastEntity.artwork = UIImageJPEGRepresentation(image, 10)
        podcastEntity.notificationsEnabled = false
        
        do {
            try context.save()
            completionHandler(podcastEntity, nil)
        } catch let error {
            completionHandler(nil, error)
            print("failed to save new podcast: \n", error)
        }
    }
    
    func saveNewLocalEpisode(podcast: Podcast, episode: EpisodeDataSource) -> Episode {
        let context = persistentContainer.viewContext
        let newEpisode = NSEntityDescription.insertNewObject(forEntityName: "Episode", into: context) as! Episode
        newEpisode.name = episode.name ?? ""
        newEpisode.artist = episode.artist ?? ""
        newEpisode.subtitle = episode.subtitle ?? ""
        newEpisode.releaseDate = episode.releaseDate
        newEpisode.episodeDesciption = episode.subtitle
        newEpisode.addedDate = Date()
        podcast.addToEpisodes(newEpisode)
        
        
        if let history = podcast.history?.allObjects as? [History] {
            let exists = history.contains { (h) -> Bool in
                return h.name ?? "" == episode.name
            }
            if !exists {
                let history = NSEntityDescription.insertNewObject(forEntityName: "History", into: context) as! History
                history.name = episode.name ?? ""
                history.date = Date()
                podcast.addToHistory(history)
            }
        }
        
        do {
            try context.save()
        } catch let error {
            print("failed to save new episode: ", error)
        }
        
        return newEpisode
    }
    
    /// Legger gitt episode i podcasten sin History.
    func saveToHistory(_ podcast: Podcast, episode: Episode) {
        let context = persistentContainer.viewContext
        let history = NSEntityDescription.insertNewObject(forEntityName: "History", into: context) as! History
        history.name = episode.name ?? ""
        history.date = Date()
        
        do {
            try context.save()
        } catch let error {
            print("Failed to save history", error)
        }
    }
    
    //MARK:- Delete
    func deleteDownloadedEpisode(episode: Episode, completionHandler: @escaping()->()) {
        let context = persistentContainer.viewContext
        
        if let lastPathComponent = episode.lastLocalPathCompoenent {
            let documentFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            guard let url = documentFolder.first?.appendingPathComponent(lastPathComponent) else { return }
            
            do {
                try FileManager.default.removeItem(at: url)
            } catch let error {
                print("failed to delete episode: ", error)
            }
        }
        
        if let podcast = episode.podcast {
            podcast.removeFromEpisodes(episode)
        }
        context.delete(episode)

        do {
            try context.save()
            completionHandler()
        } catch let error {
            print("failed to delete episode: ", error)
        }
    }
    
    func deleteAllPodcasts(completionHandler: ()->()) {
        let context = persistentContainer.viewContext
        let batchDelete = NSBatchDeleteRequest(fetchRequest: Podcast.fetchRequest())
        do {
            try context.execute(batchDelete)
            completionHandler()
        } catch let error {
            print("failed to delete all podcasts: \n", error)
        }
    }
    
    func deletePodcast(podcast: Podcast, completionHandler: () -> () ) {
        guard let episodes = podcast.episodes?.allObjects as? [Episode] else { return }
        episodes.forEach { (episode) in
            self.deleteDownloadedEpisode(episode: episode, completionHandler: {
                
            })
        }
        let context = persistentContainer.viewContext
        context.delete(podcast)
        
        do {
            try context.save()
            completionHandler()
        } catch let error {
            print("Failed to delete podcast: \n", error)
        }
    }
    
    //MARK:- Fetch
    func fetchAllPodcasts(completionHandler: @escaping ([Podcast]) -> ()) {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<Podcast>(entityName: "Podcast")
        
        //fetchRequest.predicate = NSPredicate(format: "name = %@", "Connected")
        
        do {
            let fetchedPodcast = try context.fetch(fetchRequest)
            completionHandler(fetchedPodcast)
        } catch let error {
            print("failed to fetch all podcasts from core data: \n", error)
        }
    }
    
    func fetchPodcast(name: String) -> [Podcast]? {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<Podcast>(entityName: "Podcast")
        
        fetchRequest.predicate = NSPredicate(format: "name = %@", name)
        fetchRequest.fetchLimit = 1
        
        do {
            let fetched = try context.fetch(fetchRequest)
            return fetched
            //completion(fetched)
        } catch let err {
            print("Failed to fetch podcast for name: ", err)
        }
        return nil
    }
    
    func fetchAllEpisodes(completionHandler: @escaping ([Episode]) ->()) {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<Episode>(entityName: "Episode")
        do {
            print("trying to fetch episodes")
            let fetchedEpisodes = try context.fetch(fetchRequest)
            print("sucess")
            completionHandler(fetchedEpisodes)
        } catch let error {
            print("failed to fetch episodes: ", error)
        }
    }
    
//    func fetchHistory() -> [History] {
//        let context = persistentContainer.viewContext
//        let fetchRequest = NSFetchRequest<History>(entityName: "History")
//        do {
//            let history = try context.fetch(fetchRequest)
//
//        } catch let err {
//
//        }
//    }
}
