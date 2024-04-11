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
        
        let layoutHash = communityViewModel.layoutHash
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
                
                HStack(spacing: 0.0) {
                    GeometryReader { geometry in
                        getLogoBar(width: geometry.size.width,
                                   height: geometry.size.height)
                    }
                }
                .frame(height: CGFloat(logoBarHeight))
                
                CommunityGrid(layoutHash: layoutHash)
                
                HStack(spacing: 0.0) {
                    Spacer()
                }
                .frame(height: CGFloat(bottomBarHeight))
                .background(DarkwingDuckTheme.gray300)
            }
        }
    }
    
    func getLogoBar(width: CGFloat, height: CGFloat) -> some View {
        
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

#Preview {
    CommunityView()
}
