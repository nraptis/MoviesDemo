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
        
        let width = gridCellModel.width
        let height = gridCellModel.height
        
        return ZStack {
            
            
            getMainContent(width: width, height: height)
            
            /*
            
            */
            
            
        }
        .frame(width: gridCellModel.width, height: gridCellModel.height)
        .background(gridCellModel.isVisible ? .random : .black.opacity(0.25))
        .offset(x: x,
                y: y)
    }
    
    @ViewBuilder func getMainContent(width: CGFloat, height: CGFloat) -> some View {
        
        switch gridCellModel.state {
        case .success(let image):
            getSuccessContent(width: width, height: height, image: image)
        default:
            getJunkContent(width: width, height: height)
        }
        
    }
    
    func getSuccessContent(width: CGFloat, height: CGFloat, image: UIImage) -> some View {
        
        Image(uiImage: image)
            .resizable()
            .frame(width: width, height: height)
        
    }
    
    func getJunkContent(width: CGFloat, height: CGFloat) -> some View {
        VStack {
            Text("\(gridCellModel.communityCellData?.index ?? -99)")
                .foregroundStyle(Color.red)
            
            ProgressView()
            
            if gridCellModel.communityCellData == nil {
                Text("NULL")
                    .font(.system(.title))
                    .foregroundStyle(Color.blue)
            }
        }
        .frame(width: width, height: height)
    }
    
    
    
}
