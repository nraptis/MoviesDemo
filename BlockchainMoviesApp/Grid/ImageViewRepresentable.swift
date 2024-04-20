//
//  ImageViewRepresentable.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/20/24.
//

import UIKit
import SwiftUI

struct ImageViewRepresentable: UIViewRepresentable {
    var image: UIImage?
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }
    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = image
    }
}
