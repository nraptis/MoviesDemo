//
//  File.swift
//  
//
//  Created by Nick Nameless on 4/8/24.
//

import Foundation

protocol NWNetworkControllerImplementing {
    static func fetchPopularMovies(page: Int) async throws -> NWMoviesResponse
    static func fetchMovieDetails(id: Int) async throws -> NWMovieDetails
}

public struct NWNetworkController: NWNetworkControllerImplementing {
    
    static let apiKey = "82951838f8541db71be0a09ae99f6519"
    static let apiReadAccessToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI4Mjk1MTgzOGY4NTQxZGI3MWJlMGEwOWFlOTlmNjUxOSIsInN1YiI6IjY2MTQ5ZDcwMGJiMDc2MDE4NTMxYTVkZCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.PAp5NOGOhJCB3DRAqdj0fI8kIOn7obWFb9T0EKVV-HM"
    
    public static func fetchPopularMovies(page: Int) async throws -> NWMoviesResponse {
        
        //let urlSession = URLSession(configuration: URLSessionConfiguration.default)
        
        let urlString = "https://api.themoviedb.org/3/movie/popular?api_key=\(Self.apiKey)&page=\(page)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let request = URLRequest(url: url)
        //request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // some of the do not use the format
        //let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let jsonDecoder = JSONDecoder()
        //jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        let result = try jsonDecoder.decode(NWMoviesResponse.self, from: data)
        return result
    }
    
    public static func fetchMovieDetails(id: Int) async throws -> NWMovieDetails {
        
        let urlString = "https://api.themoviedb.org/3/movie/\(id)?api_key=\(Self.apiKey)"
    
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let request = URLRequest(url: url)
        //request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let jsonDecoder = JSONDecoder()
        
        let result = try jsonDecoder.decode(NWMovieDetails.self, from: data)
        return result
    }
}
