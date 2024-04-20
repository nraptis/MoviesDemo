//
//  Color+Random.swift
//  BlockchainMoviesApp
//
//  Created by Nick Nameless on 4/19/24.
//

import SwiftUI

extension ShapeStyle where Self == Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}
