//
//  File.swift
//  
//
//  Created by Nick Nameless on 4/12/24.
//

import Foundation

public struct NWMovieDetails {
    public let id: Int
    public let poster_path: String?
    public let release_date: String?
    public let title: String
    public let tagline: String?
    public let vote_average: Double
    public let vote_count: Int
    public let backdrop_path: String?
    public let homepage: String?
    public let overview: String?
}

extension NWMovieDetails: Decodable {
    
}

extension NWMovieDetails: Identifiable {
    
}

extension NWMovieDetails {
    public func getPosterURL() -> String? {
        if let poster_path = poster_path {
            return "https://image.tmdb.org/t/p/w500/" + poster_path
        }
        return nil
    }
    public func getBackdropURL() -> String? {
        if let backdrop_path = backdrop_path {
            return "https://image.tmdb.org/t/p/w1280/" + backdrop_path
        }
        return nil
    }
}
