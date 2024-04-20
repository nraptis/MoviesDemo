//
//  File.swift
//  
//
//  Created by "Nick" Django Raptis on 4/12/24.
//

import Foundation
@testable import BlockChainNetworking

class NWMockNetworkController: NWNetworkControllerImplementing {
    
    static func fetchPopularMovies(page: Int) async throws -> BlockChainNetworking.NWMoviesResponse {
        
        let nwMovie1 = NWMovie(id: 200,
                               poster_path: "/xQCMAHeg5M9HpDIqanYbWdr4brB.jpg",
                               release_date: "1998-12-11",
                               title: "Star Trek: Insurrection",
                               vote_average: 6.43, 
                               vote_count: 1142)
        
        let nwMovie2 = NWMovie(id: 201,
                               poster_path: "/cldAwhvBmOv9jrd3bXWuqRHoXyq.jpg",
                               release_date: "2002-12-13",
                               title: "Star Trek: Nemesis",
                               vote_average: 6.287, vote_count: 1344)
        
        let nwMovie3 = NWMovie(id: 203,
                               poster_path: "/9msfwOeGc9uL1iRRTBdEf15XonC.jpg",
                               release_date: "1973-10-14",
                               title: "Mean Streets",
                               vote_average: 7.094, vote_count: 1974)
        
        return NWMoviesResponse(results: [nwMovie1, nwMovie2, nwMovie3],
                                page: 10,
                                total_pages: 15000,
                                total_results: 300000)
    }
    
    static func fetchMovieDetails(id: Int) async throws -> BlockChainNetworking.NWMovieDetails {
        
        return NWMovieDetails(id: 100,
                              poster_path: "/wt2TRBmFmBn5M5MBcPTwovlREaB.jpg",
                              release_date: "1998-08-28",
                              title: "Lock, Stock and Two Smoking Barrels",
                              tagline: "A Disgrace to Criminals Everywhere.",
                              vote_average: 8.121,
                              vote_count: 6299,
                              backdrop_path: "/cXQH2u7wUIX1eoIdEj51kHXoWhX.jpg",
                              homepage: "http://www.universalstudiosentertainment.com/lock-stock-and-two-smoking-barrels/",
                              overview: "A card shark and his unwillingly-enlisted friends need to make a lot of cash quick after losing a sketchy poker match. To do this they decide to pull a heist on a small-time gang who happen to be operating out of the flat next door.")
    }
    
}
