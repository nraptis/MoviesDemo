//
//  CommunityCell.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/18/24.
//

import SwiftUI

struct CommunityCell: View {
    
    struct CommunityCellConstants {
        static let outerRadius = CGFloat(16.0)
        static let innerRadius = CGFloat(14.0)
        
        static let buttonRadius = CGFloat(8.0)
        
        
        static let lineThickness = CGFloat(4.0)
        
        static let bottomAreaHeight = CGFloat(44.0)
    }
    
    @Environment (CommunityViewModel.self) var communityViewModel: CommunityViewModel
    @Environment (GridCellModel.self) var gridCellModel: GridCellModel
    
    var body: some View {
        
        //
        // Most of the time missing model will be
        // at the end of the screen, when our connection
        // failed for one reason or another.
        //
        
        let x = gridCellModel.x
        let y = gridCellModel.y
        let width = gridCellModel.width
        let height = gridCellModel.height
        return ZStack {
            getMainContent(width: width, height: height)
        }
        .frame(width: gridCellModel.width, height: gridCellModel.height)
        //.background(DarkwingDuckTheme.gray900)
        .background(Color(red: Double.random(in: 0.25...0.75),
                          green: Double.random(in: 0.25...0.75),
                          blue: Double.random(in: 0.25...0.75)))
        .clipShape(RoundedRectangle(cornerRadius: CommunityCellConstants.outerRadius))
        .offset(x: x,
                y: y)
        .opacity(gridCellModel.isVisible ? 1.0 : 0.0)
    }
    
    private static let blankImage = UIImage()
    func getMainContent(width: CGFloat, height: CGFloat) -> some View {
        
        var image: UIImage = Self.blankImage
        
        var isMissing = false
        var isDownloading = false
        var isDownloadingActively = false
        var isSuccess = false
        var isError = false
        
        switch gridCellModel.state {
        case .downloading:
            isDownloading = true
        case .downloadingActively:
            isDownloading = true
            isDownloadingActively = true
        case .success(let _image):
            isSuccess = true
            image = _image
        case .error:
            isError = true
        case .illegal:
            isMissing = true
        case .missingModel:
            isMissing = true
        case .missingKey:
            isMissing = true
        }
        
        var innerWidth = width - (CommunityCellConstants.lineThickness + CommunityCellConstants.lineThickness)
        if innerWidth < 0 {
            innerWidth = 0
        }
        
        var innerHeight = height - (CommunityCellConstants.lineThickness + CommunityCellConstants.lineThickness)
        if innerHeight < 0 {
            innerHeight = 0
        }
        
        return ZStack {
            
            if isMissing {
                getMisingContent(width: innerWidth, height: innerHeight)
            }
                
            if isError {
                getErrorContent(width: innerWidth, height: innerHeight)
            }
            
            if isDownloading {
                getDownloadingContent(width: innerWidth, height: innerHeight, active: isDownloadingActively)
            }
            
            if isSuccess {
                getSuccessContent(width: innerWidth, height: innerHeight, image: image)
            }
            
            /*
            
            Text("\(gridCellModel.layoutIndex)")
                .font(.system(size: 32).bold())
                .foregroundStyle(Color.red)
                .background(Color.black.opacity(0.5))
            
            */
        }
    }
    
    func getSuccessContent(width: CGFloat, height: CGFloat, image: UIImage) -> some View {
        
        ZStack {
            
            DarkwingDuckTheme.gray050
            
            Button {
                Task { @MainActor in
                    await communityViewModel.handleCellClicked(at: gridCellModel.layoutIndex)
                }
            } label: {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: width, height: height)
                    
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: CommunityCellConstants.innerRadius))

    }
    
    func getMisingContent(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            ZStack {
                Image(systemName: "questionmark")
                    .font(.system(size: Device.isPad ? 32 : 24))
                    .foregroundStyle(DarkwingDuckTheme.gray700)
            }
            .frame(width: Device.isPad ? 56.0 : 44.0,
                   height: Device.isPad ? 56.0 : 44.0)
            .background(RoundedRectangle(cornerRadius: CommunityCellConstants.buttonRadius).foregroundStyle(DarkwingDuckTheme.gray300))
        }
        .frame(width: width, height: height)
        .background(RoundedRectangle(cornerRadius: CommunityCellConstants.innerRadius).foregroundStyle(DarkwingDuckTheme.gray200))
    }
    
    func getErrorContent(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0.0) {
            
            Spacer(minLength: 0.0)
            
            ZStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: Device.isPad ? 32 : 24))
                    .foregroundStyle(DarkwingDuckTheme.naughtyYellow)
                    
            }
            .frame(width: Device.isPad ? 56.0 : 44.0,
                   height: Device.isPad ? 56.0 : 44.0)
            Button {
                Task { @MainActor in
                    await communityViewModel.handleCellForceRetryDownload(at: gridCellModel.layoutIndex)
                }
            } label: {
                VStack(spacing: 0.0) {
                    
                    ZStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: Device.isPad ? 32 : 24))
                            .foregroundStyle(DarkwingDuckTheme.gray800)
                    }
                    .frame(width: Device.isPad ? 56.0 : 44.0,
                           height: Device.isPad ? 56.0 : 44.0)
                    .background(ZStack {
                        RoundedRectangle(cornerRadius: CommunityCellConstants.buttonRadius).foregroundStyle(DarkwingDuckTheme.gray800)
                            .frame(width: (Device.isPad ? 56.0 : 44.0),
                                   height: (Device.isPad ? 56.0 : 44.0))
                        RoundedRectangle(cornerRadius: CommunityCellConstants.buttonRadius).foregroundStyle(DarkwingDuckTheme.gray300)
                            .frame(width: (Device.isPad ? 56.0 : 44.0) - 4.0,
                                   height: (Device.isPad ? 56.0 : 44.0) - 4.0)
                    })
                }
            }
            
            ZStack {
                
            }
            .frame(width: Device.isPad ? 56.0 : 44.0,
                   height: Device.isPad ? 56.0 : 44.0)
            
            Spacer(minLength: 0.0)
        }
        .frame(width: width, height: height)
        .background(RoundedRectangle(cornerRadius: CommunityCellConstants.innerRadius).foregroundStyle(DarkwingDuckTheme.gray200))
    }
    
    func getDownloadingContent(width: CGFloat, height: CGFloat, active: Bool) -> some View {
        VStack(spacing: 0.0) {
            Spacer(minLength: 0.0)
            Image(systemName: "rays")
                .font(.system(size: Device.isPad ? 32 : 24))
                .foregroundStyle(DarkwingDuckTheme.gray800)
            Spacer(minLength: 0.0)
        }
        .frame(width: width, height: height)
        .background(RoundedRectangle(cornerRadius: CommunityCellConstants.innerRadius)
            .foregroundStyle(active ? DarkwingDuckTheme.gray400 : DarkwingDuckTheme.gray200))
    }
    
}
