//
//  DirtyImageCache.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/9/24.
//

import UIKit

@globalActor actor DirtyImageCacheActor {
    static let shared = DirtyImageDownloaderActor()
}

struct KeyAndIndexPair {
    let key: String
    let index: Int
}

struct KeyIndexImage {
    let image: UIImage
    let key: String
    let index: Int
}

extension KeyAndIndexPair: Equatable {
    
}

extension KeyAndIndexPair: Hashable {
    
}

class DirtyImageCache {
    
    private let name: String
    
    private let DISABLED = true
    
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
    }
    
    @DirtyImageCacheActor func purge() async {
        try? await Task.sleep(nanoseconds: 100_000)
        fileRecycler.clear()
    }
    
    @DirtyImageCacheActor func cacheImage(_ image: UIImage, _ key: String) async {
        
        if DISABLED { return }
        
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
                Task {
                    await save()
                }
            }
        }
    }
    
    @DirtyImageCacheActor func batchRetrieve(_ keyAndIndexPairs: [KeyAndIndexPair]) async -> [KeyAndIndexPair: UIImage] {
        var result = [KeyAndIndexPair: UIImage]()
        
        if DISABLED { return result }
        
        for keyAndIndexPair in keyAndIndexPairs {
            var image: UIImage?
            if let node = self.fileRecycler.get(keyAndIndexPair.key) {
                image = node.loadImage()
            }
            if let image = image {
                result[keyAndIndexPair] = image
            }
            try? await Task.sleep(nanoseconds: 100_000)
        }
        return result
    }
    
    @DirtyImageCacheActor func singleRetrieve(_ keyAndIndexPair: KeyAndIndexPair) async -> UIImage? {
        
        if DISABLED { return nil }
        
        var image: UIImage?
        if let node = self.fileRecycler.get(keyAndIndexPair.key) {
            image = node.loadImage()
        }
        if let image = image {
            return image
        }
        return nil
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
    
    lazy private var filePath: String = {
        let fileName = "image_cache_" + name + ".cache"
        return FileUtils.shared.getDocumentPath(fileName: fileName)
    }()
    
    @DirtyImageCacheActor private var _isSaving = false
    @DirtyImageCacheActor private var _isSavingEnqueued = false
    @DirtyImageCacheActor private func save() async {
        if _isSaving {
            _isSavingEnqueued = true
            return
        }
        
        let filePath = filePath
        
        _isSaving = true
        
        let fileBuffer = FileBuffer()
        
        fileRecycler.save(fileBuffer: fileBuffer)
        
        fileBuffer.save(filePath: filePath)
        
        // Sleep for 5 seconds...
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        _isSaving = false
        
        if _isSavingEnqueued {
            Task { @DirtyImageCacheActor in
                _isSavingEnqueued = false
                await save()
            }
        }
    }
    
    @DirtyImageCacheActor func load() {
        let filePath = filePath
        let fileBuffer = FileBuffer()
        fileBuffer.load(filePath: filePath)
        fileRecycler.load(fileBuffer: fileBuffer)
    }
}
