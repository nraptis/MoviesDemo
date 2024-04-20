//
//  BlockchainMoviesAppApp.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/8/24.
//

import SwiftUI

@main
struct BlockchainMoviesAppApp: App {
    
    @State var rootViewModel: RootViewModel
    @State var router: Router
    //@State var router = Router()
    
    init() {
        // The ninja way to initialize @State objects.
        let rootViewModel = RootViewModel()
        let router = Router(rootViewModel: rootViewModel)
        self._rootViewModel = State(wrappedValue: rootViewModel)
        self._router = State(wrappedValue: router)
    }
    
    var body: some Scene {
        return WindowGroup {
            RootView()
                .environment(rootViewModel)
                .environment(router)
        }
    }
    /*
    let communityViewModel = CommunityViewModel()
    var body: some Scene {
        WindowGroup {
            CommunityView()
                .environment(communityViewModel)
        }
    }
    */
}
