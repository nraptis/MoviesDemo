//
//  File.swift
//
//  Created by Nicky Taylor on 4/9/24.
//

import Foundation

public struct Movie {
    public let id: Int
    public let adult: Bool
    public let backdrop_path: String?
    public let genre_ids: [Int]
    public let original_language: String
    public let original_title: String
    public let overview: String
    public let popularity: Double
    public let poster_path: String?
    public let release_date: String?
    public let title: String
    public let video: Bool
    public let vote_average: Double
    public let vote_count: Int
}

extension Movie: Decodable {
    
}

extension Movie: Identifiable {
    
}

extension Movie {
    
    public static func mock() -> Movie {
        Movie(id: 823464,
              adult: false,
              backdrop_path: "/j3Z3XktmWB1VhsS8iXNcrR86PXi.jpg",
              genre_ids: [28, 878, 12, 14],
              original_language: "en",
              original_title: "Godzilla x Kong: The New Empire",
              overview: "Following their explosive showdown, Godzilla and Kong must reunite against a colossal undiscovered threat hidden within our world, challenging their very existence – and our own.",
              popularity: 3269.222,
              poster_path: "/gmGK5Gw5CIGMPhOmTO0bNA9Q66c.jpg",
              release_date: "2024-03-27",
              title: "Godzilla x Kong: The New Empire",
              video: false,
              vote_average: 6.7,
              vote_count: 504)
    }
}

extension Movie {
    public func getPosterURL() -> String? {
        if let poster_path = poster_path {
            return "https://image.tmdb.org/t/p/w500/" + poster_path
        }
        return nil
    }
}
