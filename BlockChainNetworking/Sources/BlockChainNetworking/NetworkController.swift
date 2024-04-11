//
//  File.swift
//  
//
//  Created by Nicky Taylor on 4/8/24.
//

import Foundation

public struct NetworkController {
    
    static let apiKey = "82951838f8541db71be0a09ae99f6519"
    static let apiReadAccessToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI4Mjk1MTgzOGY4NTQxZGI3MWJlMGEwOWFlOTlmNjUxOSIsInN1YiI6IjY2MTQ5ZDcwMGJiMDc2MDE4NTMxYTVkZCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.PAp5NOGOhJCB3DRAqdj0fI8kIOn7obWFb9T0EKVV-HM"
    
    public static func fetchPopularMovies(page: Int) async throws -> MoviesResponse {
        
        let urlSession = URLSession(configuration: URLSessionConfiguration.default)
        
        let urlString = "https://api.themoviedb.org/3/movie/popular?api_key=\(Self.apiKey)&page=\(page)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let request = URLRequest(url: url)
        
        let (data, response) = try await urlSession.data(for: request)
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
        
        do {
            let result = try jsonDecoder.decode(MoviesResponse.self, from: data)
            return result
            
        } catch let DecodingError.keyNotFound(key, context) {
            print("Decoding error (keyNotFound): \(key) not found in \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        } catch let DecodingError.dataCorrupted(context) {
            print("Decoding error (dataCorrupted): data corrupted in \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        } catch let DecodingError.typeMismatch(type, context) {
            print("Decoding error (typeMismatch): type mismatch of \(type) in \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        } catch let DecodingError.valueNotFound(type, context) {
            print("Decoding error (valueNotFound): value not found for \(type) in \(context.debugDescription)")
            print("Coding path: \(context.codingPath)")
        } catch let error {
            throw error
        }
        
        throw NSError(domain: "fetchPopularMovies, JSON decoding error", code: 1000)
    }
}
