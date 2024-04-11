//
//  DirtyImageDownloaderTask.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import UIKit

class DirtyImageDownloaderTask: NSObject, URLSessionDelegate {
    
    weak var downloader: DirtyImageDownloader?
    weak var item: (any DirtyImageDownloaderType)?
    
    @DirtyImageDownloaderActor var isActive = false
    @DirtyImageDownloaderActor private(set) var priority: Int = 0
    
    @DirtyImageDownloaderActor private(set) var isInvalidated = false
    @DirtyImageDownloaderActor private(set) var isCompleted = false
    
    //private(set) var id: Int
    private(set) var index: Int
    
    var isVisited = false
    
    var task: Task<Void, Never>?
    
    init(downloader: DirtyImageDownloader, item: any DirtyImageDownloaderType) {
        self.downloader = downloader
        self.item = item
        //self.id = item.id
        self.index = item.index
    }
    
    @DirtyImageDownloaderActor func setPriority(_ priority: Int) {
        self.priority = priority
    }
    
    @DirtyImageDownloaderActor func invalidate() async {
        
        isInvalidated = true
        isActive = false
        
        task?.cancel()
        task = nil
        
        if let downloader = downloader {
            await MainActor.run {
                downloader.handleDownloadTaskDidInvalidate(task: self)
            }
        }
        
        downloader = nil
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
                downloader.handleDownloadTaskDidFail(task: self)
            }
            self.downloader = nil
            return
        }
        
        guard let urlString = item.urlString else {
            self.isActive = false
            await MainActor.run {
                downloader.handleDownloadTaskDidFail(task: self)
            }
            self.downloader = nil
            return
        }
        
        guard let url = URL(string: urlString) else {
            self.isActive = false
            await MainActor.run {
                downloader.handleDownloadTaskDidFail(task: self)
            }
            self.downloader = nil
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        /*
        let urlSession = URLSession(configuration: URLSessionConfiguration.default,
                                    delegate: self,
                                    delegateQueue: nil)
         */
        
        var _data: Data?
        var _response: URLResponse?
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            _data = data
            _response = response
        } catch let error {
            self.isActive = false
            await MainActor.run {
                downloader.handleDownloadTaskDidFail(task: self)
            }
            self.downloader = nil
            return
        }
        
        let data = _data
        let response = _response
        
        guard let httpResponse = response as? HTTPURLResponse else {
            isActive = false
            await MainActor.run {
                downloader.handleDownloadTaskDidFail(task: self)
            }
            self.downloader = nil
            return
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            isActive = false
            await MainActor.run {
                downloader.handleDownloadTaskDidFail(task: self)
            }
            self.downloader = nil
            return
        }
        
        isCompleted = true
        
        if isInvalidated {
            isActive = false
            return
        }
        
        guard let data = data else {
            isActive = false
            await MainActor.run {
                downloader.handleDownloadTaskDidFail(task: self)
            }
            self.downloader = nil
            return
        }
        
        guard let image = UIImage(data: data) else {
            isActive = false
            await MainActor.run {
                downloader.handleDownloadTaskDidFail(task: self)
            }
            self.downloader = nil
            return
        }
        
        //print("Image Downloaded For \(index) @ \(Int(image.size.width + 0.5)) x \(Int(image.size.height + 0.5))")
        
        var width = CGFloat(200.0)
        var height = CGFloat(300.0)
        
        if Device.isPad {
            width = 100.0
            height = 150.0
        }
        
        guard let image = image.resizeAspectFill(CGSize(width: width, height: height)) else {
            isActive = false
            await MainActor.run {
                downloader.handleDownloadTaskDidFail(task: self)
            }
            self.downloader = nil
            return
        }
        
        isActive = false
        await MainActor.run {
            downloader.handleDownloadTaskDidSucceed(task: self, image: image)
        }
        self.downloader = nil
        self.item = nil
        
    }
    
}
