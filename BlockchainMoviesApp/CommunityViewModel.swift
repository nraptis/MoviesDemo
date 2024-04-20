//
//  CommunityViewModel.swift
//  BlockchainMoviesApp
//
//  Created by "Nick" Django Raptis on 4/9/24.
//

import SwiftUI
import BlockChainNetworking
import BlockChainDatabase
import Combine

@Observable class CommunityViewModel {
    
    
    typealias NWMovie = BlockChainNetworking.NWMovie
    typealias DBMovie = BlockChainDatabase.DBMovie
    
    private static let probeAheadOrBehindRangeForDownloads = 8
    
    @ObservationIgnored @MainActor private var databaseController = BlockChainDatabase.DBDatabaseController()
    
    @MainActor @ObservationIgnored private let downloader = DirtyImageDownloader(numberOfSimultaneousDownloads: 2)
    
    @MainActor @ObservationIgnored fileprivate var _imageDict  = [String: UIImage]()
    
    @MainActor @ObservationIgnored fileprivate var _imageFailedSet = Set<Int>()
    
    @MainActor @ObservationIgnored fileprivate var _imageDidCheckCacheSet = Set<Int>()
    
    @MainActor @ObservationIgnored private var _addDownloadItems = [CommunityCellData]()
    @MainActor @ObservationIgnored private var _checkCacheDownloadItems = [CommunityCellData]()
    @MainActor @ObservationIgnored private var _checkCacheKeys = [KeyAndIndexPair]()
    
    @MainActor @ObservationIgnored var isUsingDatabaseData = false
    
    @ObservationIgnored var isAssigningTasksToDownloader = false
    @ObservationIgnored var isAssigningTasksToDownloaderEnqueued = false
    
    @ObservationIgnored var pageSize = 0
    
    @ObservationIgnored var numberOfItems = 0
    
    @ObservationIgnored var numberOfCells = 0
    @ObservationIgnored var numberOfPages = 0
    
    @ObservationIgnored var highestPageFetchedSoFar = 0
    
    @ObservationIgnored private var _priorityCommunityCellDatas = [CommunityCellData]()
    @ObservationIgnored private var _priorityList = [Int]()
    
    
    // This should only change when the screen is
    // booting up, or the device rotates. The # of cells
    // is managed by the GridLayout
    @MainActor @ObservationIgnored var gridCellModels = [GridCellModel]()
    
    @MainActor @ObservationIgnored let staticGridLayout = StaticGridLayout()
    @MainActor @ObservationIgnored private let imageCache = DirtyImageCache(name: "dirty_cache")
    @ObservationIgnored private(set) var isRefreshing = false
    
    // We use 2 "sources of truth" here.
    @MainActor var layoutWidth = CGFloat(255.0)
    @MainActor var layoutHeight = CGFloat(1024.0)
    
    private static let communityCellDataPlaceholder = CommunityCellData()
    
    @MainActor private(set) var isFetching = false
    @MainActor private(set) var isNetworkErrorPresent = false
    @MainActor var isAnyItemPresent = false
    
    @MainActor @ObservationIgnored let router: Router
    @MainActor init(router: Router) {
        
        self.router = router
        
        downloader.delegate = self
        downloader.isBlocked = true
        
        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil, queue: nil) { notification in
            Task { @MainActor in
                self._imageDict.removeAll(keepingCapacity: true)
                self._imageFailedSet.removeAll(keepingCapacity: true)
                self._imageDidCheckCacheSet.removeAll(keepingCapacity: true)
            }
        }

        Task { @MainActor in
            await self.heartbeat()
        }
        
