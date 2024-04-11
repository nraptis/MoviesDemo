//
//  CommunityGrid.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import SwiftUI

struct CommunityGrid: View {
    
    @Environment (CommunityViewModel.self) var communityViewModel: CommunityViewModel
    let layoutHash: Int
    
    var body: some View {
        GeometryReader { containerGeometry in
            list(containerGeometry)
                .refreshable {
                    await communityViewModel.refresh()
                }
        }
    }
    
    @MainActor private func list(_ containerGeometry: GeometryProxy) -> some View {
        let layout = communityViewModel.layout
        let numberOfCells = communityViewModel.model.numberOfCells
        
        let layoutWidth = communityViewModel.layoutWidth
        let layoutHeight = communityViewModel.layoutHeight
        
        
        layout.registerContainer(containerGeometry, numberOfCells)
        return List {
            GeometryReader { scrollContentGeometry in
                grid(containerGeometry, scrollContentGeometry)
            }
            .frame(width: layoutWidth,
                   height: layoutHeight)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
    
    @MainActor private func grid(_ containerGeometry: GeometryProxy, _ scrollContentGeometry: GeometryProxy) -> some View {
        let layout = communityViewModel.layout
        layout.registerScrollContent(scrollContentGeometry)
        communityViewModel.registerScrollContent(scrollContentGeometry)
        let allVisibleCellModels = communityViewModel.allVisibleCellModels
        
        /*
        return VStack {
            
        }
        .frame(width: containerGeometry.size.width, height: containerGeometry.size.height)
        .background(RoundedRectangle(cornerRadius: 20.0).foregroundStyle(Color.red))
        */
        
        return ThumbGrid(list: allVisibleCellModels, layout: layout) { gridCellModel in
            
            let index = gridCellModel.index
            
            let width = layout.getWidth(at: index)
            let height = layout.getHeight(at: index)
            
            let communityCellModel = communityViewModel.getCommunityCellModel(at: index)
            let image = communityViewModel.getCellImage(at: index)
            let didImageDownloadFail = communityViewModel.didCellImageDownloadFail(at: index)
            let isImageDownloadActive = communityViewModel.isCellImageDownloadActive(at: index)
            
            return CommunityCell(communityCellModel: communityCellModel,
                                 index: index,
                                 //layoutHash: layoutHash,
                                 width: width,
                                 height: height,
                                 image: image,
                                 didImageDownloadFail: didImageDownloadFail,
                                 isImageDownloadActive: isImageDownloadActive) {
                communityViewModel.forceRestartDownload(at: index)
            }
            
            /*
            VStack {
                
            }
            .frame(width: layout.getWidth(cellModel.index),
                   height: layout.getHeight(cellModel.index))
            .background(RoundedRectangle(cornerRadius: 20.0).foregroundStyle(Color.red))
            */
            
            /*
            ThumbView(thumbModel: viewModel.thumbModel(at: cellModel.index),
                      width: layout.getWidth(cellModel.index),
                      height: layout.getHeight(cellModel.index),
                      downloadDidSucceed: viewModel.didThumbDownloadSucceed(cellModel.index),
                      downloadDidFail: viewModel.didThumbDownloadFail(cellModel.index),
                      activelyDownloading: viewModel.isThumbDownloadingActively(cellModel.index)) {
                viewModel.forceRestartDownload(cellModel.index)
            }
            */
        }
        
    }
}
