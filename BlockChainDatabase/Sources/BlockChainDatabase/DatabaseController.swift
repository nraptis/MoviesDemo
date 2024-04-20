//
//  File.swift
//  
//
//  Created by Nick Nameless on 4/8/24.
//

import Foundation
import CoreData
import BlockChainNetworking

@globalActor actor DBDatabaseActor {
    static let shared = DBDatabaseActor()
}

public typealias NWMovie = BlockChainNetworking.NWMovie

public protocol DBDatabaseConforming {
    func loadPersistentStores() async
    func fetchMovies() async throws -> [DBMovie]
    func sync(nwMovies: [NWMovie]) async throws
}
    
public class DBDatabaseController: DBDatabaseConforming {
    
    public init() {
        
    }
    
    @DBDatabaseActor lazy var managedObjectModel: NSManagedObjectModel = {
        if let url = Bundle.module.url(forResource: "Database", withExtension: "momd") {
            if let result = NSManagedObjectModel(contentsOf: url) {
                return result
            }
            
        }
        return NSManagedObjectModel()
    }()
    
    @DBDatabaseActor lazy var persistentContainer: NSPersistentContainer = {
        return NSPersistentContainer(name: "Database", managedObjectModel: managedObjectModel)
    }()
    
    @DBDatabaseActor public func loadPersistentStores() async {
        await withCheckedContinuation { continuation in
            persistentContainer.loadPersistentStores { description, error in
                if let error = error {
                    print("Load Persistent Stores Error: \(error.localizedDescription)")
                }
                continuation.resume()
            }
        }
    }
    
    @DBDatabaseActor public func magnetize() async throws {
        let context = persistentContainer.viewContext
        try await context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DBMovie")
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(batchDeleteRequest)
            try context.save()
        }
    }
    
    @DBDatabaseActor public func sync(nwMovies: [NWMovie]) async throws {
        let nwMovieEntities = try await fetchMovies()
                
        var dbMovieDict = [Int64: DBMovie]()
        for dbMovie in nwMovieEntities {
            if dbMovie.id != 0 {
                dbMovieDict[dbMovie.id] = dbMovie
            }
        }
        
        let context = persistentContainer.viewContext
        try await context.perform {
            for nwMovie in nwMovies where nwMovie.id != 0 {
                let nwMovieId = Int64(nwMovie.id)
                if let dbMovie = dbMovieDict[nwMovieId] {
                    self.inject(dbMovie: dbMovie,
                                nwMovie: nwMovie)
                } else {
                    let dbMovie = DBMovie(context: context)
                    self.inject(dbMovie: dbMovie,
                                nwMovie: nwMovie)
                }
            }
            try context.save()
        }
    }
    
    @DBDatabaseActor public func fetchMovies() async throws -> [DBMovie] {
        let context = persistentContainer.viewContext
        var result = [DBMovie]()
        try await context.perform {
            let fetchRequest = DBMovie.fetchRequest()
            result = try context.fetch(fetchRequest)
        }
        return result
    }
    
    private func inject(dbMovie: DBMovie, nwMovie: NWMovie) {
        dbMovie.id = Int64(nwMovie.id)
        dbMovie.poster_path = nwMovie.poster_path
        dbMovie.release_date = nwMovie.release_date
        dbMovie.title = nwMovie.title
        dbMovie.vote_average = nwMovie.vote_average
        dbMovie.vote_count = Int64(nwMovie.vote_count)
        dbMovie.urlString = nwMovie.getPosterURL()
    }
}
