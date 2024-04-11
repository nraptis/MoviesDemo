//
//  CommunityViewModel.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import SwiftUI

@Observable class CommunityViewModel {
    
    private static let probeAheadOrBehindRangeForDownloads = 8
    
    static func mock() -> CommunityViewModel {
        return CommunityViewModel()
    }
    
    @ObservationIgnored private let downloader = DirtyImageDownloader(numberOfSimultaneousDownloads: 2)
    @ObservationIgnored fileprivate var didWake = false
    
    //@ImageDictActor
    //@ObservationIgnored
    @ObservationIgnored @MainActor fileprivate var _imageDict = [Int: UIImage]()
    
    //@ObservationIgnored
    @ObservationIgnored @MainActor fileprivate var _failedSet = Set<Int>()
    //@ObservationIgnored
    @ObservationIgnored @MainActor fileprivate var _activeSet = Set<Int>()
    //@ObservationIgnored
    @ObservationIgnored @MainActor fileprivate var _downloadingSet = Set<Int>()
    
    
    @ObservationIgnored @MainActor private var _keyBackMap = [String: CommunityCellModel]()
    
    @ObservationIgnored @MainActor fileprivate var _didStartCheckCacheSet = Set<Int>()
    @ObservationIgnored @MainActor fileprivate var _didFinishCheckCacheSet = Set<Int>()
    
    //@ObservationIgnored
    @ObservationIgnored @MainActor private(set) var model = CommunityModel()
    
    @MainActor @ObservationIgnored var isAssigningTasksToDownloader = false
    @ObservationIgnored var isAssigningTasksToDownloaderEnqueued = false
    
    init() {
        
        downloader.delegate = self
        downloader.paused = true
        
        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil,
                                               queue: nil) { notification in
            print("Memory Warning!!! Purging RAM Images...")
        }
        
