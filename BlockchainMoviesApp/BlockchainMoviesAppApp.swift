//
//  BlockchainMoviesAppApp.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/8/24.
//

import SwiftUI

@main
struct BlockchainMoviesAppApp: App {
    let communityViewModel = CommunityViewModel()
    var body: some Scene {
        WindowGroup {
            CommunityView()
                .environment(communityViewModel)
        }
    }
}
