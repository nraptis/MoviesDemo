//
//  MovieDetailsViewModel.swift
//  BlockchainMoviesApp
//
//  Created by Nick Nameless on 4/12/24.
//

import SwiftUI
import BlockChainNetworking
import Combine

@Observable class MovieDetailsViewModel {
    
    typealias NWMovie = BlockChainNetworking.NWMovie
    typealias NWMovieDetails = BlockChainNetworking.NWMovieDetails
    
    private static let probeAheadOrBehindRangeForDownloads = 8
    
    let nwMovieDetails: NWMovieDetails
    init(nwMovieDetails: NWMovieDetails) {
        self.nwMovieDetails = nwMovieDetails
    }
}

extension MovieDetailsViewModel: Equatable {
    static func == (lhs: MovieDetailsViewModel, rhs: MovieDetailsViewModel) -> Bool {
        lhs === rhs
    }
}

extension MovieDetailsViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