        Task { @MainActor in
            layout.delegate = self
            fetchPopularMovies(page: 1)
            
            didWake = true
            downloader.paused = false
            //loadUpDownloaderWithTasks()
            
        }
    }
    
    @MainActor func fetchPopularMovies(page: Int) {
        isFetching = true
        Task {
            await _fetchPopularMovies(page: page)
            await MainActor.run {
                isFetching = false
                layout.registerNumberOfCells(model.numberOfCells)
                assignTasksToDownloader()
                fetchMorePagesIfNecessary()
            }
        }
    }
    
    private func _fetchPopularMovies(page: Int) async {
        do {
            try await model.fetchPopularMovies(page: page)
            
            await MainActor.run {
                
                let firstNewIndex = (page - 1) * model.pageSize
                let ceiling = firstNewIndex + model.pageSize
                
                var index = firstNewIndex
                while index < ceiling {
                    if let communityCellModel = model.getCommunityCellModel(at: index) {
                        _keyBackMap[communityCellModel.cacheKey] = communityCellModel
                    }
                    
                    index += 1
                }
            }
            
        } catch {
            print("fetchPopularMovies Error: \(error.localizedDescription)")
        }
    }
    
    @ObservationIgnored let layout = GridLayout()
    @ObservationIgnored private let imageCache = DirtyImageCache(name: "dirty_cache")
    private(set) var isRefreshing = false
    @ObservationIgnored private var isFetching = false
    
    @ObservationIgnored var allVisibleCellModels = [GridLayout.ThumbGridCellModel]()
    @ObservationIgnored var numberOfCells = 0
    @ObservationIgnored var layoutHeight = CGFloat(320.0)
    @ObservationIgnored var layoutWidth = CGFloat(320.0)
    
    @ObservationIgnored var didFailToFetch = false
    
    @MainActor func getCommunityCellModel(at index: Int) -> CommunityCellModel? {
        return model.getCommunityCellModel(at: index)
    }
    
    
    @MainActor var layoutHash = 0
    @ObservationIgnored var __layoutHash = 0
    @ObservationIgnored var isLayoutHashTriggering = false
    @ObservationIgnored var isLayoutHashTriggeringEnqueued = false
    func triggerLayoutHash() {
        if isLayoutHashTriggering {
            isLayoutHashTriggeringEnqueued = true
            return
        }
        isLayoutHashTriggering = true
        Task {
            __layoutHash += 1
            if __layoutHash > 100_000 { __layoutHash -= 100_000 }
            await MainActor.run {
                layoutHash = __layoutHash
            }
            try? await Task.sleep(nanoseconds: 1_000)
            isLayoutHashTriggering = false
            if isLayoutHashTriggeringEnqueued {
                isLayoutHashTriggeringEnqueued = false
                triggerLayoutHash()
            }
        }
    }
    
    @MainActor func clear() async {
        
        numberOfCells = 0
        layoutHeight = 0
        layoutHeight = 0
        
        layout.clear()
        
        await downloader.cancelAll()
        
        
        _imageDict.removeAll()
        _failedSet.removeAll()
        _activeSet.removeAll()
        _downloadingSet.removeAll()
        _didStartCheckCacheSet.removeAll()
        _didFinishCheckCacheSet.removeAll()
        
        _keyBackMap.removeAll()
        
        model = CommunityModel()
    }
    
    @MainActor func getCellImage(at index: Int) -> UIImage? {
        if let communityCellModel = model.getCommunityCellModel(at: index) {
            if let result = _imageDict[communityCellModel.index] {
                return result
            }
        }
        return nil
    }
    
    func forceRestartDownload(at index: Int) {
        
    }
    
    @MainActor func didCellImageDownloadFail(at index: Int) -> Bool {
        if let communityCellModel = model.getCommunityCellModel(at: index) {
            return _failedSet.contains(communityCellModel.index)
        }
        return false
    }
    
    @MainActor func isCellImageDownloadActive(at index: Int) -> Bool {
        if let communityCellModel = model.getCommunityCellModel(at: index) {
            return _activeSet.contains(communityCellModel.index)
        }
        return false
    }
    
    func refreshWrappingFetch() async {
        // Fake Refresh, 1 seconds
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await fetchPopularMovies(page: 1)
    }
    
    func refresh() async {
        
        isRefreshing = true
        
        //1.) Clear everything, wipe the screen
        await clear()
        
        //3.) do the actual fetch
        await refreshWrappingFetch()
        
        //4.) wrap it up
        await MainActor.run {
            self.isRefreshing = false
            //self.loadUpDownloaderWithTasks()
        }
    }
    
    @MainActor func registerScrollContent(_ scrollContentGeometry: GeometryProxy) {
        
        assignTasksToDownloader()
        
    }
    
    // This is on the MainActor because the UI uses "AllVisibleCellModels"
    @MainActor func fetchMorePagesIfNecessary() {
        
        if isFetching { return }
        
        if allVisibleCellModels.count <= 0 { return }
        
        let pageSize = model.pageSize
        if pageSize < 1 { return }
        
        let numberOfCols = layout.getNumberOfCols()
        //let numberOfItems = model.numberOfItems
        let numberOfPages = model.numberOfPages
        
        var _lowest = allVisibleCellModels[0].index
        var _highest = allVisibleCellModels[0].index
        for cellModel in allVisibleCellModels {
            if cellModel.index < _lowest {
                _lowest = cellModel.index
            }
            if cellModel.index > _highest {
                _highest = cellModel.index
            }
        }
        
        _lowest -= numberOfCols
        _highest += (numberOfCols * 4)
        
        if _lowest < 0 {
            _lowest = 0
        }
        
        // These don't change after these lines. Indicated as such with grace.
        let lowest = _lowest
        let highest = _highest
        
        var checkIndex = lowest
        while checkIndex < highest {
            if !model.doesDataExist(at: checkIndex) {
                
                let pageIndexToFetch = (checkIndex / pageSize)
                let pageToFetch = pageIndexToFetch + 1
                if pageToFetch < numberOfPages {
                    fetchPopularMovies(page: pageToFetch)
                    return
                }
            }
            checkIndex += 1
        }
    }
    
    @ObservationIgnored private var _priorityCommunityCellModels = [CommunityCellModel]()
    @ObservationIgnored private var _priorityList = [Int]()
    
    @ObservationIgnored private var _addDownloadItems = [CommunityCellModel]()
    @ObservationIgnored private var _checkCacheDownloadItems = [CommunityCellModel]()
}

// This is for computing download priorities.
extension CommunityViewModel {
    
