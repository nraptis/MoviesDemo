//
//  ThumbGrid.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/9/24.
//

import SwiftUI

struct ThumbGrid<Item, ItemView>: View where Item: Identifiable, ItemView: View {
    
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