        // In this case, it doesn't matter the order that the imageCache and dataBase load,
        // however, we want them to both load before the network call fires.
        Task { @MainActor in
            staticGridLayout.delegate = self
            layoutWidth = staticGridLayout.width // Race condition. SwiftUI is updating the layout...
            layoutHeight = staticGridLayout.height // Race condition. SwiftUI is updating the layout...
            handleNumberOfCellsMayHaveChanged() // Race condition. SwiftUI is updating the layout...
            
            await withTaskGroup(of: Void.self) { group in
                group.addTask { @DirtyImageCacheActor in
                    self.imageCache.load()
                }
                group.addTask { @MainActor in
                    await self.databaseController.loadPersistentStores()
                }
            }
            downloader.isBlocked = false
            await fetchPopularMovies(page: 1)
        }
    }
    
    //
    // This is more or less a tidying process.
    // Sometimes, with async and await, though no
    // data races occur, the state will not elegantly
    // transfer.
    //
    // As an example, in one async function, we are doing an
    // await before we set the cell to "downloading state"
    // ...
    // but on another async function, we have already set
    // the cell to the "success" state.
    // ...
    // Now the cell, which was just set to the "success" state
    // is very quickly overwritten with the downloading state.
    // So, it becomes stuck in this downloading state.
    //...
    // We can either check ALL of the conditions after each
    // and every possibly de-synchronizing await, or we can
    // just have this heartbeat process (oldschool) which
    // will identify anything out of sync and try to fix it.
    //
    // This rarely does anything, but it is a good insurance
    // policy against, not data races, but state races.
    //
    
    @MainActor func heartbeat() async {
        await pulse()
        
        Task { [weak self] in
            
            try? await Task.sleep(nanoseconds: 50_000_000)
            
            Task { @MainActor in
                if let self = self {
                    await self.heartbeat()
                }
            }
        }
    }
    
    @ObservationIgnored private var isOnPulse = false
    @MainActor func pulse() async {
        
        if isRefreshing {
            return
        }
        
        while isOnVisibleCellsMayHaveChanged {
            try? await Task.sleep(nanoseconds: 10_000)
        }
        
        isOnPulse = true
        
        for gridCellModel in gridCellModels {
            
            // Only concern ourselves with what we can see
            guard gridCellModel.isVisible else {
                continue
            }
            
            //
            // After about 20 ticks, the heartbeat process
            // will take over the management. This way, we
            // will not interfere with the main download
            // prioritization process.
            //
            if gridCellModel.isReadyForHeartbeatTick > 0 {
                gridCellModel.isReadyForHeartbeatTick -= 1
                if gridCellModel.isReadyForHeartbeatTick == 0 {
                    print("🔉 Cell @ \(gridCellModel) ready for heartbeat process.")
                }
                continue
            }
            
            let index = gridCellModel.layoutIndex
            
            // The data model may have gone missing.
            guard let communityCellData = getCommunityCellData(at: index) else {
                // Only update the view if we need to.
                // Verified that the same value will
                // cause the SwiftUI view to refresh.
                switch gridCellModel.state {
                case .missingModel:
                    break
                default:
                    gridCellModel.state = .missingModel
                    print("📚 Heartbeat process updated \(gridCellModel.layoutIndex) to MISSING MODEL H1")
                }
                continue
            }
            
            // The data model may have updated to
            // no longer have a key. (key is the img URL)
            guard let key = communityCellData.key else {
                // Only update the view if we need to.
                // Verified that the same value will
                // cause the SwiftUI view to refresh.
                switch gridCellModel.state {
                case .missingKey:
                    break
                default:
                    gridCellModel.state = .missingKey
                    print("📚 Heartbeat process updated \(gridCellModel.layoutIndex) to MISSING KEY H2")
                }
                continue
            }
            
            var gridCellModelImage: UIImage?
            switch gridCellModel.state {
            case .success(let image):
                gridCellModelImage = image
            default:
                break
            }
            
            if gridCellModelImage === nil {
                
                // The cell does not have an image
                
                if let image = _imageDict[key] {
                    
                    // Only update the view if we need to.
                    // In this instance, we are definitely
                    // not in "success" state, so we need
                    // to refresh the cell. No need for check.
                    gridCellModel.state = .success(image)
                    print("📚 Heartbeat process updated \(communityCellData.index) to an image [\(image.size.width) x \(image.size.width)] C2")
                    
                } else {
                    
                    // This is the common "trap" scenario. We have no image, neither does the cell...
                    // Let's see if we know the state...
                    
                    let keyAndIndexPair = KeyAndIndexPair(key: key, index: index)
                    if let image = await imageCache.singleRetrieve(keyAndIndexPair) {
                        _imageDict[key] = image
                        
                        // Only update the view if we need to.
                        // In this case, we finished an await,
                        // so it's possible out state transferred.
                        
                        switch gridCellModel.state {
                        case .success:
                            break
                        default:
                            gridCellModel.state = .success(image)
                            print("📚 Heartbeat process updated \(communityCellData.index) to an image [\(image.size.width) x \(image.size.width)] B2")
                        }
                    } else if await downloader.isDownloading(communityCellData) {
                        
                        // Possible data idiosyncrasies with image cache and
                        // the downloader here. It's not the end of the world
                        // if we download the image twice. This would be rare.
                        
                        // Only update the view if we need to.
                        // Verified that the same value will
                        // cause the SwiftUI view to refresh.
                        if await downloader.isDownloadingActively(communityCellData) {
                            switch gridCellModel.state {
                            case .downloadingActively:
                                break
                            default:
                                gridCellModel.state = .downloadingActively
                                print("📚 Heartbeat process updated \(communityCellData.index) to .downloadingActively")
                            }
                        } else {
                            
                            // Only update the view if we need to.
                            // Verified that the same value will
                            // cause the SwiftUI view to refresh.
                            switch gridCellModel.state {
                            case .downloading:
                                break
                            default:
                                gridCellModel.state = .downloading
                                print("📚 Heartbeat process updated \(communityCellData.index) to .downloading")
                            }
                        }
                    } else if _imageFailedSet.contains(index) {
                        
                        // Only update the view if we need to.
                        // Verified that the same value will
                        // cause the SwiftUI view to refresh.
                        switch gridCellModel.state {
                        case .error:
                            break
                        default:
                            gridCellModel.state = .error
                            print("📚 Heartbeat process updated \(communityCellData.index) to .error")
                        }
                    } else {
                        // The cell is in an illegal state right here...
                        // Let's try to download the thing...
                        
                        await downloader.addDownloadTask(communityCellData)
                        if await downloader.isDownloading(communityCellData) {
                            if await downloader.isDownloadingActively(communityCellData) {
                                // Only update the view if we need to.
                                // Verified that the same value will
                                // cause the SwiftUI view to refresh.
                                switch gridCellModel.state {
                                case .downloadingActively:
                                    break
                                default:
                                    gridCellModel.state = .downloadingActively
                                    print("📚 Heartbeat process updated \(communityCellData.index) to .downloadingActively")
                                }
                            } else {
                                // Only update the view if we need to.
                                // Verified that the same value will
                                // cause the SwiftUI view to refresh.
                                switch gridCellModel.state {
                                case .downloading:
                                    break
                                default:
                                    gridCellModel.state = .downloading
                                    print("📚 Heartbeat process updated \(communityCellData.index) to .downloadingActively")
                                }
                            }
                        } else {
                            
                            // We could also have instantly downloaded
                            // We just finished some "await," so the
                            // system may have changed.
                            // Therefore, we must check if the image
                            // exists a second time.
                            if let image = _imageDict[key] {
                                
                                // Only update the view if we need to.
                                // Verified that the same value will
                                // cause the SwiftUI view to refresh.
                                switch gridCellModel.state {
                                case .success:
                                    break
                                default:
                                    gridCellModel.state = .success(image)
                                    print("📚 Heartbeat process updated \(communityCellData.index) to an image [\(image.size.width) x \(image.size.width)] A2")
                                }
                            } else {
                                // In this case, the downloader is
                                // either blocked or malfunctioning.
                                // So we will go to the "illegal" state.
                                
                                // Something could be reconciled on
                                // the next pulse, in which case, we
                                // will get back in sync...
                                
                                // Only update the view if we need to.
                                // Verified that the same value will
                                // cause the SwiftUI view to refresh.
                                switch gridCellModel.state {
                                case .illegal:
                                    break
                                default:
                                    gridCellModel.state = .illegal
                                    print("📚 Heartbeat process updated \(communityCellData.index) to .illegal")
                                }
                            }
                        }
                    }
                }
                
            } else {
                
                // The cell already has an image...
                
                if let image = _imageDict[key] {
                    // Only update the view if we need to.
                    // Verified that the same value will
                    // cause the SwiftUI view to refresh.
                    switch gridCellModel.state {
                    case .success:
                        break
                    default:
                        gridCellModel.state = .success(image)
                        print("📚 Heartbeat process updated \(communityCellData.index) to an image [\(image.size.width) x \(image.size.width)] C1")
                    }
                } else {
                    
                    // This is a strange case. The cell has an image, but we do not have an image...
                    if _imageFailedSet.contains(index) {
                        
                        // Only update the view if we need to.
                        // Verified that the same value will
                        // cause the SwiftUI view to refresh.
                        switch gridCellModel.state {
                        case .error:
                            break
                        default:
                            gridCellModel.state = .error
                        }
                    } else if await downloader.isDownloading(communityCellData) {
                        // Perhaps we are downloading...
                        if await downloader.isDownloadingActively(communityCellData) {
                            
                            // Only update the view if we need to.
                            // Verified that the same value will
                            // cause the SwiftUI view to refresh.
                            switch gridCellModel.state {
                            case .downloadingActively:
                                break
                            default:
                                gridCellModel.state = .downloadingActively
                                print("📚 Heartbeat process updated \(communityCellData.index) to .downloadingActively")
                            }
                        } else {
                            
                            // Only update the view if we need to.
                            // Verified that the same value will
                            // cause the SwiftUI view to refresh.
                            switch gridCellModel.state {
                            case .downloading:
                                break
                            default:
                                gridCellModel.state = .downloading
                                print("📚 Heartbeat process updated \(communityCellData.index) to .downloading")
                            }
                        }
                    } else {
                        
                        // Maybe it's in the cache, but not
                        // the image dictionary, e.g. we flushed memory warning.
                        let keyAndIndexPair = KeyAndIndexPair(key: key, index: index)
                        if let image = await imageCache.singleRetrieve(keyAndIndexPair) {
                            _imageDict[key] = image
                            
                            // Only update the view if we need to.
                            // Verified that the same value will
                            // cause the SwiftUI view to refresh.
                            switch gridCellModel.state {
                            case .success:
                                break
                            default:
                                gridCellModel.state = .success(image)
                                print("📚 Heartbeat process updated \(communityCellData.index) to an image [\(image.size.width) x \(image.size.width)] B1")
                            }
                        } else {
                            
                            // Fishy state. Let's try to download the image...
                            
                            await downloader.addDownloadTask(communityCellData)
                            if await downloader.isDownloading(communityCellData) {
                                if await downloader.isDownloadingActively(communityCellData) {
                                    
                                    // Only update the view if we need to.
                                    // Verified that the same value will
                                    // cause the SwiftUI view to refresh.
                                    switch gridCellModel.state {
                                    case .downloadingActively:
                                        break
                                    default:
                                        print("📚 Heartbeat process updated \(communityCellData.index) to .downloadingActively")
                                        gridCellModel.state = .downloadingActively
                                    }
                                } else {
                                    
                                    // Only update the view if we need to.
                                    // Verified that the same value will
                                    // cause the SwiftUI view to refresh.
                                    switch gridCellModel.state {
                                    case .downloading:
                                        break
                                    default:
                                        print("📚 Heartbeat process updated \(communityCellData.index) to .downloading")
                                        gridCellModel.state = .downloading
                                    }
                                }
                            } else {
                                
                                // We could also have instantly downloaded
                                // the image, so let's check again.
                                if let image = _imageDict[key] {
                                    
                                    // Only update the view if we need to.
                                    // Verified that the same value will
                                    // cause the SwiftUI view to refresh.
                                    switch gridCellModel.state {
                                    case .success:
                                        break
                                    default:
                                        print("📚 Heartbeat process updated \(communityCellData.index) to an image [\(image.size.width) x \(image.size.width)] A1")
                                        gridCellModel.state = .success(image)
                                    }
                                } else {
                                    // In this case, the downloader is
                                    // either blocked or malfunctioning.
                                    // So we will go to the "illegal" state.
                                    
                                    // Something could be reconciled on
                                    // the next pulse, in which case, we
                                    // will get back in sync...
                                    
                                    // Only update the view if we need to.
                                    // Verified that the same value will
                                    // cause the SwiftUI view to refresh.
                                    switch gridCellModel.state {
                                    case .illegal:
                                        break
                                    default:
                                        gridCellModel.state = .illegal
                                        print("📚 Heartbeat process updated \(communityCellData.index) to .illegal")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        await assignTasksToDownloader()
        await downloader.startTasksIfNecessary()
        isOnPulse = false
    }
    
    @MainActor func refresh() async {
        
        if isRefreshing {
            print("🧚🏽 We are already refreshing... No double refreshing...!!!")
            return
        }
        
        isRefreshing = true
        
        recentFetches.removeAll(keepingCapacity: true)
        
        downloader.isBlocked = true
        await downloader.cancelAll()
        
        var fudge = 0
        while isOnPulse {
            if fudge == 0 {
                print("🙅🏽‍♀️ Refreshing During Pulse... Waiting For End!!!")
            }
            
            try? await Task.sleep(nanoseconds: 1_000_000)
            
            fudge += 1
            if fudge >= 2048 {
                print("🧛🏻‍♂️ Terminating refresh, we are pulse-locked.")
                downloader.isBlocked = false
                isRefreshing = false
                return
            }
        }
        
        // Cancel the downloader again, incase the PULSE process added a new download.
        await downloader.cancelAll()
        
        
        fudge = 0
        while isOnVisibleCellsMayHaveChanged {
            if fudge == 0 {
                print("🙅🏽‍♀️ Refreshing During Visible Cell Freshen... Waiting For End!!!")
            }
            
            try? await Task.sleep(nanoseconds: 1_000_000)
            
            fudge += 1
            if fudge >= 2048 {
                print("🧛🏻‍♂️ Terminating refresh, we are visible cells-locked.")
                downloader.isBlocked = false
                isRefreshing = false
                return
            }
        }
        
        fudge = 0
        while isFetching {
            if fudge == 0 {
                print("🙅🏽‍♀️ Refreshing During Fetch... Waiting For End!!!")
            }
            
            try? await Task.sleep(nanoseconds: 1_000_000)
            
            fudge += 1
            if fudge >= 2048 {
                print("🧛🏻‍♂️ Terminating refresh, we are fetch-locked.")
                downloader.isBlocked = false
                isRefreshing = false
                return
            }
        }
        
        // For the sake of UX, let's throw everything into the
        // "missing model" state and sleep for 1s.
        
        for gridCellModel in gridCellModels {
            gridCellModel.state = .missingModel
        }
        
        // This is mainly just for user feedback; the refresh feels
        // more natural if it takes a couple seconds...
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let nwMovies = await _fetchPopularMoviesWithNetwork(page: 1)
        
        // This is mainly just for user feedback; the refresh feels
        // more natural if it takes a couple seconds...
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        if nwMovies.count <= 0 {
            print("🧟‍♀️ Bad Refresh! We got no items from the network...")
            
            let dbMovies = await _fetchPopularMoviesWithDatabase()
            if dbMovies.count <= 0 {
                print("🧟‍♀️ Bad Refresh! We got no items from the database...")
                
                downloader.isBlocked = false
                isRefreshing = false
                isAnyItemPresent = false
            } else {
                
                pageSize = -1
                numberOfItems = dbMovies.count
                numberOfCells = dbMovies.count
                numberOfPages = -1
                highestPageFetchedSoFar = -1
                isUsingDatabaseData = true
                _clearForRefresh()
                _synchronize(dbMovies: dbMovies)
                downloader.isBlocked = false
                isRefreshing = false
                staticGridLayout.registerNumberOfCells(numberOfCells)
                handleVisibleCellsMayHaveChanged()
            }
        } else {
            isUsingDatabaseData = false
            _clearForRefresh()
            _synchronize(nwMovies: nwMovies, page: 0)
            downloader.isBlocked = false
            isRefreshing = false
            staticGridLayout.registerNumberOfCells(numberOfCells)
            handleVisibleCellsMayHaveChanged()
        }
    }
    
    @MainActor func _clearForRefresh() {
        
        // Empty out all the internal storage crap...!!!
        _imageDict.removeAll()
        _imageFailedSet.removeAll()
        _imageDidCheckCacheSet.removeAll()
        
        staticGridLayout.clear()
        
        for communityCellData in communityCellDatas {
            if let communityCellData = communityCellData {
                _depositCommunityCellData(communityCellData)
            }
        }
        communityCellDatas.removeAll()
    }
    
    @MainActor func fetchPopularMovies(page: Int) async {
        
        if isFetching { return }
        
        if isRefreshing { return }
        
        print("🎁 Fetching popular movies [page \(page)]")
        
        isFetching = true
        
        let nwMovies = await _fetchPopularMoviesWithNetwork(page: page)
        
        // We either fetched nothing, or got an error.
        if nwMovies.count <= 0 {
            if communityCellDatas.count > 0 {
                // We will just keep what we have...
            } else {
                
                // We will fetch from the database!!!
                let dbMovies = await _fetchPopularMoviesWithDatabase()
                if dbMovies.count <= 0 {
                    
                    print("🪣 Tried to use database, there are no items.")
                    
                    isUsingDatabaseData = false
                    isAnyItemPresent = false
                
                } else {
                    
                    print("📀 Fetched \(dbMovies.count) items from database! Using offline mode!")
                    
                    pageSize = -1
                    numberOfItems = dbMovies.count
                    numberOfCells = dbMovies.count
                    numberOfPages = -1
                    highestPageFetchedSoFar = -1
                    
                    isUsingDatabaseData = true
                    _synchronize(dbMovies: dbMovies)
                    isAnyItemPresent = true
                }
            }

        } else {
            isUsingDatabaseData = false
            _synchronize(nwMovies: nwMovies, page: page)
            isAnyItemPresent = true
        }
        
        isFetching = false
        staticGridLayout.registerNumberOfCells(numberOfCells)
        
        handleVisibleCellsMayHaveChanged()
    }
    
    @MainActor private func _synchronize(nwMovies: [NWMovie], page: Int) {
        
        if pageSize <= 0 {
            print("🧌 pageSize = \(pageSize), this seems wrong.")
            return
        }
        if page <= 0 {
            print("🧌 page = \(page), this seems wrong. We expect the pages to start at 1, and number up.")
            return
        }
        
        // The first index of the cells, in the master list.
        let startCellIndex = (page - 1) * pageSize
        var cellModelIndex = startCellIndex
        
        var newCommunityCellDatas = [CommunityCellData]()
        newCommunityCellDatas.reserveCapacity(nwMovies.count)
        for nwMovie in nwMovies {
            let cellModel = _withdrawCommunityCellData(index: cellModelIndex, nwMovie: nwMovie)
            newCommunityCellDatas.append(cellModel)
            cellModelIndex += 1
        }
        
        _overwriteCells(newCommunityCellDatas, at: startCellIndex)
    }
    
    @MainActor private func _synchronize(dbMovies: [DBMovie]) {
        
        // The first index of the cells, here it's always 0.
        let startCellIndex = 0
        var cellModelIndex = startCellIndex
        
        var newCommunityCellDatas = [CommunityCellData]()
        newCommunityCellDatas.reserveCapacity(dbMovies.count)
        for dbMovie in dbMovies {
            let cellModel = _withdrawCommunityCellData(index: cellModelIndex, dbMovie: dbMovie)
            newCommunityCellDatas.append(cellModel)
            cellModelIndex += 1
        }
        
        _magnetizeCells()
        
        _overwriteCells(newCommunityCellDatas, at: startCellIndex)
    }
    
    // Put all the cells which were in the communityCellDatas
    // list into the queue, blank them all out to nil.
    @MainActor private func _magnetizeCells() {
        var cellModelIndex = 0
        while cellModelIndex < communityCellDatas.count {
            if let communityCellData = communityCellDatas[cellModelIndex] {
                _depositCommunityCellData(communityCellData)
                communityCellDatas[cellModelIndex] = nil
            }
            cellModelIndex += 1
        }
    }
    
    @MainActor private func _overwriteCells(_ newCommunityCellDatas: [CommunityCellData], at index: Int) {
        
        if index < 0 {
            print("🧌 index = \(index), this seems wrong.")
            return
        }
        
        let ceiling = index + newCommunityCellDatas.count
        
        // Fill in with blank up to the ceiling
        while communityCellDatas.count < ceiling {
            communityCellDatas.append(nil)
        }
        
        // What we do here is flush out anything in the range
        // we are "writing" to... In case we have overlap, etc.
        var itemIndex = 0
        var cellModelIndex = index
        while itemIndex < newCommunityCellDatas.count {
            if let communityCellData = communityCellDatas[cellModelIndex] {
                _depositCommunityCellData(communityCellData)
                communityCellDatas[cellModelIndex] = nil
            }
            
            itemIndex += 1
            cellModelIndex += 1
        }

        //
        // What we do here is place new cell models in this range,
        // which will now be 100% clean and ready for that fresh
        // fresh sweet baby Jesus sweeting falling down fast.
        //
        itemIndex = 0
        cellModelIndex = index
        while itemIndex < newCommunityCellDatas.count {
            let communityCellData = newCommunityCellDatas[itemIndex]
            communityCellDatas[cellModelIndex] = communityCellData
            itemIndex += 1
            cellModelIndex += 1
        }
    }
    
    
    struct RecentNetworkFetch {
        let date: Date
        let page: Int
    }
    
    @ObservationIgnored @MainActor private var recentFetches = [RecentNetworkFetch]()
    @MainActor private func _fetchPopularMoviesWithNetwork(page: Int) async -> [NWMovie] {
        
        //
        // Let's keep peace with the network. If for some reason, we are
        // stuck in a fetch loop, we will throttle it to every 120 seconds.
        //
        if recentFetches.count >= 3 {
            let lastFetch = recentFetches[recentFetches.count - 1]
            if lastFetch.page == page {
                let timeElapsed = Date().timeIntervalSince(lastFetch.date)
                if timeElapsed <= 120 {
                    print("💭 Stalling fetch. Only \(timeElapsed) seconds went by since last fetch of page \(page)")
                    isNetworkErrorPresent = true
                    return []
                }
            }
        }
        
        recentFetches.append(RecentNetworkFetch(date: Date(), page: page))
        if recentFetches.count > 3 {
            _ = recentFetches.removeFirst()
        }
        
        var _isNetworkErrorPresent = false
        
        var result = [NWMovie]()
        do {
            let response = try await BlockChainNetworking.NWNetworkController.fetchPopularMovies(page: page)
            result.append(contentsOf: response.results)
            do {
                try await databaseController.sync(nwMovies: response.results)
                print("💾 We did sync Movies to database.")
            } catch {
                print("🧌 Could not sync Movies to database.")
                print("\(error.localizedDescription)")
            }
            
            numberOfItems = response.total_results
            numberOfPages = response.total_pages
            
            if response.results.count > pageSize { pageSize = response.results.count }
            
            if page > highestPageFetchedSoFar { highestPageFetchedSoFar = page }
            
            var _numberOfCells = (highestPageFetchedSoFar) * pageSize
            if _numberOfCells > numberOfItems { _numberOfCells = numberOfItems }
            
            numberOfCells = _numberOfCells
            
        } catch let error {
            print("🧌 Unable to fetch popular movies (Network): \(error.localizedDescription)")
            _isNetworkErrorPresent = true
        }
        
        let __isNetworkErrorPresent = _isNetworkErrorPresent
        await MainActor.run {
            isNetworkErrorPresent = __isNetworkErrorPresent
        }
        
        return result
    }
    
    private func _fetchPopularMoviesWithDatabase() async -> [DBMovie] {
        var result = [DBMovie]()
        do {
            let dbMovies = try await databaseController.fetchMovies()
            result.append(contentsOf: dbMovies)
            
        } catch let error {
            print("🧌 Unable to fetch (Database): \(error.localizedDescription)")
        }
        return result
    }
    
    /*
    @MainActor private func updateCell(at index: Int) async {
        
        return
        
        guard let gridCellModel = getGridCellModel(at: index) else {
            return
        }
        
        guard let communityCellData = getCommunityCellData(at: index) else {
            
            // Only update the view if we need to.
            // Verified that the same value will
            // cause the SwiftUI view to refresh.
            switch gridCellModel.state {
            case .missingModel:
                break
            default:
                gridCellModel.state = .missingModel
            }
            return
        }
        
        if let gridCellModel = getGridCellModel(at: index) {
            
            if let image = getCellImage(at: index) {
                
                // Only update the view if we need to.
                // Verified that the same value will
                // cause the SwiftUI view to refresh.
                switch gridCellModel.state {
                case .success:
                    break
                default:
                    gridCellModel.state = .success(image)
                }
            } else if _imageFailedSet.contains(index) {
                
                // Only update the view if we need to.
                // Verified that the same value will
                // cause the SwiftUI view to refresh.
                switch gridCellModel.state {
                case .error:
                    break
                default:
                    gridCellModel.state = .error
                }
            } else if await downloader.isDownloading(communityCellData) {
                if await downloader.isDownloadingActively(communityCellData) {
                    
                    // Only update the view if we need to.
                    // Verified that the same value will
                    // cause the SwiftUI view to refresh.
                    switch gridCellModel.state {
                    case .downloadingActively:
                        break
                    default:
                        gridCellModel.state = .downloadingActively
                    }
                } else {
                    
                    // Only update the view if we need to.
                    // Verified that the same value will
                    // cause the SwiftUI view to refresh.
                    switch gridCellModel.state {
                    case .downloading:
                        break
                    default:
                        gridCellModel.state = .downloading
                    }
                }
            } else if communityCellData.key == nil {
                
                // Only update the view if we need to.
                // Verified that the same value will
                // cause the SwiftUI view to refresh.
                switch gridCellModel.state {
                case .missingKey:
                    break
                default:
                    gridCellModel.state = .missingKey
                }
            }
        }
    }
    */
    
    @MainActor func getCellImage(at index: Int) -> UIImage? {
        if let communityCellData = getCommunityCellData(at: index) {
            if let key = communityCellData.key {
                if let result = _imageDict[key] {
                    return result
                }
            }
        }
        return nil
    }
    
    @MainActor func didCellImageDownloadFail(at index: Int) -> Bool {
        _imageFailedSet.contains(index)
    }
    
    @MainActor func isCellImageDownloading(at index: Int) async -> Bool {
        
        guard let communityCellData = getCommunityCellData(at: index) else {
            return false
        }
        
        return await downloader.isDownloading(communityCellData)
    }
    
    @MainActor func isCellImageDownloadingActively(at index: Int) async -> Bool {
        guard let communityCellData = getCommunityCellData(at: index) else {
            return false
        }
        
        return await downloader.isDownloadingActively(communityCellData)
    }
    
    func registerScrollContent(_ scrollContentGeometry: GeometryProxy) {
        
    }
    
    @ObservationIgnored @MainActor var gridCellModelQueue = [GridCellModel]()
    @MainActor private func _withdrawGridCellModel() -> GridCellModel {
        if gridCellModelQueue.count > 0 {
            let result = gridCellModelQueue.removeLast()
            return result
        } else {
            let result = GridCellModel()
            return result
        }
    }
    
    @MainActor private func _depositGridCellModel(_ cellModel: GridCellModel) {
        cellModel.communityCellData = nil
        cellModel.layoutIndex = -1
        cellModel.isVisible = false
        cellModel.isReadyForHeartbeatTick = 20
        gridCellModelQueue.append(cellModel)
    }
    
    @ObservationIgnored @MainActor var communityCellDatas = [CommunityCellData?]()
    @ObservationIgnored @MainActor var communityCellDataQueue = [CommunityCellData]()
    
    @MainActor func _withdrawCommunityCellData(index: Int, nwMovie: BlockChainNetworking.NWMovie) -> CommunityCellData {
        if communityCellDataQueue.count > 0 {
            let result = communityCellDataQueue.removeLast()
            result.inject(index: index, nwMovie: nwMovie)
            return result
        } else {
            let result = CommunityCellData(index: index, nwMovie: nwMovie)
            return result
        }
    }
    
    @MainActor private func _withdrawCommunityCellData(index: Int, dbMovie: BlockChainDatabase.DBMovie) -> CommunityCellData {
        if communityCellDataQueue.count > 0 {
            let result = communityCellDataQueue.removeLast()
            result.inject(index: index, dbMovie: dbMovie)
            return result
        } else {
            let result = CommunityCellData(index: index, dbMovie: dbMovie)
            return result
        }
    }
    
    @MainActor private func _depositCommunityCellData(_ cellModel: CommunityCellData) {
        communityCellDataQueue.append(cellModel)
    }
    
    @MainActor func getCommunityCellData(at index: Int) -> CommunityCellData? {
        if index >= 0 && index < communityCellDatas.count {
            return communityCellDatas[index]
        }
        return nil
    }
    
    @MainActor func getGridCellModel(communityCellData: CommunityCellData) -> GridCellModel? {
        var gridCellModelIndex = 0
        while gridCellModelIndex < gridCellModels.count {
            let gridCellModel = gridCellModels[gridCellModelIndex]
            if gridCellModel.communityCellData === communityCellData {
                return gridCellModel
            }
            gridCellModelIndex += 1
        }
        return nil
    }
    
    @MainActor func getGridCellModel(at index: Int) -> GridCellModel? {
        var gridCellModelIndex = 0
        while gridCellModelIndex < gridCellModels.count {
            let gridCellModel = gridCellModels[gridCellModelIndex]
            if gridCellModel.layoutIndex == index {
                return gridCellModel
            }
            gridCellModelIndex += 1
        }
        return nil
    }
    
    // This is on the MainActor because the UI uses "AllVisibleCellModels"
    @MainActor func fetchMorePagesIfNecessary() {
        
        if isFetching { return }
        if isRefreshing { return }
        if isUsingDatabaseData { return }
        
        // They have to pull-to-refresh when the network comes back on...
        if isNetworkErrorPresent { return }
        
        //
        // This needs a valid page size...
        // It sucks they chose "page" instead of (index, limit)
        //
        if pageSize < 1 { return }
        
        let firstCellIndexOnScreen = staticGridLayout.getFirstCellIndexOnScreen()
        let lastCellIndexOnScreen = staticGridLayout.getLastCellIndexOnScreen()
        
        if firstCellIndexOnScreen >= lastCellIndexOnScreen { return }
        
        let numberOfCols = staticGridLayout.getNumberOfCols()
        
        var _lowest = firstCellIndexOnScreen
        var _highest = lastCellIndexOnScreen
        
        _lowest -= numberOfCols
        _highest += (numberOfCols * 2)
        
        if _lowest < 0 {
            _lowest = 0
        }
        
        // These don't change after these lines. Indicated as such with grace.
        let lowest = _lowest
        let highest = _highest
        
        var checkIndex = lowest
        while checkIndex < highest {
            if getCommunityCellData(at: checkIndex) === nil {
                
                let pageIndexToFetch = (checkIndex / pageSize)
                let pageToFetch = pageIndexToFetch + 1
                
                if pageToFetch < numberOfPages {
                    Task {
                        await fetchPopularMovies(page: pageToFetch)
                    }
                    return
                }
            }
            checkIndex += 1
        }
    }
    
    private var _isFetchingDetails = false
    @MainActor func handleCellClicked(at index: Int) async {
        
        if _isFetchingDetails {
            print("🪚 [STOPPED] Attempted to queue up fetch details twice.")
            return
        }
        
        _isFetchingDetails = true
        
        if let communityCellData = getCommunityCellData(at: index) {
            do {
                let id = communityCellData.id
                let nwMovieDetails = try await BlockChainNetworking.NWNetworkController.fetchMovieDetails(id: id)
                print("🎥 Movie fetched! For \(communityCellData.title) [\(communityCellData.id)]")
                print(nwMovieDetails)
                router.pushMovieDetails(nwMovieDetails: nwMovieDetails)
            } catch {
                print("🧌 Unable to fetch movie details (Network): \(error.localizedDescription)")
                router.rootViewModel.showError("Oops!", "Looks like we couldn't fetch the data! Check your connection!")
            }
            _isFetchingDetails = false
        }
    }
    
    @MainActor func handleCellForceRetryDownload(at index: Int) async {
        if let communityCellData = getCommunityCellData(at: index) {
            print("🚦 Force download restart @ \(index)")
            _imageFailedSet.remove(index)
            await downloader.forceRestart(communityCellData)
        }
    }
    
    @MainActor func handleNumberOfCellsMayHaveChanged() {
        
        let maximumNumberOfVisibleCells = staticGridLayout.getMaximumNumberOfVisibleCells()
        if gridCellModels.count < maximumNumberOfVisibleCells {
            
            let numberToAdd = (maximumNumberOfVisibleCells - gridCellModels.count)
            
            print("🎡 Visible Cell Count Changed, We Need To Add \(numberToAdd) Cells.")
            
            var index = 0
            while index < numberToAdd {
                let gridCellModel = _withdrawGridCellModel()
                gridCellModel.id = gridCellModels.count
                gridCellModels.append(gridCellModel)
                index += 1
            }
        }
        
        if gridCellModels.count > maximumNumberOfVisibleCells {
            let numberToRemove = gridCellModels.count - maximumNumberOfVisibleCells
            
            print("🎢 Visible Cell Count Changed, We Need To Remove \(numberToRemove) Cells.")
            
            var index = gridCellModels.count - numberToRemove
            while index < gridCellModels.count {
                let gridCellModel = gridCellModels[index]
                _depositGridCellModel(gridCellModel)
                index += 1
            }
            gridCellModels.removeLast(numberToRemove)
        }
        
        handleVisibleCellsMayHaveChanged()
    }
    
    @ObservationIgnored private var _gridCellModelsTemp = [GridCellModel]()
    @ObservationIgnored private var _newGridCellModelsTemp = [GridCellModel]()
    @ObservationIgnored private var _layoutGridCellIndicesTemp = [Int]()
    
    @ObservationIgnored private var isOnVisibleCellsMayHaveChanged = false
    
    
    @MainActor private func _injectWithData(gridCellModel: GridCellModel, 
                                            communityCellData: CommunityCellData,
                                            index: Int) {
        
        // Only update the view if we need to.
        // Verified that the same value will
        // cause the SwiftUI view to refresh.
        if gridCellModel.communityCellData !== communityCellData {
            gridCellModel.communityCellData = communityCellData
        }
        
        if let key = communityCellData.key {
            
            if let image = _imageDict[key] {
                
                // Only update the view if we need to.
                // Verified that the same value will
                // cause the SwiftUI view to refresh.
                switch gridCellModel.state {
                case .success:
                    break
                default:
                    gridCellModel.state = .success(image)
                    print("📚 🚧 Injection Process Updated \(communityCellData.index) to an image [\(image.size.width) x \(image.size.width)] WJ")
                    
                }
                
            } else {
                
                if _imageFailedSet.contains(index) {
                    // Only update the view if we need to.
                    // Verified that the same value will
                    // cause the SwiftUI view to refresh.
                    switch gridCellModel.state {
                    case .error:
                        break
                    default:
                        gridCellModel.state = .error
                        print("📚 🚧 Injection Process Updated \(communityCellData.index) to .error WK")
                    }
                }
            }
        } else {
            
            // Only update the view if we need to.
            // Verified that the same value will
            // cause the SwiftUI view to refresh.
            switch gridCellModel.state {
            case .missingKey:
                break
            default:
                gridCellModel.state = .missingKey
                print("📚 🚧 Injection Process Updated \(communityCellData.index) to .missingKey JM")
            }
        }
    }
    
    /*
    @MainActor private func _injectWithData(gridCellModel: GridCellModel, communityCellData: CommunityCellData, index: Int) async {
        
        // Only update the view if we need to.
        // Verified that the same value will
        // cause the SwiftUI view to refresh.
        if gridCellModel.communityCellData !== communityCellData {
            gridCellModel.communityCellData = communityCellData
        }
        
        // Only update the view if we need to.
        // Verified that the same value will
        // cause the SwiftUI view to refresh.
        if gridCellModel.isVisible == false {
            gridCellModel.isVisible = true
        }
        
        
        
        if let key = communityCellData.key {
            
            if let image = _imageDict[key] {
                
                // Only update the view if we need to.
                // Verified that the same value will
                // cause the SwiftUI view to refresh.
                switch gridCellModel.state {
                case .success:
                    break
                default:
                    gridCellModel.state = .success(image)
                    print("📚 🚧 Injection Process Updated \(communityCellData.index) to an image [\(image.size.width) x \(image.size.width)] WJ")
                    
                }
                
            } else {
                
                if _imageFailedSet.contains(index) {
                    // Only update the view if we need to.
                    // Verified that the same value will
                    // cause the SwiftUI view to refresh.
                    switch gridCellModel.state {
                    case .error:
                        break
                    default:
                        gridCellModel.state = .error
                        print("📚 🚧 Injection Process Updated \(communityCellData.index) to .error WK")
                    }
                } else {
                    // We have an illegal state, let the heartbeat process fix it.
                    
                    if await downloader.isDownloading(communityCellData) {
                        if await downloader.isDownloadingActively(communityCellData) {
                            // Only update the view if we need to.
                            // Verified that the same value will
                            // cause the SwiftUI view to refresh.
                            switch gridCellModel.state {
                            case .downloadingActively:
                                break
                            default:
                                gridCellModel.state = .downloadingActively
                                print("📚 🚧 Injection Process Updated \(communityCellData.index) to .downloadingActively WL")
                            }
                        } else {
                            // Only update the view if we need to.
                            // Verified that the same value will
                            // cause the SwiftUI view to refresh.
                            switch gridCellModel.state {
                            case .downloading:
                                break
                            default:
                                gridCellModel.state = .downloading
                                print("📚 🚧 Injection Process Updated \(communityCellData.index) to .downloading WM")
                            }
                        }
                    } else {
                        if let key = communityCellData.key {
                            
                            let keyAndIndexPair = KeyAndIndexPair(key: key, index: index)
                            if let image = await imageCache.singleRetrieve(keyAndIndexPair) {
                                _imageDict[key] = image
                                // Only update the view if we need to.
                                // Verified that the same value will
                                // cause the SwiftUI view to refresh.
                                switch gridCellModel.state {
                                case .success:
                                    break
                                default:
                                    gridCellModel.state = .success(image)
                                    print("📚 🚧 Injection Process Updated \(communityCellData.index) to an image [\(image.size.width) x \(image.size.width)] WNN")
                                }
                            } else {
                                
                                // Only update the view if we need to.
                                // Verified that the same value will
                                // cause the SwiftUI view to refresh.
                                switch gridCellModel.state {
                                case .illegal:
                                    break
                                default:
                                    gridCellModel.state = .illegal
                                    print("📚 🚧 Injection Process Updated \(communityCellData.index) to .illegal JL")
                                }
                            }
                        } else {
                            // Only update the view if we need to.
                            // Verified that the same value will
                            // cause the SwiftUI view to refresh.
                            switch gridCellModel.state {
                            case .downloading:
                                break
                            default:
                                gridCellModel.state = .missingKey
                                print("📚 🚧 Injection Process Updated \(communityCellData.index) to .missingKey WO")
                            }
                        }
                    }
                }
            }
        } else {
            
            // Only update the view if we need to.
            // Verified that the same value will
            // cause the SwiftUI view to refresh.
            switch gridCellModel.state {
            case .missingKey:
                break
            default:
                gridCellModel.state = .missingKey
                print("📚 🚧 Injection Process Updated \(communityCellData.index) to .missingKey JM")
            }
            
        }
    }
    */
    
    @MainActor private func _injectWithDataWhileRefreshing(gridCellModel: GridCellModel,
                                                           communityCellData: CommunityCellData,
                                                           index: Int) {
        
        // Only update the view if we need to.
        // Verified that the same value will
        // cause the SwiftUI view to refresh.
        if gridCellModel.communityCellData !== communityCellData {
            gridCellModel.communityCellData = communityCellData
        }
    }
    
    func _injectWithoutData(gridCellModel: GridCellModel, index: Int) {
        // Only update the view if we need to.
        // Verified that the same value will
        // cause the SwiftUI view to refresh.
        switch gridCellModel.state {
        case .missingModel:
            break
        default:
            gridCellModel.state = .missingModel
            print("📚 🚧 Injection Process II Updated \(index) to an MISSING MODEL KK")
        }
        
        // Only update the view if we need to.
        // Verified that the same value will
        // cause the SwiftUI view to refresh.
        if gridCellModel.communityCellData !== nil {
            gridCellModel.communityCellData = nil
        }
    }
    
    @MainActor func handleVisibleCellsMayHaveChanged() {
        
        isOnVisibleCellsMayHaveChanged = true
        
        if staticGridLayout.isAnyItemPresent {
            isAnyItemPresent = true
        }
        
        let firstCellIndexOnScreen = staticGridLayout.getFirstCellIndexOnScreen()
        let lastCellIndexOnScreen = staticGridLayout.getLastCellIndexOnScreen()
        
        let numberOfCellsRequired = (lastCellIndexOnScreen - firstCellIndexOnScreen) + 1
        let numberOfCellsHad = gridCellModels.count
        
        if numberOfCellsHad < numberOfCellsRequired {
            print("‼️ [Layout] Cells Needed = \(numberOfCellsRequired) / \(numberOfCellsHad) Cells Available. This is a kludge. Should not occur.")
            print("‼️ This is an error with the calculation. Maybe the device is rotating weird?")
            let numberToAdd = (numberOfCellsRequired - numberOfCellsHad)
            var index = 0
            while index < numberToAdd {
                let gridCellModel = _withdrawGridCellModel()
                gridCellModel.id = gridCellModels.count
                gridCellModels.append(gridCellModel)
                index += 1
            }
        }
        
        // List of cells we can write to.
        _gridCellModelsTemp.removeAll(keepingCapacity: true)
        for gridCellModel in gridCellModels {
            
            let index = gridCellModel.layoutIndex
            let doesExistInLayout = (index >= firstCellIndexOnScreen && index <= lastCellIndexOnScreen)
            if doesExistInLayout {
                
                // We should let heartbeat process handle existing cells.
                
                if gridCellModel.isVisible != true {
                    gridCellModel.isVisible = true
                }
                
            } else {
                // We can overwrite this cell.
                _gridCellModelsTemp.append(gridCellModel)
                gridCellModel.isVisible = false
                gridCellModel.layoutIndex = -1
                gridCellModel.communityCellData = nil
                gridCellModel.state = .illegal
            }
        }
        
        // These will be the ones we need to freshly add...
        _layoutGridCellIndicesTemp.removeAll(keepingCapacity: true)
        
        var checkLayoutIndex = firstCellIndexOnScreen
        while checkLayoutIndex <= lastCellIndexOnScreen {
            var doesExistOnScreen = false
            for gridCellModel in gridCellModels {
                if gridCellModel.layoutIndex == checkLayoutIndex {
                    doesExistOnScreen = true
                }
            }
            
            if doesExistOnScreen {
                // We don't need to do anything with this one,
                // it's already handled properly.
            } else {
                _layoutGridCellIndicesTemp.append(checkLayoutIndex)
            }
            checkLayoutIndex += 1
        }
        
        
        _newGridCellModelsTemp.removeAll(keepingCapacity: true)
        var visibleCellIndex = 0
        while (visibleCellIndex < _layoutGridCellIndicesTemp.count) && (visibleCellIndex < _gridCellModelsTemp.count) {
            
            let layoutIndex = _layoutGridCellIndicesTemp[visibleCellIndex]
            let gridCellModel = _gridCellModelsTemp[visibleCellIndex]
            
            // Only update the view if we need to.
            // Verified that the same value will
            // cause the SwiftUI view to refresh.
            if gridCellModel.layoutIndex != layoutIndex {
                gridCellModel.layoutIndex = layoutIndex
            }
            
            if gridCellModel.isVisible != true {
                gridCellModel.isVisible = true
            }
            
            _newGridCellModelsTemp.append(gridCellModel)
            
            visibleCellIndex += 1
        }
        
        while visibleCellIndex < _layoutGridCellIndicesTemp.count {
            print("🚧 [Layout] OVERFLOW: @ \(visibleCellIndex), cell = \(_layoutGridCellIndicesTemp[visibleCellIndex]), how is that?")
            visibleCellIndex += 1
        }
        
        let cellWidth = staticGridLayout.getCellWidth()
        let cellHeight = staticGridLayout.getCellHeight()
        
        // We will always update the x, y, width, height
        for gridCellModel in gridCellModels {
            if gridCellModel.isVisible {
                
                let index = gridCellModel.layoutIndex
                
                let x = staticGridLayout.getCellX(cellIndex: gridCellModel.layoutIndex)
                let y = staticGridLayout.getCellY(cellIndex: gridCellModel.layoutIndex)
                
                if x != gridCellModel.x {
                    // Only update the view if we need to.
                    // Verified that the same value will
                    // cause the SwiftUI view to refresh.
                    gridCellModel.x = x
                }
                if y != gridCellModel.y {
                    // Only update the view if we need to.
                    // Verified that the same value will
                    // cause the SwiftUI view to refresh.
                    gridCellModel.y = y
                }
                if cellWidth != gridCellModel.width {
                    // Only update the view if we need to.
                    // Verified that the same value will
                    // cause the SwiftUI view to refresh.
                    gridCellModel.width = cellWidth
                }
                if cellHeight != gridCellModel.height {
                    // Only update the view if we need to.
                    // Verified that the same value will
                    // cause the SwiftUI view to refresh.
                    gridCellModel.height = cellHeight
                }
            }
        }

        for gridCellModel in _newGridCellModelsTemp {
            let index = gridCellModel.layoutIndex
            if let communityCellData = getCommunityCellData(at: index) {
                if !isRefreshing {
                    _injectWithData(gridCellModel: gridCellModel,
                                    communityCellData: communityCellData,
                                    index: index)
                } else {
                    _injectWithDataWhileRefreshing(gridCellModel: gridCellModel,
                                                   communityCellData: communityCellData,
                                                   index: index)
                }
            } else {
                _injectWithoutData(gridCellModel: gridCellModel, index: index)
            }
        }
        
        isOnVisibleCellsMayHaveChanged = false
        
        Task {
            //await handleVisibleCellsMayHaveChanged_PostProcess(newGridCellModels: _newGridCellModelsTemp)
            await assignTasksToDownloader()
            fetchMorePagesIfNecessary()
        }
        
    }
    
    @MainActor func handleVisibleCellsMayHaveChanged_PostProcess(newGridCellModels: [GridCellModel]) async {
        
        
        
    }
    
    // Distance from the left of the container / screen.
    // Distance from the top of the container / screen.
    private func priority(distX: Int, distY: Int) -> Int {
        let px = (-distX)
        let py = (8192 * 8192) - (8192 * distY)
        return (px + py)
    }
    
    // If you bunch up calls to this, they will only execute 10 times per second.
    // This should be the single point of entry for fetching things out of the image cache...
    @MainActor func assignTasksToDownloader() async {
        
        if isRefreshing {
            return
        }
        
        if isAssigningTasksToDownloader {
            isAssigningTasksToDownloaderEnqueued = true
            return
        }
        
        if staticGridLayout.getNumberOfCells() <= 0 {
            return
        }
        
        let containerTopY = staticGridLayout.getContainerTop()
        let containerBottomY = staticGridLayout.getContainerBottom()
        if containerBottomY <= containerTopY {
            return
        }
        
        var firstCellIndexOnScreen = staticGridLayout.getFirstCellIndexOnScreen() - Self.probeAheadOrBehindRangeForDownloads
        if firstCellIndexOnScreen < 0 {
            firstCellIndexOnScreen = 0
        }
        
        var lastCellIndexOnScreen = staticGridLayout.getLastCellIndexOnScreen() + Self.probeAheadOrBehindRangeForDownloads
        if lastCellIndexOnScreen >= numberOfCells {
            lastCellIndexOnScreen = numberOfCells - 1
        }
        
        guard lastCellIndexOnScreen > firstCellIndexOnScreen else {
            return
        }
        
        let containerRangeY = containerTopY...containerBottomY
        
        isAssigningTasksToDownloader = true
        
        _addDownloadItems.removeAll(keepingCapacity: true)
        _checkCacheDownloadItems.removeAll(keepingCapacity: true)
        
        var cellIndex = firstCellIndexOnScreen
        while cellIndex < lastCellIndexOnScreen {
            if let communityCellData = getCommunityCellData(at: cellIndex) {
                if let key = communityCellData.key {
                    
                    if _imageDict[key] != nil {
                        // We already have this image, don't do anything at all with it
                        cellIndex += 1
                        continue
                    }
                    
                    if _imageFailedSet.contains(communityCellData.index) {
                        // This one failed already, don't do anything at all with it
                        cellIndex += 1
                        continue
                    }
                    
                    if _imageDidCheckCacheSet.contains(communityCellData.index) {
                        // We have already checked the image cache for this,
                        // so we should just download it. No need to hit the
                        // cache an extra time with this request.
                        _addDownloadItems.append(communityCellData)
                    } else {
                        // We have never checked the image cache, let's first
                        // check the image cache, then if it whiffs, we can
                        // download it in this pass as well...
                        _checkCacheDownloadItems.append(communityCellData)
                    }
                }
            }
            cellIndex += 1
        }
        
        await _loadUpImageCacheAndHandOffMissesToDownloadList()
        
        await _loadUpDownloaderAndComputePriorities(containerTopY: containerTopY, containerRangeY: containerRangeY)
        
        await downloader.startTasksIfNecessary()
        
        //
        // Let's not bunch up requests calls to this.
        // If they bunch up, we enqueue another call.
        //
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        isAssigningTasksToDownloader = false
        if isAssigningTasksToDownloaderEnqueued {
            Task { @MainActor in
                isAssigningTasksToDownloaderEnqueued = false
                await assignTasksToDownloader()
            }
        }
    }
    
    @MainActor func _loadUpImageCacheAndHandOffMissesToDownloadList() async {
        if _checkCacheDownloadItems.count > 0 {
            
            _checkCacheKeys.removeAll(keepingCapacity: true)
            
            for communityCellData in _checkCacheDownloadItems {
                _imageDidCheckCacheSet.insert(communityCellData.index)
                if let key = communityCellData.key {
                    let keyAndIndexPair = KeyAndIndexPair(key: key, index: communityCellData.index)
                    _checkCacheKeys.append(keyAndIndexPair)
                }
            }
            
            let cacheDict = await imageCache.batchRetrieve(_checkCacheKeys)
            
            var countNotInCache = 0
            var countInCache = 0
            // If it was NOT in the cache, let's download it...
            for communityCellData in _checkCacheDownloadItems {
                if let key = communityCellData.key {
                    let keyAndIndexPair = KeyAndIndexPair(key: key, index: communityCellData.index)
                    if cacheDict[keyAndIndexPair] === nil {
                        countNotInCache += 1
                        _addDownloadItems.append(communityCellData)
                    } else {
                        countInCache += 1
                    }
                }
            }
            
            if countNotInCache > 0 {
                print("⚙️ \(countNotInCache) images were not in the cache, adding to downloader...")
            }
            
            if countInCache > 0 {
                print("📝 \(countInCache) images were pulled from the cache, no need to download...")
            }
            
            // If it WAS in the cache, let's store the image and
            // update the UI. This was a successful cache hit!
            
            // Let's do 3 er 4 at a time. This seems to lag less.
            
            struct KeyIndexImage {
                let image: UIImage
                let key: String
                let index: Int
            }
            
            var cacheContents = [KeyIndexImage]()
            
            for (keyAndIndexPair, image) in cacheDict {
                
                cacheContents.append(KeyIndexImage(image: image,
                                                   key: keyAndIndexPair.key,
                                                   index: keyAndIndexPair.index))
            }
            
            var cacheContentIndex = 0
            while cacheContentIndex < cacheContents.count {
                
                var loops = 4
                while cacheContentIndex < cacheContents.count && loops > 0 {
                    
                    let cacheContent = cacheContents[cacheContentIndex]
                    
                    _imageDict[cacheContent.key] = cacheContent.image
                    
                    if let gridCellModel = getGridCellModel(at: cacheContent.index) {
                        switch gridCellModel.state {
                        case .success:
                            break
                        default:
                            gridCellModel.state = .success(cacheContent.image)
                        }
                    }
                    
                    // Let the UI update.
                    try? await Task.sleep(nanoseconds: 15_000_000)
                    
                    cacheContentIndex += 1
                    loops -= 1
                }
            }
        }
    }
    
    @MainActor func _loadUpDownloaderAndComputePriorities(containerTopY: Int, containerRangeY: ClosedRange<Int>) async {
        
        await downloader.addDownloadTaskBatch(_addDownloadItems)
        
        let taskList = await downloader.taskList
        
        _priorityCommunityCellDatas.removeAll(keepingCapacity: true)
        _priorityList.removeAll(keepingCapacity: true)
        
        for task in taskList {
            let cellIndex = task.index
            if let communityCellData = getCommunityCellData(at: cellIndex) {
                
                let cellLeftX = staticGridLayout.getCellLeft(cellIndex: cellIndex)
                let cellTopY = staticGridLayout.getCellTop(cellIndex: cellIndex)
                let cellBottomY = staticGridLayout.getCellBottom(cellIndex: cellIndex)
                let cellRangeY = cellTopY...cellBottomY
                
                let overlap = containerRangeY.overlaps(cellRangeY)
                
                if overlap {
                    
                    let distX = cellLeftX
                    let distY = max(cellTopY - containerTopY, 0)
                    let priority = priority(distX: distX, distY: distY)
                    
                    _priorityCommunityCellDatas.append(communityCellData)
                    _priorityList.append(priority)
                } else {
                    _priorityCommunityCellDatas.append(communityCellData)
                    _priorityList.append(0)
                }
            }
        }
        await downloader.setPriorityBatch(_priorityCommunityCellDatas, _priorityList)
    }
}

extension CommunityViewModel: StaticGridLayoutDelegate {
    
    @MainActor func layoutDidChangeVisibleCells() {
        handleVisibleCellsMayHaveChanged()
    }
    
    @MainActor func layoutDidChangeWidth() {
        layoutWidth = staticGridLayout.width
    }
    
    @MainActor func layoutDidChangeHeight() {
        layoutHeight = staticGridLayout.height
    }
    
    @MainActor func layoutContainerSizeDidChange() {
        handleNumberOfCellsMayHaveChanged()
    }
}

extension CommunityViewModel: DirtyImageDownloaderDelegate {
    @MainActor func dataDownloadDidStart(_ index: Int) {
        
    }
    
    @MainActor func dataDownloadDidSucceed(_ index: Int, image: UIImage) {
        //print("✅ Image download success @ \(index)")
        _imageFailedSet.remove(index)
        if let communityCellData = getCommunityCellData(at: index) {
            if let key = communityCellData.key {
                _imageDict[key] = image
                Task {
                    await imageCache.cacheImage(image, key)
                }
            }
        }
    }
    
    @MainActor func dataDownloadDidCancel(_ index: Int) {
        print("🧩 We had an image cancel its download @ \(index)")
    }
    
    @MainActor func dataDownloadDidFail(_ index: Int) {
        print("🎲 We had an image fail to download @ \(index)")
        _imageFailedSet.insert(index)
    }
}
