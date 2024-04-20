//
//  DirtyImageDownloaderTask.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/9/24.
//

import UIKit

class DirtyImageDownloaderTask: NSObject, URLSessionDelegate {
    
    weak var downloader: DirtyImageDownloader?
    weak var item: (any DirtyImageDownloaderType)?
    
    @DirtyImageDownloaderActor var isActive = false
    @DirtyImageDownloaderActor private(set) var priority: Int = 0
    @DirtyImageDownloaderActor private(set) var isInvalidated = false
    @DirtyImageDownloaderActor private(set) var priorityHasBeenSetAtLeastOnce = false
    
    private(set) var index: Int
    
    var isVisited = false
    
    var task: Task<Void, Never>?
    
    init(downloader: DirtyImageDownloader, item: any DirtyImageDownloaderType) {
        self.downloader = downloader
        self.item = item
        self.index = item.index
    }
    
    @DirtyImageDownloaderActor func setPriority(_ priority: Int) {
        self.priority = priority
        priorityHasBeenSetAtLeastOnce = true
    }
    
    @DirtyImageDownloaderActor func invalidate() async {
        
        isInvalidated = true
        isActive = false
        
        task?.cancel()
        task = nil
        
        if let downloader = downloader {
            self.downloader = nil
            await MainActor.run {
                downloader.handleDownloadTaskDidInvalidate(task: self)
            }
        }
        
        item = nil
    }
    
    @DirtyImageDownloaderActor func fire() async {
        
        isActive = true
        
        guard let downloader = self.downloader else {
            self.isActive = false
            return
        }
        
        guard let item = self.item else {
            self.isActive = false
            await MainActor.run {
                self.downloader = nil
                downloader.handleDownloadTaskDidFail(task: self)
            }
            
            return
        }
        
        guard let urlString = item.urlString else {
            self.isActive = false
            await MainActor.run {
                self.downloader = nil
                downloader.handleDownloadTaskDidFail(task: self)
            }
            
            return
        }
        
        guard let url = URL(string: urlString) else {
            self.isActive = false
            await MainActor.run {
                self.downloader = nil
                downloader.handleDownloadTaskDidFail(task: self)
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        var _data: Data?
        var _response: URLResponse?
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            _data = data
            _response = response
        } catch {
            self.isActive = false
            await MainActor.run {
                self.downloader = nil
                downloader.handleDownloadTaskDidFail(task: self)
            }
            return
        }
        
        let data = _data
        let response = _response
        
        guard let httpResponse = response as? HTTPURLResponse else {
            isActive = false
            await MainActor.run {
                self.downloader = nil
                downloader.handleDownloadTaskDidFail(task: self)
            }
            return
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            isActive = false
            await MainActor.run {
                self.downloader = nil
                downloader.handleDownloadTaskDidFail(task: self)
            }
            return
        }
        
        if isInvalidated {
            isActive = false
            return
        }
        
        guard let data = data else {
            isActive = false
            await MainActor.run {
                self.downloader = nil
                downloader.handleDownloadTaskDidFail(task: self)
            }
            
            return
        }
        
        guard let image = UIImage(data: data) else {
            isActive = false
            await MainActor.run {
                self.downloader = nil
                downloader.handleDownloadTaskDidFail(task: self)
            }
            
            return
        }
        
        let width = CGFloat(200.0)
        let height = CGFloat(300.0)
        
        guard let image = image.resizeAspectFill(CGSize(width: width, height: height)) else {
            isActive = false
            await MainActor.run {
                self.downloader = nil
                downloader.handleDownloadTaskDidFail(task: self)
            }
            
            return
        }
        
        //TODO: Remove
        //try? await Task.sleep(nanoseconds: 2_250_000_000)
        
        
        //TODO: Remove
        /*
        if Int.random(in: 0...5) == 3 {
            isActive = false
            await MainActor.run {
                self.downloader = nil
                downloader.handleDownloadTaskDidFail(task: self)
            }
            
            return
        }
        */
        
        isActive = false
        await MainActor.run {
            self.downloader = nil
            self.item = nil
            downloader.handleDownloadTaskDidSucceed(task: self, image: image)
        }
    }
}
