//
//  ThumbGrid.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import SwiftUI

protocol ThumbGridConforming: Identifiable {
    var index: Int { get }
}

struct ThumbGrid<Item, ItemView>: View where Item: ThumbGridConforming, ItemView: View {
    
    let list: [Item]
    let content: (Item) -> ItemView
    
    @MainActor func thumb(item: Item) -> some View {
        return content(item)
    }
    
    var body: some View {
        ForEach(list) { item in
            thumb(item: item)
        }
    }
}
