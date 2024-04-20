//
//  CommunityView.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/9/24.
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
        .background(DarkwingDuckTheme.gray050)
    }
    
    @MainActor func guts(containerGeometry: GeometryProxy) -> some View {
        
        let containerFrame = containerGeometry.frame(in: .global)
        let geometryWidth = containerFrame.width
        let geometryHeight = containerFrame.height
        
        //
        // This is a little bit tricky. We have bundled the
        // error and no items view in with the scroll view.
        // The loading view is really only there for the
        // initial load. Once we get an item or an error,
        // all the loading will be done with the pull-refresh.
        //
        var isScrollViewShowing = false
        var isLoadingViewShowing = false
        if communityViewModel.isAnyItemPresent {
            isScrollViewShowing = true
        } else {
            if communityViewModel.isFetching {
                isLoadingViewShowing = true
            } else {
                isScrollViewShowing = true
            }
        }
        
        return ZStack {
            ScrollView {
                scrollContent(containerGeometry: containerGeometry)
                    .background(DarkwingDuckTheme.gray050)
            }
            .refreshable {
                await communityViewModel.refresh()
            }
            .onAppear {
                UIRefreshControl.appearance().tintColor = DarkwingDuckTheme._gray700
            }
            .opacity(isScrollViewShowing ? 1.0 : 0.0)
            
            LoadingView()
                .frame(width: geometryWidth, height: geometryHeight)
                .opacity(isLoadingViewShowing ? 1.0 : 0.0)
        }
        .frame(width: geometryWidth, height: geometryHeight)
    }
    
    @MainActor func scrollContent(containerGeometry: GeometryProxy) -> some View {
        
        let containerFrame = containerGeometry.frame(in: .global)
        let geometryWidth = containerFrame.width
        let geometryHeight = containerFrame.height
        
        var contentHeight = communityViewModel.layoutHeight
        if contentHeight < containerGeometry.size.height {
            contentHeight = containerGeometry.size.height
        }
        
        var isGridShowing = false
        var isNoItemsShowing = false
        var isErrorShowing = false
        
        if communityViewModel.isAnyItemPresent {
            isGridShowing = true
        } else if communityViewModel.isNetworkErrorPresent {
            isErrorShowing = true
        } else {
            isNoItemsShowing = true
        }
        
        return ZStack(alignment: .top) {
            GeometryReader { scrollContentGeometry in
                grid(containerGeometry, scrollContentGeometry)
            }
            .opacity(isGridShowing ? 1.0 : 0.0)
            
            NoItemsView()
                .frame(width: geometryWidth, height: geometryHeight)
                .opacity(isNoItemsShowing ? 1.0 : 0.0)
            
            ErrorView(text: "An Error Occurred")
                .frame(width: geometryWidth, height: geometryHeight)
                .opacity(isErrorShowing ? 1.0 : 0.0)
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
            Image(systemName: "bolt.trianglebadge.exclamationmark.fill")
                .renderingMode(.template)
                .font(.system(size: CGFloat(min(bottomBarHeight - 14, 22))))
                .foregroundStyle(DarkwingDuckTheme.naughtyYellow)
                .opacity(communityViewModel.isNetworkErrorPresent ? 1.0 : 0.0)
            
        }
        .frame(height: CGFloat(bottomBarHeight))
        .background(DarkwingDuckTheme.gray100)
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
        .background(DarkwingDuckTheme.gray100)
    }
}
