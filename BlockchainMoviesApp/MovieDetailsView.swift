//
//  MovieDetailsView.swift
//  BlockchainMoviesApp
//
//  Created by Nick Nameless on 4/12/24.
//

import SwiftUI

struct MovieDetailsView: View {
    
    @Environment (MovieDetailsViewModel.self) var movieDetailsViewModel: MovieDetailsViewModel
    
    var body: some View {
        GeometryReader { geometry in
            outerGuts(geometry: geometry)
        }
        .background(DarkwingDuckTheme.gray200)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(movieDetailsViewModel.nwMovieDetails.title)
                    .font(.system(size: Device.isPad ? 32.0 : 24.0, weight: .bold))
                    .foregroundColor(DarkwingDuckTheme.gray900)
            }
        }
        .toolbarBackground(DarkwingDuckTheme.gray200, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        
    }
    
    @MainActor func outerGuts(geometry: GeometryProxy) -> some View {
        var width = geometry.size.width
        if width > 640.0 {
            width = 640.0
        }
        return HStack {
            Spacer(minLength: 0.0)
            
            VStack {
                GeometryReader { innerGeometry in
                    innerGuts(geometry: innerGeometry)
                }
            }
            .frame(width: width, height: geometry.size.height)
            Spacer(minLength: 0.0)
        }
        .frame(width: geometry.size.width)
        .background(DarkwingDuckTheme.gray100)
    }
    
    @MainActor func innerGuts(geometry: GeometryProxy) -> some View {
        
        let expectedImageWidth = 1280
        let expectedImageHeight = 720
        
        let containerRect = CGRect(x: 0.0,
                                   y: 0.0,
                                   width: geometry.size.width,
                                   height: geometry.size.height)
        let imageRect = CGRect(x: 0.0,
                               y: 0.0,
                               width: CGFloat(expectedImageWidth),
                               height: CGFloat(expectedImageHeight))
        let fit = containerRect.size.getAspectFit(imageRect.size)
        let imageSize = fit.size
        
        var imageScale = CGFloat(1.0)
        if fit.scale > Math.epsilon {
            imageScale = 1.0 / fit.scale
        }
        
        let nwMovieDetails = movieDetailsViewModel.nwMovieDetails
        
        return ScrollView {
            VStack {
                HStack {
                    if let urlString = nwMovieDetails.getBackdropURL(), let url = URL(string: urlString) {
                        
                        AsyncImage(url: url, scale: imageScale) { image in
                            image
                                .resizable()
                        } placeholder: {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(DarkwingDuckTheme.gray900)
                                .scaleEffect(1.2)
                        }
                        
                    } else {
                        ZStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: Device.isPad ? 80.0 : 54.0))
                                .tint(DarkwingDuckTheme.gray300)
                        }
                    }
                }
                .frame(width: imageSize.width, height: imageSize.height)
                .background(DarkwingDuckTheme.gray500)
                
                VStack {
                    if let tagline = nwMovieDetails.tagline?.trimmingCharacters(in: .whitespacesAndNewlines),
                       tagline.count > 0 {
                        Text(tagline)
                            .font(.system(size: Device.isPad ? 32.0 : 24.0, weight: .bold))
                            .foregroundStyle(DarkwingDuckTheme.gray900)
                        Spacer()
                            .frame(height: 20.0)
                    } else {
                        Spacer()
                            .frame(height: 6.0)
                    }
                    
                    if let overview = nwMovieDetails.overview {
                        Text(overview)
                            .font(.system(size: Device.isPad ? 22.0 : 16.0, weight: .regular))
                            .foregroundStyle(DarkwingDuckTheme.gray800)
                            .padding(.bottom, 8.0)
                    }
                    
                    if let homepage = nwMovieDetails.homepage {
                        if let url = URL(string: homepage) {
                            Link("Visit Homepage", destination: url)
                                .font(.system(size: Device.isPad ? 22.0 : 16.0, weight: .semibold, design: .monospaced))
                                .foregroundStyle(DarkwingDuckTheme.naughtyYellow)
                                .padding(.bottom, 8.0)
                        }
                    }
                    
                    VStack {
                        HStack(spacing: Device.isPad ? 24.0 : 18.0) {
                            VStack(alignment: .trailing) {
                                Text("Rating:")
                                    .font(.system(size: Device.isPad ? 24.0 : 16.0, weight: .bold))
                                Text("Votes:")
                                    .font(.system(size: Device.isPad ? 24.0 : 16.0, weight: .bold))
                            }
                            .foregroundStyle(DarkwingDuckTheme.gray700)
                            VStack(alignment: .leading) {
                                Text(String(format: "%.2f", nwMovieDetails.vote_average))
                                    .font(.system(size: Device.isPad ? 24.0 : 16.0, weight: .bold))
                                
                                Text("\(nwMovieDetails.vote_count)")
                                    .font(.system(size: Device.isPad ? 24.0 : 16.0, weight: .bold))
                            }
                            .foregroundStyle(DarkwingDuckTheme.gray900)
                        }
                        .padding(.horizontal, 24.0)
                        
                    }
                    .padding(.vertical, 16.0)
                    .background(RoundedRectangle(cornerRadius: 12.0).stroke().foregroundStyle(DarkwingDuckTheme.gray700))
                    .padding(.top, 4.0)
                }
                .padding(.horizontal, 16.0)
                .padding(.top, 4.0)
                
                Spacer()
                    .frame(height: 128.0)
                
                Spacer()
            }
        }
        .background(DarkwingDuckTheme.gray200)
    }
}
