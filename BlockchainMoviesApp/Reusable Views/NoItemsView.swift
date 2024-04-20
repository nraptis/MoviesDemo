//
//  NoItemsView.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/11/24.
//

import SwiftUI

struct NoItemsView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: Device.isPad ? 24.0 : 16.0) {
                    Image(systemName: "popcorn.fill")
                        .font(.system(size: Device.isPad ? 80.0 : 54.0))
                        .tint(DarkwingDuckTheme.gray300)
                    HStack {
                        Text("No Items Loaded")
                            .font(.system(size: Device.isPad ? 24.0 : 16.0).bold())
                    }
                    .frame(maxWidth: 220.0)
                }
                .foregroundColor(DarkwingDuckTheme.gray800)
                Spacer()
            }
            Spacer()
        }
        .background(DarkwingDuckTheme.gray300)
    }
}