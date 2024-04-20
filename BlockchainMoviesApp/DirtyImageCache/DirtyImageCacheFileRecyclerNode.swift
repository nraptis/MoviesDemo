//
//  DirtyImageCacheFileRecyclerNode.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/9/24.
//

import UIKit

class DirtyImageCacheFileRecyclerNode {
    var prev: DirtyImageCacheFileRecyclerNode?
    var next: DirtyImageCacheFileRecyclerNode?
    var key: String
    var imageNumber: Int
    var imagePath: String
    init(key: String, imageNumber: Int, imagePath: String) {
        self.key = key
        self.imageNumber = imageNumber
        self.imagePath = imagePath
    }
    
    func updateImage(_ image: UIImage) {
        let filePath = FileUtils.shared.getDocumentPath(fileName: imagePath)
        FileUtils.shared.savePNG(image: image, filePath: filePath)
    }
    
    func loadImage() -> UIImage? {
        let filePath = FileUtils.shared.getDocumentPath(fileName: imagePath)
        return FileUtils.shared.loadImage(filePath)
    }
    
    func purge() {
        let filePath = FileUtils.shared.getDocumentPath(fileName: imagePath)
        FileUtils.shared.deleteFile(filePath)
    }
    
    func save(fileBuffer: FileBuffer) {
        fileBuffer.writeInt32(Int32(imageNumber))
        fileBuffer.writeString(key)
        fileBuffer.writeString(imagePath)
    }
}
