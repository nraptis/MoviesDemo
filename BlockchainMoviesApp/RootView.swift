//
//  RootView.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/12/24.
//

import SwiftUI

struct RootView: View {
    
    @Environment(RootViewModel.self) var rootViewModel: RootViewModel
    @Environment(Router.self) var router: Router
    
    var body: some View {
        @Bindable var router = router
        @Bindable var rootViewModel = rootViewModel
        return NavigationStack(path: $router.navigationPath) {
            CommunityView()
                .environment(router.communityViewModel)
                .navigationDestination(for: MovieDetailsViewModel.self) { movieDetailsViewModel in
                    MovieDetailsView()
                        .environment(movieDetailsViewModel)
                }
        }
        .accentColor(DarkwingDuckTheme.gray700)
        .alert(isPresented: $rootViewModel.isShowingError) {
            Alert(title: Text(rootViewModel.errorTitle)
                  , message: Text(rootViewModel.errorMessage))
        }
        
    }
}
