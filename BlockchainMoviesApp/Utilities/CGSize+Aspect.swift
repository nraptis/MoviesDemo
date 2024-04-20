//
//  CGSize+Aspect.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/9/24.
//

import UIKit

extension CGSize {
    func getAspectFit(_ size: CGSize) -> (size: CGSize, scale: CGFloat) {
        var result = (size: CGSize(width: width, height: height), scale: CGFloat(1.0))
        let epsilon = CGFloat(Math.epsilon)
        if width > epsilon && height > epsilon && size.width > epsilon && size.height > epsilon {
            if (size.width / size.height) > (width / height) {
                result.scale = width / size.width
                result.size.width = width
                result.size.height = result.scale * size.height
            } else {
                result.scale = height / size.height
                result.size.width = result.scale * size.width
                result.size.height = height
            }
        }
        return result
    }
    
    func getAspectFill(_ size: CGSize) -> (size: CGSize, scale: CGFloat) {
        var result = (size: CGSize(width: width, height: height), scale: CGFloat(1.0))
        let epsilon = CGFloat(Math.epsilon)
        if width > epsilon && height > epsilon && size.width > epsilon && size.height > epsilon {
            if (size.width / size.height) < (width / height) {
                result.scale = width / size.width
                result.size.width = width
                result.size.height = result.scale * size.height
            } else {
                result.scale = height / size.height
                result.size.width = result.scale * size.width
                result.size.height = height
            }
        }
        return result
    }
}
