//
//  LoadingViewTwo.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/11/24.
//

import SwiftUI

struct LoadingView: View {
    
    var body: some View {
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: Device.isPad ? 12.0 : 8.0) {
                    ZStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(DarkwingDuckTheme.gray800)
                            .scaleEffect(Device.isPad ? 1.5 : 1.25)
                    }
                    .frame(width: Device.isPad ? 74.0 : 56.0,
                           height: Device.isPad ? 74.0 : 56.0)
                    .background(RoundedRectangle(cornerRadius: 12.0))
                    .foregroundStyle(DarkwingDuckTheme.gray150)
                }
                .foregroundColor(DarkwingDuckTheme.gray800)
                Spacer()
            }
            Spacer()
        }
        .background(DarkwingDuckTheme.gray050)
    }
}
