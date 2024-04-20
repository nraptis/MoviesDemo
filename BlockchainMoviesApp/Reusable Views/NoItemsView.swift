//
//  NoItemsView.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/11/24.
//

import SwiftUI

struct NoItemsView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: Device.isPad ? 12.0 : 8.0) {
                    Image(systemName: "popcorn.fill")
                        .font(.system(size: Device.isPad ? 56 : 44.0))
                    HStack {
                        Text("No Items Loaded")
                            .font(.system(size: Device.isPad ? 20.0 : 16.0, weight: .semibold))
                    }
                    .frame(maxWidth: 220.0)
                }
                .foregroundColor(DarkwingDuckTheme.gray800)
                Spacer()
            }
            Spacer()
        }
        .background(DarkwingDuckTheme.gray050)
    }
}
