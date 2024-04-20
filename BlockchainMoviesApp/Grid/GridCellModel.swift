//
//  GridCellModel.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/19/24.
//

import Foundation

@Observable class GridCellModel: Equatable, ThumbGridConforming {
    
    var state = CellModelState.uninitialized
    var index = -1
    var id = -1
    
    var x = CGFloat(0.0)
    var y = CGFloat(0.0)
    var width = CGFloat(0.0)
    var height = CGFloat(0.0)
    
    @ObservationIgnored var communityCellData: CommunityCellData?
    
    var isVisible = false
    
    static func == (lhs: GridCellModel, rhs: GridCellModel) -> Bool {
        lhs.state == rhs.state && lhs.index == rhs.index
    }
    
}
