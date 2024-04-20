//
//  DirtyImageDownloaderType.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/9/24.
//

import Foundation

protocol DirtyImageDownloaderType: AnyObject, Identifiable, Hashable {
    var id: Int { get }
    var index: Int { get }
    var urlString: String? { get }
}