    // Distance from the left of the container / screen.
    // Distance from the top of the container / screen.
    private func priority(distX: Int, distY: Int) -> Int {
        let px = (-distX)
        let py = (8192 * 8192) - (8192 * distY)
        return (px + py)
    }
    
    @MainActor func assignTasksToDownloader() {
        if isAssigningTasksToDownloader {
            isAssigningTasksToDownloaderEnqueued = true
            return
        }
        
        if layout.numberOfCells() <= 0 {
            print("Exiting Assign, No Cells...")
            return
        }
        
        let containerTopY = layout.getContainerTop()
        let containerBottomY = layout.getContainerBottom()
        if containerBottomY <= containerTopY {
            print("Exiting Assign, Zero Frame...")
            return
        }
        
        let firstCellIndexOnScreen = layout.firstCellIndexOnScreen() - Self.probeAheadOrBehindRangeForDownloads
        let lastCellIndexOnScreen = layout.lastCellIndexOnScreen() + Self.probeAheadOrBehindRangeForDownloads
        
        guard lastCellIndexOnScreen > firstCellIndexOnScreen else {
            print("Exiting Assign, First/Last Index Foob...")
            return
        }
        
        let containerRangeY = containerTopY...containerBottomY
        
        isAssigningTasksToDownloader = true
        
        
        _addDownloadItems.removeAll(keepingCapacity: true)
        _checkCacheDownloadItems.removeAll(keepingCapacity: true)
        
        Task { @MainActor in
            
            var cellIndex = firstCellIndexOnScreen
            while cellIndex < lastCellIndexOnScreen {
                if let communityCellModel = getCommunityCellModel(at: cellIndex) {
                    
                    let isEnqueuedInDownloader = await downloader.isEnqueued(communityCellModel)
                    
                    if (!_failedSet.contains(communityCellModel.index)) &&
                        (_imageDict[communityCellModel.index] == nil) &&
                        (!isEnqueuedInDownloader) &&
                        (!_downloadingSet.contains(cellIndex)) {
                        
                        if _didFinishCheckCacheSet.contains(communityCellModel.index) {
                            _downloadingSet.insert(cellIndex)
                            _addDownloadItems.append(communityCellModel)
                        } else if !_didStartCheckCacheSet.contains(communityCellModel.index) {
                            _checkCacheDownloadItems.append(communityCellModel)
                        }
                    }
                }
                cellIndex += 1
            }
            
            Task { @DirtyImageCacheActor in
                
                var keysToCheck = [String]()
                for cellData in _checkCacheDownloadItems {
                    await MainActor.run {
                        _ = _didStartCheckCacheSet.insert(cellData.index)
                    }
                    keysToCheck.append(cellData.cacheKey)
                }
                
                let cacheDict = await imageCache.batchRetrieve(keysToCheck)
                
                var missedCacheKeys = Set(keysToCheck)
                for (key, _) in cacheDict {
                    missedCacheKeys.remove(key)
                }
                
                for key in missedCacheKeys {
                    await MainActor.run {
                        if let cellData = self._keyBackMap[key] {
                            self._didFinishCheckCacheSet.insert(cellData.index)
                        }
                    }
                }
                
                var shouldTriggerLayoutHash = false
                
                if missedCacheKeys.count > 0 {
                    shouldTriggerLayoutHash = true
                    isAssigningTasksToDownloaderEnqueued = true
                    triggerLayoutHash()
                }
                
                var listOfKeysAndImages = [(key: String, image: UIImage)]()
                for (key, image) in cacheDict {
                    listOfKeysAndImages.append((key, image))
                }
                
                var index = 0
                while index < listOfKeysAndImages.count {
                    
                    var loopIndex = index
                    let capIndex = index + 3
                    
                    while loopIndex < listOfKeysAndImages.count && loopIndex < capIndex {
                        
                        let keyAndImage = listOfKeysAndImages[loopIndex]
                        await MainActor.run {
                            if let cellData = self._keyBackMap[keyAndImage.key] {
                                self._didFinishCheckCacheSet.insert(cellData.index)
                                self._imageDict[cellData.index] = keyAndImage.image
                                print("Image @ \(cellData.index) from CACHE")
                                
                            }
                        }
                        loopIndex += 1
                    }
                    
                    try? await Task.sleep(nanoseconds: 100_000)
                    
                    shouldTriggerLayoutHash = true
                    
                    index += 3
                }
                
                
                if shouldTriggerLayoutHash {
                    // We could get stuck, as we updated the _imageDict
                    isAssigningTasksToDownloaderEnqueued = true
                    triggerLayoutHash()
                }
                
                
                Task { @DirtyImageDownloaderActor in
                    
                    
                    downloader.addDownloadTaskBatch(_addDownloadItems)
                    
                    let taskList = downloader.taskList
                    
                    _priorityCommunityCellModels.removeAll(keepingCapacity: true)
                    _priorityList.removeAll(keepingCapacity: true)
                    
                    for task in taskList {
                        let cellIndex = task.index
                        if let communityCellModel = await model.getCommunityCellModel(at: cellIndex) {
                            
                            let cellLeftX = await layout.getCellLeft(withCellIndex: cellIndex)
                            let cellTopY = await layout.getCellTop(withCellIndex: cellIndex)
                            let cellBottomY = await layout.getCellBottom(withCellIndex: cellIndex)
                            let cellRangeY = cellTopY...cellBottomY
                            
                            let overlap = containerRangeY.overlaps(cellRangeY)
                            
                            if overlap {
                                
                                let distX = cellLeftX
                                let distY = max(cellTopY - containerTopY, 0)
                                let priority = priority(distX: distX, distY: distY)
                                
                                _priorityCommunityCellModels.append(communityCellModel)
                                _priorityList.append(priority)
                            } else {
                                _priorityCommunityCellModels.append(communityCellModel)
                                _priorityList.append(0)
                            }
                        }
                    }
                    
                    downloader.setPriorityBatch(_priorityCommunityCellModels, _priorityList)
                    
                    await downloader.startTasksIfNecessary()
                    
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    
                    await MainActor.run {
                        isAssigningTasksToDownloader = false
                        if isAssigningTasksToDownloaderEnqueued {
                            isAssigningTasksToDownloaderEnqueued = false
                            assignTasksToDownloader()
                        }
                    }
                }
            }
        }
    }
}

