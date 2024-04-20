//
//  CommunityCell.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/18/24.
//

import SwiftUI

struct CommunityCell: View {
    
    @Environment (CommunityViewModel.self) var communityViewModel: CommunityViewModel
    @Environment (GridCellModel.self) var gridCellModel: GridCellModel
    
    var body: some View {
        
        var x = gridCellModel.x
        var y = gridCellModel.y
        
        if gridCellModel.isVisible == false {
            x -= 20.0
            y = -24.0
        }
        
        return VStack {
            Text("\(gridCellModel.communityCellData?.index ?? -99)")
                .foregroundStyle(Color.red)
            
            ProgressView()
            
            if gridCellModel.communityCellData == nil {
                Text("NULL")
                    .font(.system(.title))
                    .foregroundStyle(Color.blue)
            }
            
            
        }
        .frame(width: gridCellModel.width, height: gridCellModel.height)
        .background(gridCellModel.isVisible ? .random : .black.opacity(0.25))
        .offset(x: x,
                y: y)
    }
}
