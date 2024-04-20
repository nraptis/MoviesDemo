//
//  HomeGridCellData.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import Foundation
import BlockChainNetworking
import BlockChainDatabase

class CommunityCellData {
    var index: Int
    var id: Int
    var poster_path: String?
    var release_date: String?
    var title: String
    var vote_average: Double
    var vote_count: Int
    var urlString: String?
    
    init() {
        self.index = -1
        self.id = -1
        self.poster_path = nil
        self.release_date = nil
        self.title = ""
        self.vote_average = 0.0
        self.vote_count = 0
        self.urlString = nil
    }
    
    init(index: Int, nwMovie: BlockChainNetworking.NWMovie) {
        self.index = index
        self.id = nwMovie.id
        self.poster_path = nwMovie.poster_path
        self.release_date = nwMovie.release_date
        self.title = nwMovie.title
        self.vote_average = nwMovie.vote_average
        self.vote_count = nwMovie.vote_count
        self.urlString = nwMovie.getPosterURL()
    }
    
    init(index: Int, dbMovie: BlockChainDatabase.DBMovie) {
        self.index = index
        self.id = Int(dbMovie.id)
        self.poster_path = dbMovie.poster_path
        self.release_date = dbMovie.release_date
        self.title = dbMovie.title ?? "Unknown"
        self.vote_average = dbMovie.vote_average
        self.vote_count = Int(dbMovie.vote_count)
        self.urlString = dbMovie.urlString
    }
    
    func inject(index: Int, nwMovie: BlockChainNetworking.NWMovie) {
        self.index = index
        self.id = nwMovie.id
        self.poster_path = nwMovie.poster_path
        self.release_date = nwMovie.release_date
        self.title = nwMovie.title
        self.vote_average = nwMovie.vote_average
        self.vote_count = nwMovie.vote_count
        self.urlString = nwMovie.getPosterURL()
    }
    
    func inject(index: Int, dbMovie: BlockChainDatabase.DBMovie) {
        self.index = index
        self.id = Int(dbMovie.id)
        self.poster_path = dbMovie.poster_path
        self.release_date = dbMovie.release_date
        self.title = dbMovie.title ?? "Unknown"
        self.vote_average = dbMovie.vote_average
        self.vote_count = Int(dbMovie.vote_count)
        self.urlString = dbMovie.urlString
    }
    
    var key: String? {
        urlString
    }
}

extension CommunityCellData: Equatable {
    static func == (lhs: CommunityCellData, rhs: CommunityCellData) -> Bool {
        lhs.index == rhs.index
    }
}

extension CommunityCellData: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(index)
    }
}

extension CommunityCellData: Identifiable {
    
}

extension CommunityCellData: DirtyImageDownloaderType {
    
}
