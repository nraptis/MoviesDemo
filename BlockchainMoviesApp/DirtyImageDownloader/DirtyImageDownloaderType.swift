//
//  DirtyImageDownloaderType.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import Foundation

protocol DirtyImageDownloaderType: AnyObject, Identifiable, Hashable {
    var id: Int { get }
    var index: Int { get }
    var urlString: String? { get }
}
