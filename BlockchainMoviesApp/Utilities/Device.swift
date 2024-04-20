//
//  Device.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/9/24.
//

import UIKit

class Device {
    
    let widthPortrait: Float
    let heightPortrait: Float
    let widthLandscape: Float
    let heightLandscape: Float
    
    let widthPortraitScaled: Float
    let heightPortraitScaled: Float
    let widthLandscapeScaled: Float
    let heightLandscapeScaled: Float
    
    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    static var scale: Float {
        Float(UIScreen.main.scale)
    }
    
    init() {
        
        let _screenWidth = Float(Int(UIScreen.main.bounds.size.width + 0.5))
        let _screenHeight = Float(Int(UIScreen.main.bounds.size.height + 0.5))
        
        widthPortrait = _screenWidth < _screenHeight ? _screenWidth : _screenHeight
        heightPortrait = _screenWidth < _screenHeight ? _screenHeight : _screenWidth
        widthLandscape = heightPortrait
        heightLandscape = widthPortrait
        
        widthPortraitScaled = Float(Int(widthPortrait * Self.scale + 0.5))
        heightPortraitScaled = Float(Int(heightPortrait * Self.scale + 0.5))
        widthLandscapeScaled = heightPortraitScaled
        heightLandscapeScaled = widthPortraitScaled
        
        print("Device Portrait  [\(String(format: "%.1f", widthPortrait)) x \(String(format: "%.1f", heightPortrait))]")
        print("Device Landscape [\(String(format: "%.1f", widthLandscape)) x \(String(format: "%.1f", heightLandscape))]")
        print("Device Portrait Scaled  [\(String(format: "%.1f", widthPortraitScaled)) x \(String(format: "%.1f", heightPortraitScaled))]")
        print("Device Landscape Scaled [\(String(format: "%.1f", widthLandscapeScaled)) x \(String(format: "%.1f", heightLandscapeScaled))]")
        
    }
}
