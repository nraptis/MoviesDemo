//
//  CommunityCell.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import SwiftUI

struct CommunityCell: View {
    
    let communityCellModel: CommunityCellModel?
    let index: Int
    //let layoutHash: Int
    let width: CGFloat
    let height: CGFloat
    let image: UIImage?
    let didImageDownloadFail: Bool
    let isImageDownloadActive: Bool
    let restartAction: (() -> Void)?
    
    private static let tileBackground = RoundedRectangle(cornerRadius: 12)
    
    @ViewBuilder
    var body: some View {
        ZStack {
            if let communityCellModel = communityCellModel {
                
                if let image = image {
                    thumbContent(image, communityCellModel)
                } else if isImageDownloadActive {
                    activelyDownloadingContent(communityCellModel)
                } else if didImageDownloadFail {
                    failedContent(communityCellModel)
                } else {
                    placeholderContent()
                }
                
            } else {
                placeholderContent()
            }
         
            /*
            VStack {
                
                Spacer()
                Text("\(index) isImageDownloadActive = \(isImageDownloadActive)")
                
            }
            */
            
        }
        .frame(width: width, height: height)
    }
    
    private func progressView() -> some View {
        /*
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
        */
        
        Image(systemName: "hourglass")
            .font(.system(size: 32.0))
            .foregroundColor(DarkwingDuckTheme.gray500)
    }
    
    private func thumbContent(_ image: UIImage, _ communityCellModel: CommunityCellModel) -> some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .frame(width: width, height: height)
                .aspectRatio(contentMode: .fill)
                
        }
        .frame(width: width, height: height)
        .clipShape(Self.tileBackground)
        //.background(Self.tileBackground.fill().foregroundColor(DarkwingDuckTheme.gray200).opacity(0.5))
        
    }
    
    private func placeholderContent() -> some View {
        ZStack {
            progressView()
        }
        .frame(width: width, height: height)
        .background(Self.tileBackground.fill().foregroundColor(DarkwingDuckTheme.gray300).opacity(0.5))
    }
    
    private func downloadingContent(_ communityCellModel: CommunityCellModel) -> some View {
        ZStack {
            progressView()
        }
        .frame(width: width, height: height)
        .background(Self.tileBackground.fill().foregroundColor(DarkwingDuckTheme.gray400).opacity(0.5))
    }
    
    private func activelyDownloadingContent(_ communityCellModel: CommunityCellModel) -> some View {
        ZStack {
            progressView()
        }
        .frame(width: width, height: height)
        .background(Self.tileBackground.fill().foregroundColor(DarkwingDuckTheme.gray500))
    }
    
    private func failedContent(_ communityCellModel: CommunityCellModel) -> some View {
        Button {
            restartAction?()
        } label: {
            ZStack {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 46).bold())
                    .foregroundColor(.white)
            }
            .frame(width: width, height: height)
            .background(Self.tileBackground.fill().foregroundColor(DarkwingDuckTheme.gray600))
        }
        .buttonStyle(.plain)
    }
}
