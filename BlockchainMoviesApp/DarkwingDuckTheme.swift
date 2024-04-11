//
//  DarkwingDuckTheme.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import UIKit
import SwiftUI

struct DarkwingDuckTheme {
    
    static let logo = UIImage(named: "blockchain_logo") ?? UIImage()
    
    static let _gray900 = UIColor(red: 0.87 * 1.02, green: 0.87, blue: 0.87 * 1.05, alpha: 1.0)
    static let _gray800 = UIColor(red: 0.74 * 1.02, green: 0.74, blue: 0.74 * 1.05, alpha: 1.0)
    static let _gray700 = UIColor(red: 0.64 * 1.02, green: 0.64, blue: 0.64 * 1.05, alpha: 1.0)
    static let _gray600 = UIColor(red: 0.56 * 1.02, green: 0.56, blue: 0.56 * 1.05, alpha: 1.0)
    static let _gray500 = UIColor(red: 0.44 * 1.02, green: 0.44, blue: 0.44 * 1.05, alpha: 1.0)
    static let _gray400 = UIColor(red: 0.32 * 1.02, green: 0.32, blue: 0.32 * 1.05, alpha: 1.0)
    static let _gray300 = UIColor(red: 0.24 * 1.02, green: 0.24, blue: 0.24 * 1.05, alpha: 1.0)
    static let _gray200 = UIColor(red: 0.12 * 1.02, green: 0.12, blue: 0.12 * 1.05, alpha: 1.0)
    static let _gray100 = UIColor(red: 0.04 * 1.02, green: 0.04, blue: 0.04 * 1.05, alpha: 1.0)
    
    static let gray900 = Color(uiColor: Self._gray900)
    static let gray800 = Color(uiColor: Self._gray800)
    static let gray700 = Color(uiColor: Self._gray700)
    static let gray600 = Color(uiColor: Self._gray600)
    static let gray500 = Color(uiColor: Self._gray500)
    static let gray400 = Color(uiColor: Self._gray400)
    static let gray300 = Color(uiColor: Self._gray300)
    static let gray200 = Color(uiColor: Self._gray200)
}
