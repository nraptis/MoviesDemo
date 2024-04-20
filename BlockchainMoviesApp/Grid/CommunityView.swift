//
//  CommunityView.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import SwiftUI

struct CommunityView: View {
    
    @Environment (CommunityViewModel.self) var communityViewModel: CommunityViewModel
    
    var body: some View {
        
        return GeometryReader { containerGeometry in
            
            let isLandscape = containerGeometry.size.width > containerGeometry.size.height
            
            let logoBarHeight: Int
            let bottomBarHeight: Int
            if Device.isPad {
                if isLandscape {
                    logoBarHeight = 54
                    bottomBarHeight = 44
                } else {
                    logoBarHeight = 62
                    bottomBarHeight = 54
                }
            } else {
                if isLandscape {
                    logoBarHeight = 44
                    bottomBarHeight = 32
                } else {
                    logoBarHeight = 52
                    bottomBarHeight = 44
                }
            }
            
            return VStack(spacing: 0.0) {
                
                getLogoBarContainer(logoBarHeight: CGFloat(logoBarHeight))
                
                ZStack {
                    GeometryReader { geometry in
                        
                        let geometryWidth = geometry.size.width
                        let geometryHeight = geometry.size.height
                        
                        let staticGridLayout = communityViewModel.staticGridLayout
                        staticGridLayout.registerContainer(CGRect(x: 0.0, y: 0.0, width: geometryWidth, height: geometryHeight),
                                                           communityViewModel.numberOfCells)
                        
                        return guts(containerGeometry: geometry)
                    }
                }
                
                getFooterBar(bottomBarHeight: CGFloat(bottomBarHeight))
            }
        }
        .background(DarkwingDuckTheme.gray100)
    }
    
    
    
    //@ViewBuilder
    @MainActor func guts(containerGeometry: GeometryProxy) -> some View {
        ScrollView {
            scrollContent(containerGeometry: containerGeometry)
                .background(.random)
        }
        .listStyle(.plain)
        .refreshable {
            await communityViewModel.refresh()
        }
    }
    
    @MainActor func scrollContent(containerGeometry: GeometryProxy) -> some View {
        
        var contentHeight = communityViewModel.layoutHeight
        if contentHeight < containerGeometry.size.height {
            contentHeight = containerGeometry.size.height
        }
        
        return ZStack {
            GeometryReader { scrollContentGeometry in
                grid(containerGeometry, scrollContentGeometry)
            }
        }
        .frame(width: communityViewModel.layoutWidth,
               height: contentHeight)
    }
    
    @MainActor private func grid(_ containerGeometry: GeometryProxy, _ scrollContentGeometry: GeometryProxy) -> some View {
        
        let contentFrame = scrollContentGeometry.frame(in: .global)
        let containerFrame = containerGeometry.frame(in: .global)

        let frame = CGRect(x: 0.0,
                           y: contentFrame.origin.y - containerFrame.origin.y,
                           width: contentFrame.size.width,
                           height: contentFrame.size.height)
        
        let staticGridLayout = communityViewModel.staticGridLayout
        staticGridLayout.registerScrollContent(frame)
        
        return ThumbGrid(list: communityViewModel.gridCellModels) { gridCellModel in
            CommunityCell()
                .environment(gridCellModel)
        }
    }
    
    @MainActor func getLogoBarContainer(logoBarHeight: CGFloat) -> some View {
        HStack(spacing: 0.0) {
            GeometryReader { geometry in
                getLogoBar(width: geometry.size.width,
                           height: geometry.size.height)
            }
        }
        .frame(height: CGFloat(logoBarHeight))
    }
    
    @MainActor func getFooterBar(bottomBarHeight: CGFloat) -> some View {
        ZStack {
            HStack {
                Spacer()
                VStack {
                    Spacer()
                }
                Spacer()
            }
            if communityViewModel.isNetworkErrorPresent {
                Image(systemName: "exclamationmark.triangle.fill")
                    .renderingMode(.template)
                    .font(.system(size: CGFloat(min(bottomBarHeight - 8, 36))))
                    .foregroundStyle(DarkwingDuckTheme.naughtyYellow)
            }
            
            Button {
                Task {
                    await communityViewModel.fetchPopularMovies(page: communityViewModel.highestPageFetchedSoFar + 1)
                }
                /*
                if communityViewModel.gridCellModels.count > 2 {
                    
                    let index1 = Int.random(in: 0..<communityViewModel.gridCellModels.count)
                    let index2 = Int.random(in: 0..<communityViewModel.gridCellModels.count)
                    print("Swapping \(index1) and \(index2)")
                    
                    let cellModel1 = communityViewModel.gridCellModels[index1]
                    let cellModel2 = communityViewModel.gridCellModels[index2]
                    
                    var newArray = communityViewModel.gridCellModels
                    
                    cellModel1.index += 100
                    
                    newArray[index1] = cellModel2
                    newArray[index2] = cellModel1
                    
                    communityViewModel.gridCellModels = newArray
                    
                }
                */
                
            } label: {
                Text("Swap...")
                    .padding()
            }

            
        }
        .frame(height: CGFloat(bottomBarHeight))
        .background(DarkwingDuckTheme.gray200)
    }
    
    @MainActor func getLogoBar(width: CGFloat, height: CGFloat) -> some View {
        
        let logoMainBodyWidth = 1024
        let logoMainBodyHeight = 158
        
        let fitZoneWidth = (width - 64)
        let fitZoneHeight = (height - 16)
        let mainBodySize = CGSize(width: CGFloat(logoMainBodyWidth),
                                  height: CGFloat(logoMainBodyHeight))
        let fit = CGSize(width: CGFloat(fitZoneWidth), height: CGFloat(fitZoneHeight)).getAspectFit(mainBodySize)
        let scale = fit.scale
        
        return ZStack {
            Image(uiImage: DarkwingDuckTheme.logo)
                .scaleEffect(scale)
        }
        .frame(width: width, height: height)
        .background(DarkwingDuckTheme.gray200)
    }
}
