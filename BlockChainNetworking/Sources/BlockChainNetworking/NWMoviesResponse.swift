//
//  File.swift
//  
//
//  Created by "Nick" Django Raptis on 4/9/24.
//

import Foundation

public struct NWMoviesResponse {
    public let results: [NWMovie]
    public let page: Int
    public let total_pages: Int
    public let total_results: Int
    
    public init(results: [NWMovie], page: Int, total_pages: Int, total_results: Int) {
        self.results = results
        self.page = page
        self.total_pages = total_pages
        self.total_results = total_results
    }
    
}

extension NWMoviesResponse: Decodable {
    
}
