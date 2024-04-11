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
    let layout: GridLayout
    let content: (Item) -> ItemView
    
    @MainActor func thumb(item: Item) -> some View {
        let x = layout.getX(at: item.index)
        let y = layout.getY(at: item.index)
        return content(item).offset(x: x, y: y)
    }
    
    var body: some View {
        ForEach(list) { item in
            thumb(item: item)
        }
    }
}
