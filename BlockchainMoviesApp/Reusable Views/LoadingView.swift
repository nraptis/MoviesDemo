//
//  LoadingViewTwo.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/11/24.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(DarkwingDuckTheme.gray900)
                        .scaleEffect(1.4)
                }
                .frame(width: 80.0, height: 90.0)
                .background(RoundedRectangle(cornerRadius: 16.0).foregroundColor(DarkwingDuckTheme.gray300))
                Spacer()
            }
            Spacer()
        }
        .background(DarkwingDuckTheme.gray500)
    }
}
