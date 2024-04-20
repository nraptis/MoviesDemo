//
//  File.swift
//
//  Created by Nick Nameless on 4/9/24.
//

import Foundation

public struct NWMovie {
    public let id: Int
    public let poster_path: String?
    public let release_date: String?
    public let title: String
    public let vote_average: Double
    public let vote_count: Int
    
    public init(id: Int, poster_path: String?, release_date: String?, title: String, vote_average: Double, vote_count: Int) {
        self.id = id
        self.poster_path = poster_path
        self.release_date = release_date
        self.title = title
        self.vote_average = vote_average
        self.vote_count = vote_count
    }
}

extension NWMovie: Decodable {
    
}

extension NWMovie: Identifiable {
    
}

extension NWMovie {
    public func getPosterURL() -> String? {
        if let poster_path = poster_path {
            return "https://image.tmdb.org/t/p/w500/" + poster_path
        }
        return nil
    }
}
