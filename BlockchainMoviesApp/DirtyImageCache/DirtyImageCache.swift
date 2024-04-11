//
//  DirtyImageCache.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import UIKit

@globalActor actor DirtyImageCacheActor {
    static let shared = DirtyImageDownloaderActor()
}

class DirtyImageCache {
    
    private let name: String
    
    @DirtyImageCacheActor
    private var fileRecycler = DirtyImageCacheFileRecycler(capacity: 4096)
    
    /// Creates a unique file cache object.
    /// - Parameters:
    ///   - name: should be unique for each instance of DirtyImageCache (only numbers, letters, and _)
    ///   - fileCapacity: number of images stored on disk (should be prime number somewhere close to 1,000)
    ///   - ramCapacity: number of images stored in RAM (should be prime number somewhere between 30 and 200,
    ///                  larger than the max number of image displayed on any given screen  (will be flushed on memory warning)
    init(name: String) {
        self.name = name
        
        //TODO: Load Here...
        
    }
    
    @DirtyImageCacheActor func purge() async {
        try? await Task.sleep(nanoseconds: 100_000)
        fileRecycler.clear()
    }
    
    @DirtyImageCacheActor func cacheImage(_ image: UIImage, _ key: String) async {
        if let node = self.fileRecycler.get(key) {
            try? await Task.sleep(nanoseconds: 100_000)
            node.updateImage(image)
        } else {
            let numberList = self.fileRecycler.dumpToNumberList()
            let imageNumber = self.firstMissingPositive(numberList)
            var numberString = "\(imageNumber)"
            let numberDigits = 4
            if numberString.count < numberDigits {
                let zeroArray = [Character](repeating: "0", count: (numberDigits - numberString.count))
                numberString = String(zeroArray) + numberString
            }
            let imagePath = "_cached_image_\(self.name)_\(numberString).png"
            self.fileRecycler.put(key, imageNumber, imagePath)
            if let node = self.fileRecycler.get(key) {
                try? await Task.sleep(nanoseconds: 100_000)
                node.updateImage(image)
            }
        }
    }
    
    @DirtyImageCacheActor func batchRetrieve(_ keys: [String]) async -> [String: UIImage] {
        var result = [String: UIImage]()
        for key in keys {
            var image: UIImage?
            if let node = self.fileRecycler.get(key) {
                image = node.loadImage()
            }
            if let image = image {
                result[key] = image
            }
            try? await Task.sleep(nanoseconds: 100_000)
        }
        return result
    }
    
    private func firstMissingPositive(_ nums: [Int]) -> Int {
        var nums = nums
        for i in nums.indices {
            while nums[i] >= 1 && nums[i] < nums.count && nums[nums[i] - 1] != nums[i] {
                nums.swapAt(i, nums[i] - 1)
            }
        }
        for i in nums.indices {
            if nums[i] != (i + 1) {
                return (i + 1)
            }
        }
        return nums.count + 1
    }
}
