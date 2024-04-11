//
//  DirtyImageDownloader.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import UIKit

@globalActor actor DirtyImageDownloaderActor {
    static let shared = DirtyImageDownloaderActor()
}

protocol DirtyImageDownloaderDelegate: AnyObject {
    func dataDownloadDidStart(_ index: Int)
    func dataDownloadDidSucceed(_ index: Int, image: UIImage)
    func dataDownloadDidFail(_ index: Int)
    func dataDownloadDidCancel(_ index: Int)
}

class DirtyImageDownloader {
    
    var paused = false
    
    weak var delegate: DirtyImageDownloaderDelegate?
    
    private let numberOfSimultaneousDownloads: Int
    init(numberOfSimultaneousDownloads: Int) {
        self.numberOfSimultaneousDownloads = numberOfSimultaneousDownloads
    }
    
    @DirtyImageDownloaderActor private(set) var taskDict = [Int: DirtyImageDownloaderTask]()
    
    @DirtyImageDownloaderActor var taskList: [DirtyImageDownloaderTask] {
        var result = [DirtyImageDownloaderTask]()
        for (_, task) in taskDict {
            result.append(task)
        }
        return result
    }
    
    @DirtyImageDownloaderActor func cancelAll() async {
        for (_, task) in taskDict {
            await task.invalidate()
        }
        taskDict.removeAll(keepingCapacity: true)
    }
    
    @DirtyImageDownloaderActor private var _purgeList = [Int]()
    
    @DirtyImageDownloaderActor func startTasksIfNecessary() async {
        
        var numberOfActiveDownloads = 0
        
        for (key, task) in taskDict {
            if task.item == nil || task.isInvalidated == true || task.isCompleted == true {
                _purgeList.append(key)
            } else {
                if task.isActive {
                    numberOfActiveDownloads += 1
                }
            }
        }
        
        if _purgeList.count > 0 {
            for key in _purgeList {
                if let task = taskDict[key] {
                    await task.invalidate()
                }
                taskDict.removeValue(forKey: key)
            }
            _purgeList.removeAll(keepingCapacity: true)
        }
        
        let numberOfTasksToStart = (numberOfSimultaneousDownloads - numberOfActiveDownloads)
        if numberOfTasksToStart <= 0 { return }
        
        let tasksToStart = chooseTasksToStart(numberOfTasks: numberOfTasksToStart)
        
        for taskToStart in tasksToStart {
            taskToStart.isActive = true
        }
        
        await withTaskGroup(of: Void.self) { taskGroup in
            
            for taskToStart in tasksToStart {
                
                if let item = taskToStart.item {
                    let index = taskToStart.index
                    await MainActor.run {
                        delegate?.dataDownloadDidStart(index)
                    }
                }
                taskGroup.addTask {
                    await taskToStart.fire()
                }
                
            }
        }
    }
    
    @DirtyImageDownloaderActor func forceRestart(_ item: any DirtyImageDownloaderType) async {
        let index = item.index
        await removeDownloadTask(item)
        addDownloadTask(item)
        if let task = taskDict[item.index] {
            await task.fire()
            delegate?.dataDownloadDidStart(index)
        }
    }
    
    @DirtyImageDownloaderActor func addDownloadTaskBatch(_ items: [any DirtyImageDownloaderType]) {
        for item in items {
            addDownloadTask(item)
        }
    }
    
    @DirtyImageDownloaderActor private func addDownloadTask(_ item: any DirtyImageDownloaderType) {
        var shouldCreate = true
        if let existingTask = taskDict[item.index] {
            if !(existingTask.isActive || existingTask.isCompleted || existingTask.isInvalidated) {
                shouldCreate = false
            }
        }
        
        if shouldCreate {
            let newTask = DirtyImageDownloaderTask(downloader: self, item: item)
            taskDict[item.index] = newTask
        }
    }
    
    @DirtyImageDownloaderActor func removeDownloadTask(_ item: any DirtyImageDownloaderType) async {
        if let task = taskDict[item.index] {
            await task.invalidate()
        }
        taskDict.removeValue(forKey: item.index)
    }
    
    @DirtyImageDownloaderActor func setPriorityBatch(_ items: [any DirtyImageDownloaderType], _ priorities: [Int]) {
        var index = 0
        while index < items.count && index < priorities.count {
            let item = items[index]
            let priority = priorities[index]
            if let task = taskDict[item.index] {
                task.setPriority(priority)
            }
            index += 1
        }
    }
    
    @DirtyImageDownloaderActor func setPriority(_ item: any DirtyImageDownloaderType, _ priority: Int) {
        if let task = taskDict[item.index] {
            task.setPriority(priority)
        }
    }
    
    @DirtyImageDownloaderActor private func chooseTasksToStart(numberOfTasks: Int) -> [DirtyImageDownloaderTask] {
        
        var result = [DirtyImageDownloaderTask]()
        
        for (_, task) in taskDict {
            task.isVisited = false
        }
        
        var loopIndex = 0
        while loopIndex < numberOfTasks {
            
            var highestPriority = Int.min
            var chosenTask: DirtyImageDownloaderTask?
            for (_, task) in taskDict {
                if !task.isActive && !task.isVisited {
                    if (chosenTask == nil) || (task.priority > highestPriority) {
                        highestPriority = task.priority
                        chosenTask = task
                    }
                }
            }
            if let task = chosenTask {
                task.isVisited = true
                result.append(task)
            } else {
                break
            }
            
            loopIndex += 1
        }
        
        
        return result
    }
    
    @DirtyImageDownloaderActor func isEnqueued(_ item: any DirtyImageDownloaderType) -> Bool {
        var result = false
        if taskDict[item.index] != nil {
            result = true
        }
        return result
    }
    
    @DirtyImageDownloaderActor func isActivelyDownloading(_ item: any DirtyImageDownloaderType) -> Bool {
        var result = false
        if let task = taskDict[item.index] {
            result = task.isActive
        }
        return result
    }
}

extension DirtyImageDownloader {
    @MainActor func handleDownloadTaskDidInvalidate(task: DirtyImageDownloaderTask) {
        let index = task.index
        delegate?.dataDownloadDidCancel(index)
        Task { @DirtyImageDownloaderActor in
            await startTasksIfNecessary()
        }
    }
    
    @MainActor func handleDownloadTaskDidSucceed(task: DirtyImageDownloaderTask, image: UIImage) {
        let index = task.index
        delegate?.dataDownloadDidSucceed(index, image: image)
        Task { @DirtyImageDownloaderActor in
            await startTasksIfNecessary()
        }
    }
    
    @MainActor func handleDownloadTaskDidFail(task: DirtyImageDownloaderTask) {
        let index = task.index
        delegate?.dataDownloadDidFail(index)
        Task { @DirtyImageDownloaderActor in
            await startTasksIfNecessary()
        }
    }
}
