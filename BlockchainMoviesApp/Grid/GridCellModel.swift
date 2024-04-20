//
//  GridCellModel.swift
//  BlockchainMoviesApp
//
//  Created by Nick Nameless on 4/19/24.
//

import Foundation

// This is the model which drives the UI.
@Observable class GridCellModel: Identifiable {
    
    var state = CellModelState.uninitialized
    
    // Note: This index and ID are *NOT* the
    //       "index" of the cell, such as "cell #100 has index 100"
    //       These are just used to uniquify the GridCellModel.
    //       We use the SAME grid cell models, and swap the content
    //       of the model. This way, we are not causing the parent
    //       view to update, because the number of cells stays constant.
    //       When the device is rotated, it will not stay constant though.
    //
    //var index = -1
    var id = -1
    
    // Note: This index mirrors the layout index,
    //       which will be the same as communityCellData.index
    //       if communityCellData exists...
    @ObservationIgnored var layoutIndex = -1
    
    var x = CGFloat(0.0)
    var y = CGFloat(0.0)
    var width = CGFloat(0.0)
    var height = CGFloat(0.0)
    
    @ObservationIgnored var communityCellData: CommunityCellData?
    
    var isVisible = false
    
    //static func == (lhs: GridCellModel, rhs: GridCellModel) -> Bool {
    //    lhs === rhs
    //}
    
}
