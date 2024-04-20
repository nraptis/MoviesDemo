//
//  Router.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/12/24.
//

import Foundation
import SwiftUI
import BlockChainNetworking

@Observable class Router {
    
    @MainActor var navigationPath = NavigationPath()
    @MainActor let rootViewModel: RootViewModel
    @MainActor init(rootViewModel: RootViewModel) {
        self.rootViewModel = rootViewModel
    }
    
    @MainActor @ObservationIgnored lazy var communityViewModel: CommunityViewModel = {
        CommunityViewModel(router: self)
    }()
    
    @MainActor func pushMovieDetails(nwMovieDetails: BlockChainNetworking.NWMovieDetails) {
        let movieDetailsViewModel = MovieDetailsViewModel(nwMovieDetails: nwMovieDetails)
        navigationPath.append(movieDetailsViewModel)
    }
    
}
