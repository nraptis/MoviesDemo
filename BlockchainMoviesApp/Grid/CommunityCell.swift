//
//  CommunityCell.swift
//  BlockchainMoviesApp
//
//  Created by Nick Nameless on 4/18/24.
//

import SwiftUI

struct CommunityCell: View {
    
    struct CommunityCellConstants {
        static let outerRadius = CGFloat(16.0)
        static let innerRadius = CGFloat(16.0)
        
        static let lineThickness = CGFloat(2.0)
        
        static let bottomAreaHeight = CGFloat(44.0)
        
        
    }
    
    
    @Environment (CommunityViewModel.self) var communityViewModel: CommunityViewModel
    @Environment (GridCellModel.self) var gridCellModel: GridCellModel
    
    var body: some View {
        
        let x = gridCellModel.x
        let y = gridCellModel.y
        let width = gridCellModel.width
        let height = gridCellModel.height
        return ZStack {
            getMainContent(width: width, height: height)
        }
        .frame(width: gridCellModel.width, height: gridCellModel.height)
        .background(gridCellModel.isVisible ? .random : .black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: CommunityCellConstants.outerRadius))
        .offset(x: x,
                y: y)
    }
    
    //private static let blankImage = UIImage()
    func getMainContent(width: CGFloat, height: CGFloat) -> some View {
        
        var image: UIImage?
        
        var isUninitialized = false
        var isDownloading = false
        var isDownloadingActively = false
        var isSuccess = false
        var isError = false
        var isMissingModel = false
        var isIllegal = false
        var isMissingKey = false
        
        
        
        switch gridCellModel.state {
        case .uninitialized:
            isUninitialized = true
            
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
            isIllegal = true
        case .missingModel:
            isMissingModel = true
        case .missingKey:
            isMissingKey = true
        }
        
        return ZStack {
            
            getSuccessContent(width: width, height: height, image: image)
                .opacity(isSuccess ? 1.0 : 0.0)
            getSuccessContent(width: width, height: height, image: image)
                .opacity(isSuccess ? 1.0 : 0.0)
            getSuccessContent(width: width, height: height, image: image)
                .opacity(isSuccess ? 1.0 : 0.0)
            
            
            getJunkContent(width: width, height: height)
                .opacity(isSuccess ? 0.0 : 1.0)
            getJunkContent(width: width, height: height)
                .opacity(isSuccess ? 0.0 : 1.0)
            getJunkContent(width: width, height: height)
                .opacity(isSuccess ? 0.0 : 1.0)
        }
    }
    
    func getMask(width: CGFloat, height: CGFloat) -> Path {
        let innerRectX = CommunityCellConstants.lineThickness
        let innerRectY = CommunityCellConstants.lineThickness
        let innerRectWidth = width - (CommunityCellConstants.lineThickness + CommunityCellConstants.lineThickness)
        let innerRectHeight = height - (CommunityCellConstants.bottomAreaHeight + CommunityCellConstants.lineThickness)
        let innerRectCornerRadius = CommunityCellConstants.innerRadius
        var result = Rectangle().path(in: CGRect(x: 0.0,
                                                 y: 0.0,
                                                 width: width,
                                                 height: height))
        result.addRoundedRect(in: CGRect(x: innerRectX,
                                         y: innerRectY,
                                         width: innerRectWidth,
                                         height: innerRectHeight),
                        cornerSize: CGSize(width: innerRectCornerRadius,
                                           height: innerRectCornerRadius))
        
        //.mask(getMask(width: width, height: height).fill(style: FillStyle(eoFill: true)))
        
        return result
    }
    
    func getSuccessContent(width: CGFloat, height: CGFloat, image: UIImage?) -> some View {
        
        ZStack {
            
            ImageViewRepresentable(image: image)
                .frame(width: width, height: height)
            
            /*
            Image(uiImage: image)
                .resizable()
                .frame(width: width, height: height)
            */
            /*
            Rectangle()
                .foregroundStyle(.regularMaterial)
                .preferredColorScheme(.dark)
             .mask(getMask(width: width, height: height).fill(style: FillStyle(eoFill: true)))
            */
        }
        
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
