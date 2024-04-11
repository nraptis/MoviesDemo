//
//  CommunityModel.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import Foundation
import BlockChainNetworking

class CommunityModel {
    
    typealias Movie = BlockChainNetworking.Movie
    
    var pageSize = 0
    
    var numberOfItems = 0
    
    var numberOfCells = 0
    var numberOfPages = 0
    
    var highestPageFetchedSoFar = 0
    
    var communityCellModels = [CommunityCellModel?]()
    
    var cellModelQueue = [CommunityCellModel]()
    func withdrawCellModel(index: Int, movie: BlockChainNetworking.Movie) -> CommunityCellModel {
        if cellModelQueue.count > 0 {
            let result = cellModelQueue.removeLast()
            result.movie = movie
            result.index = index
            result.urlString = movie.getPosterURL()
            return result
        } else {
            let result = CommunityCellModel(index: index, movie: movie)
            return result
        }
    }
    
    func depositCellModel(_ cellModel: CommunityCellModel) {
        communityCellModels.append(cellModel)
    }
    
    func getCommunityCellModel(at index: Int) -> CommunityCellModel? {
        if index >= 0 && index < communityCellModels.count {
            return communityCellModels[index]
        }
        return nil
    }
    
    func doesDataExist(at index: Int) -> Bool {
        if index < 0 { return false }
        if index >= communityCellModels.count { return false }
        return communityCellModels[index] != nil
    }
    
    func fetchPopularMovies(page: Int) async throws {
        
        let response = try await BlockChainNetworking.NetworkController.fetchPopularMovies(page: page)
        
        numberOfItems = response.total_results
        
        if response.results.count > pageSize {
            pageSize = response.results.count
        }
        
        var ceiling = (page) * pageSize
        if ceiling > numberOfItems {
            ceiling = numberOfItems
        }
        
        while communityCellModels.count < ceiling {
            communityCellModels.append(nil)
        }
        
        if page > highestPageFetchedSoFar {
            highestPageFetchedSoFar = page
        }
        
        var cellModelIndex = (page - 1) * pageSize
        
        var resultIndex = 0
        
        while resultIndex < pageSize {
            
            if let cellModel = communityCellModels[cellModelIndex] {
                depositCellModel(cellModel)
                communityCellModels[cellModelIndex] = nil
            }
            
            resultIndex += 1
            cellModelIndex += 1
        }
        
        resultIndex = 0
        cellModelIndex = (page - 1) * pageSize
        
        while resultIndex < pageSize {
            if resultIndex < response.results.count {
                let movie = response.results[resultIndex]
                let cellModel = withdrawCellModel(index: cellModelIndex, movie: movie)
                communityCellModels[cellModelIndex] = cellModel
            }
            resultIndex += 1
            cellModelIndex += 1
        }
        
        var _numberOfCells = (highestPageFetchedSoFar) * pageSize
        if _numberOfCells > numberOfItems {
            _numberOfCells = numberOfItems
        }
        
        numberOfCells = _numberOfCells
        numberOfPages = response.total_pages
    }
    
}
