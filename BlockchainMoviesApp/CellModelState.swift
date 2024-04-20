//
//  CellModelState.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/19/24.
//

import UIKit

enum CellModelState: Equatable {
    
    case uninitialized
    
    case downloading
    case downloadingActively
    
    case success(UIImage)
    
    case error
    
    case illegal
    case missingModel // There is no web service model downloaded for this slot.
    //                   It may be as the result of a refresh, or a connection loss.
    
    case missingKey // This is going to be a cell with no image URL.
}