extension CommunityViewModel: GridLayoutDelegate {
    @MainActor func cellsDidEnterScreen(_ cellIndices: [Int]) {

        numberOfCells = layout.numberOfCells()
        allVisibleCellModels = layout.getAllVisibleCellModels()
        layoutWidth = layout.width
        layoutHeight = layout.height
        fetchMorePagesIfNecessary()

        triggerLayoutHash()
    }
    
    @MainActor func cellsDidLeaveScreen(_ cellIndices: [Int]) {

        numberOfCells = layout.numberOfCells()
        allVisibleCellModels = layout.getAllVisibleCellModels()
        layoutWidth = layout.width
        layoutHeight = layout.height
        fetchMorePagesIfNecessary()
        triggerLayoutHash()
    }
}

extension CommunityViewModel: DirtyImageDownloaderDelegate {
    @MainActor func dataDownloadDidStart(_ index: Int) {
        _ = self._activeSet.insert(index)
        triggerLayoutHash()
    }
    
    @MainActor func dataDownloadDidSucceed(_ index: Int, image: UIImage) {
        
        print("Image @ \(index) from DOWNLOAD")
        
        _activeSet.remove(index)
        _failedSet.remove(index)
        
        _didStartCheckCacheSet.remove(index)
        _didFinishCheckCacheSet.remove(index)
        
        _downloadingSet.remove(index)
        
        _imageDict[index] = image
        
        /*
        if let communityCellModel = model.getCommunityCellModel(at: index) {
            Task {
                await self.imageCache.cacheImage(image, communityCellModel.cacheKey)
            }
        }
        */
        
        triggerLayoutHash()
    }
    
    @MainActor func dataDownloadDidCancel(_ index: Int) {
        _activeSet.remove(index)
        _downloadingSet.remove(index)
        triggerLayoutHash()
    }
    
    @MainActor func dataDownloadDidFail(_ index: Int) {
        _activeSet.remove(index)
        _downloadingSet.remove(index)
        _ = _failedSet.insert(index)
        
        triggerLayoutHash()
    }
}
