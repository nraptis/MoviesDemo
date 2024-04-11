//
//  HomeGridCellData.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import Foundation
import BlockChainNetworking

class CommunityCellModel {
    
    static func mock() -> CommunityCellModel {
        CommunityCellModel(index: 0, movie: Movie.mock())
    }
    
    var index: Int
    var movie: BlockChainNetworking.Movie
    var urlString: String?
    init(index: Int, movie: BlockChainNetworking.Movie) {
        self.index = index
        self.movie = movie
        urlString = movie.getPosterURL()
    }
    
    var cacheKey: String {
        "cache_key_\(index)"
    }
}

extension CommunityCellModel: Equatable {
    static func == (lhs: CommunityCellModel, rhs: CommunityCellModel) -> Bool {
        lhs.index == rhs.index
    }
}

extension CommunityCellModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(index)
    }
}

extension CommunityCellModel: Identifiable {
    var id: Int {
        movie.id
    }
}

extension CommunityCellModel: DirtyImageDownloaderType {
    
}
