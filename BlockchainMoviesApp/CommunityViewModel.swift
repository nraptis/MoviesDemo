//
//  CommunityViewModel.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
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
    
    @MainActor @ObservationIgnored fileprivate var _imageDict = [String: UIImage]()
    
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
    
    @MainActor func pulse() async {
        
        /*
        guard let movieGridView = movieGridView else {
            return
        }
        
        for movieGridCell in movieGridView.movieGridCells {
            
            guard let communityCellData = getCommunityCellData(at: movieGridCell.index) else {
                switch movieGridCell.state {
                case .missingModel:
                    break
                default:
                    movieGridCell.updateStatus(.missingModel)
                }
                continue
            }
            
            guard let key = communityCellData.key else {
                switch movieGridCell.state {
                case .missingKey:
                    break
                default:
                    movieGridCell.updateStatus(.missingKey)
                }
                continue
            }
            
            let index = communityCellData.index
            
            if movieGridCell.imageView.image === nil {
                
                if let image = _imageDict[key] {
                    movieGridCell.updateStatus(.success(image))
                } else {
                    
                    // This is the common "trap" scenario. We have no image, neither does the cell...
                    // Let's see if we know the state...
                    
                    let keyAndIndexPair = KeyAndIndexPair(key: key, index: index)
                    if let image = await imageCache.singleRetrieve(keyAndIndexPair) {
                        _imageDict[key] = image
                        movieGridCell.updateStatus(.success(image))
                    } else if await downloader.isDownloading(communityCellData) {
                        
                        if await downloader.isDownloadingActively(communityCellData) {
                            switch movieGridCell.state {
                            case .downloadingActively:
                                break
                            default:
                                movieGridCell.updateStatus(.downloadingActively)
                            }
                        } else {
                            switch movieGridCell.state {
                            case .downloading:
                                break
                            default:
                                movieGridCell.updateStatus(.downloading)
                            }
                        }
                    } else if _imageFailedSet.contains(index) {
                        switch movieGridCell.state {
                        case .error:
                            break
                        default:
                            movieGridCell.updateStatus(.error)
                        }
                    } else {
                        // The cell is in an illegal state right here...
                        // Let's try to download the thing...
                        
                        await downloader.addDownloadTask(communityCellData)
                        if await downloader.isDownloading(communityCellData) {
                            if await downloader.isDownloadingActively(communityCellData) {
                                switch movieGridCell.state {
                                case .downloadingActively:
                                    break
                                default:
                                    movieGridCell.updateStatus(.downloadingActively)
                                }
                            } else {
                                switch movieGridCell.state {
                                case .downloading:
                                    break
                                default:
                                    movieGridCell.updateStatus(.downloading)
                                }
                            }
                        } else {
                            // This probably shouldn't happen.
                            switch movieGridCell.state {
                            case .illegal:
                                break
                            default:
                                movieGridCell.updateStatus(.illegal)
                            }
                        }
                    }
                }
                
            } else {
                
                // The cell already has an image...
                
                if let image = _imageDict[key] {
                    switch movieGridCell.state {
                    case .success:
                        break
                    default:
                        movieGridCell.updateStatus(.success(image))
                    }
                } else {
                    
                    // This is a strange case. The cell has an image, but we do not have an image...
                    
                    if _imageFailedSet.contains(index) {
                        switch movieGridCell.state {
                        case .error:
                            break
                        default:
                            movieGridCell.updateStatus(.error)
                        }
                    } else if await downloader.isDownloading(communityCellData) {
                        // Perhaps we are downloading...
                        if await downloader.isDownloadingActively(communityCellData) {
                            switch movieGridCell.state {
                            case .downloadingActively:
                                break
                            default:
                                movieGridCell.updateStatus(.downloadingActively)
                            }
                        } else {
                            switch movieGridCell.state {
                            case .downloading:
                                break
                            default:
                                movieGridCell.updateStatus(.downloading)
                            }
                        }
                    } else {
                        
                        // Maybe it's in the cache, but not
                        // the image dictionary, e.g. we flushed memory warning.
                        let keyAndIndexPair = KeyAndIndexPair(key: key, index: index)
                        if let image = await imageCache.singleRetrieve(keyAndIndexPair) {
                            _imageDict[key] = image
                            movieGridCell.updateStatus(.success(image))
                        } else {
                            
                            // Fishy state. Let's try to download the image...
                            
                            await downloader.addDownloadTask(communityCellData)
                            if await downloader.isDownloading(communityCellData) {
                                if await downloader.isDownloadingActively(communityCellData) {
                                    switch movieGridCell.state {
                                    case .downloadingActively:
                                        break
                                    default:
                                        movieGridCell.updateStatus(.downloadingActively)
                                    }
                                } else {
                                    switch movieGridCell.state {
                                    case .downloading:
                                        break
                                    default:
                                        movieGridCell.updateStatus(.downloading)
                                    }
                                }
                            } else {
                                // This probably shouldn't happen.
                                switch movieGridCell.state {
                                case .illegal:
                                    break
                                default:
                                    movieGridCell.updateStatus(.illegal)
                                }
                            }
                        }
                    }
                }
            }
        }
        await downloader.startTasksIfNecessary()
        */
    }
    
    @MainActor func refresh() async {
        
        if isRefreshing {
            print("🧚🏽 We are already refreshing... No double refreshing...!!!")
            return
        }
        
        isRefreshing = true
        
        downloader.isBlocked = true
        await downloader.cancelAll()
        
        var fudge = 0
        
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
        
        let nwMovies = await _fetchPopularMoviesWithNetwork(page: 1)
        
        // This is mainly just for user feedback; the refresh feels
        // more natural if it takes a couple seconds...
        try? await Task.sleep(nanoseconds: 1_250_000_000)
        
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

        // What we do here is place new cell models in this range,
        // which will now be 100% clean and ready for that fresh
        // fresh sweet baby Jesus sweeting falling down fast.
        itemIndex = 0
        cellModelIndex = index
        while itemIndex < newCommunityCellDatas.count {
            let communityCellData = newCommunityCellDatas[itemIndex]
            communityCellDatas[cellModelIndex] = communityCellData
            itemIndex += 1
            cellModelIndex += 1
        }
    }
    
    private func _fetchPopularMoviesWithNetwork(page: Int) async -> [NWMovie] {
        
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
    
    
    @MainActor private func updateCell(at index: Int) async {
        
        guard let gridCellModel = getGridCellModel(at: index) else {
            return
        }
        
        guard let communityCellData = getCommunityCellData(at: index) else {
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
                switch gridCellModel.state {
                case .success:
                    break
                default:
                    gridCellModel.state = .success(image)
                }
            } else if _imageFailedSet.contains(index) {
                switch gridCellModel.state {
                case .error:
                    break
                default:
                    gridCellModel.state = .error
                }
            } 
            
            
        }
    }
    
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
    
    func forceRestartDownload(at index: Int) {
        fatalError("Not Implemented")
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
        Task { @MainActor in
            await assignTasksToDownloader()
        }
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
    @MainActor func handleCellClicked(at index: Int) {
        
        if _isFetchingDetails {
            print("🪚 [STOPPED] Attempted to queue up fetch details twice.")
            return
        }
        
        _isFetchingDetails = true
        Task { @MainActor in
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
    
    private var _gridCellModelsTemp = [GridCellModel]()
    private var _layoutGridCellIndicesTemp = [Int]()
    
    @MainActor func handleVisibleCellsMayHaveChanged() {
        
        if staticGridLayout.isAnyItemPresent {
            isAnyItemPresent = true
        }
        
        let firstCellIndexOnScreen = staticGridLayout.getFirstCellIndexOnScreen()
        let lastCellIndexOnScreen = staticGridLayout.getLastCellIndexOnScreen()
        
        // List of cells we can write to.
        _gridCellModelsTemp.removeAll(keepingCapacity: true)
        
        for gridCellModel in gridCellModels {
            if let communityCellData = gridCellModel.communityCellData {
                let doesExistInLayout = (communityCellData.index >= firstCellIndexOnScreen && communityCellData.index <= lastCellIndexOnScreen)
                if doesExistInLayout {
                    // We CANNOT overwrite this cell.
                } else {
                    // We can overwrite this cell.
                    _gridCellModelsTemp.append(gridCellModel)
                    gridCellModel.isVisible = false
                    gridCellModel.communityCellData = nil
                }
            } else {
                // We can overwrite this cell.
                _gridCellModelsTemp.append(gridCellModel)
                gridCellModel.isVisible = false
                gridCellModel.communityCellData = nil
            }
        }
        
        // These will be the ones we need to freshly add...
        _layoutGridCellIndicesTemp.removeAll(keepingCapacity: true)
        
        var checkLayoutIndex = firstCellIndexOnScreen
        while checkLayoutIndex <= lastCellIndexOnScreen {
            var doesExistAndVisibleOnScreen = false
            for gridCellModel in gridCellModels {
                if gridCellModel.isVisible {
                    if let communityCellData = gridCellModel.communityCellData {
                        if communityCellData.index == checkLayoutIndex {
                            doesExistAndVisibleOnScreen = true
                        }
                    }
                }
            }
            
            if doesExistAndVisibleOnScreen {
                // We don't need to do anything with this one,
                // it's already handled properly.
            } else {
                _layoutGridCellIndicesTemp.append(checkLayoutIndex)
            }
            checkLayoutIndex += 1
        }
        
        var visibleCellIndex = 0
        while (visibleCellIndex < _layoutGridCellIndicesTemp.count) && (visibleCellIndex < _gridCellModelsTemp.count) {
            
            let cellIndex = _layoutGridCellIndicesTemp[visibleCellIndex]
            let gridCellModel = _gridCellModelsTemp[visibleCellIndex]
            
            gridCellModel.isVisible = true
            gridCellModel.layoutIndex = cellIndex
            gridCellModel.x = staticGridLayout.getCellX(cellIndex: cellIndex)
            gridCellModel.y = staticGridLayout.getCellY(cellIndex: cellIndex)
            gridCellModel.width = staticGridLayout.getCellWidth(cellIndex: cellIndex)
            gridCellModel.height = staticGridLayout.getCellHeight(cellIndex: cellIndex)
            
            guard let communityCellData = getCommunityCellData(at: cellIndex) else {
                gridCellModel.state = .missingModel
                visibleCellIndex += 1
                continue
            }
            
            gridCellModel.communityCellData = communityCellData
            
            if let image = getCellImage(at: cellIndex) {
                gridCellModel.state = .success(image)
            } else if _imageFailedSet.contains(cellIndex) {
                gridCellModel.state = .error
            } else {
                gridCellModel.state = .illegal
            }
            
            visibleCellIndex += 1
        }
        
        while visibleCellIndex < _layoutGridCellIndicesTemp.count {
            
            print("🚧 OVERFLOW: @ \(visibleCellIndex), cell = \(_layoutGridCellIndicesTemp[visibleCellIndex]), how is that?")
            
            visibleCellIndex += 1
        }
                
        fetchMorePagesIfNecessary()
        Task { @MainActor in
            await assignTasksToDownloader()
        }
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
            for (keyAndIndexPair, image) in cacheDict {
                _imageDict[keyAndIndexPair.key] = image
                //if let communityCellData = getCommunityCellData(at: keyAndIndexPair.index) {
                    //movieGridView?.handleImageChanged(index: communityCellData.index)
                    //cellNeedsUpdatePublisher.send(keyAndIndexPair.index)
                //}
                
                Task {
                    await updateCell(at: keyAndIndexPair.index)
                }
                
                // Let the UI update.
                try? await Task.sleep(nanoseconds: 10_000_000)
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
        Task {
            await updateCell(at: index)
        }
    }
    
    @MainActor func dataDownloadDidSucceed(_ index: Int, image: UIImage) {
        //print("✅ Image download success @ \(index)")
        _imageFailedSet.remove(index)
        if let communityCellData = getCommunityCellData(at: index) {
            if let key = communityCellData.key {
                _imageDict[key] = image
                
                /*
                Task {
                    await self.imageCache.cacheImage(image, key)
                }
                */
                
                Task {
                    await updateCell(at: index)
                }
            }
        }
    }
    
    @MainActor func dataDownloadDidCancel(_ index: Int) {
        //print("🧩 We had an image cancel its download @ \(index)")
        Task {
            await updateCell(at: index)
        }
    }
    
    @MainActor func dataDownloadDidFail(_ index: Int) {
        //print("🎲 We had an image fail to download @ \(index)")
        _imageFailedSet.insert(index)
        Task {
            await updateCell(at: index)
        }
    }
}