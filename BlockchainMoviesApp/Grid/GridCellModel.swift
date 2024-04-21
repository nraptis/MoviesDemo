//
//  GridCellModel.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/19/24.
//

import Foundation

// This is the model which drives the UI.
@Observable class GridCellModel: Identifiable {
    
    // Note: This ID is *NOT* the database index, or the
    //       "index" of the cell, such as "cell #100 has index 100"
    //       This is just used to uniquify the GridCellModel.
    //       We use the SAME grid cell models, and swap the content
    //       of the model. This way, we are not causing the parent
    //       view to update, because the number of cells stays constant.
    //       When the device is rotated, it will not stay constant though.
    //
    //       30 cells on the screen would have "id" [0...29]
    //
    //       They are always the SAME 30 cells.
    //       This minimizes redraws.
    //
    //var index = -1
    @ObservationIgnored var id = -1
    
    //
    // Note: This index mirrors the layout index,
    //       which will be the same as communityCellData.index
    //       if communityCellData exists...
    //
    @ObservationIgnored var layoutIndex = -1
    
    //@ObservationIgnored var communityCellData: CommunityCellData?
    
    //
    // This is how we control the state of the cell.
    // For example, "success" state carries the image.
    //
    var state = CellModelState.illegal
    
    var x = CGFloat(0.0)
    var y = CGFloat(0.0)
    var width = CGFloat(32.0)
    var height = CGFloat(32.0)
    
    var isVisible = false
    
    // Are we ready for the heartbeat process?
    // We just want to make sure it's not being updated
    // by two branches at once...
    @ObservationIgnored var isReadyForHeartbeatTick = 3
}
