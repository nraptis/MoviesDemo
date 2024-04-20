//
//  DirtyImageCacheFileRecycler.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/9/24.
//

import UIKit

class DirtyImageCacheFileRecycler {
    
    private let head = DirtyImageCacheFileRecyclerNode(key: "head", imageNumber: -1, imagePath: "")
    private let tail = DirtyImageCacheFileRecyclerNode(key: "tail", imageNumber: -1, imagePath: "")
    private var table = [String: DirtyImageCacheFileRecyclerNode]()
    private(set) var count = 0
    private var capacity = 0
    
    init(capacity: Int) {
        self.capacity = capacity
        head.next = tail
        tail.prev = head
    }
    
    func put(_ key: String, _ imageNumber: Int, _ imagePath: String) {
        var node: DirtyImageCacheFileRecyclerNode! = table[key]
        if node == nil {
            if count == capacity {
                node = dequeue()
                node.key = key
                node.imageNumber = imageNumber
                node.imagePath = imagePath
            } else {
                node = DirtyImageCacheFileRecyclerNode(key: key, imageNumber: imageNumber, imagePath: imagePath)
                count += 1
            }
        }
        table[key] = node
        visit(node)
    }
    
    func get(_ key: String) -> DirtyImageCacheFileRecyclerNode? {
        if let node = table[key] {
            visit(node)
            return node
        }
        return nil
    }
    
    func clear() {
        var node: DirtyImageCacheFileRecyclerNode!
        node = tail.prev
        while node !== head {
            let next = node.prev
            node.prev = nil
            node = next
        }
        
        node = head.next
        while node !== tail {
            let next = node.next
            node.next = nil
            node.purge()
            node = next
        }
        head.next = tail
        tail.prev = head
        count = 0
        table.removeAll()
    }
    
    func dumpToNumberList() -> [Int] {
        var result = [Int]()
        var node: DirtyImageCacheFileRecyclerNode!
        node = head.next
        while node !== tail {
            result.append(node.imageNumber)
            node = node.next
        }
        return result
    }
    
    private func visit(_ node: DirtyImageCacheFileRecyclerNode) {
        node.prev?.next = node.next
        node.next?.prev = node.prev
        head.next!.prev = node
        node.next = head.next
        node.prev = head
        head.next = node
    }
    
    private func dequeue() -> DirtyImageCacheFileRecyclerNode {
        let result: DirtyImageCacheFileRecyclerNode! = tail.prev
        table.removeValue(forKey: result.key)
        result.prev!.next = tail
        tail.prev = result.prev
        result.prev = nil
        result.next = nil
        result.purge()
        return result
    }
    
    func save(fileBuffer: FileBuffer) {
        fileBuffer.writeInt32(Int32(count))
        var node: DirtyImageCacheFileRecyclerNode! = tail.prev
        while node !== head {
            node.save(fileBuffer: fileBuffer)
            node = node.prev
        }
    }
    
    func load(fileBuffer: FileBuffer) {
        clear()
        
        guard let numberOfNodesSaved = fileBuffer.readInt32() else {
            return
        }
        
        if numberOfNodesSaved < 0 || numberOfNodesSaved > 8192 { return }
        
        var index = 0
        while index < numberOfNodesSaved {
            
            guard let _imageNumber = fileBuffer.readInt32() else {
                return
            }
            guard let _key = fileBuffer.readString() else {
                return
            }
            guard let _imagePath = fileBuffer.readString() else {
                return
            }
            let key = _key
            let imageNumber = Int(_imageNumber)
            let imagePath = _imagePath
            
            put(key, imageNumber, imagePath)
            index += 1
        }
    }
}
