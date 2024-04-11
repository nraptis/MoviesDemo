//
//  GridLayout.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import UIKit
import SwiftUI

protocol GridLayoutDelegate: AnyObject {
    func cellsDidEnterScreen(_ cellIndices: [Int])
    func cellsDidLeaveScreen(_ cellIndices: [Int])
}

@MainActor class GridLayout {
    
    nonisolated init() {
        
    }
    
    struct ThumbGridCellModel: ThumbGridConforming {
        let index: Int
        var id: Int { index }
    }
    
    weak var delegate: GridLayoutDelegate?
    nonisolated func setDelegate(_ delegate: GridLayoutDelegate) {
        Task { @MainActor in
            self.delegate = delegate
        }
    }
    
    // The content (grid) entire width and height
    private(set) var width: CGFloat = 255
    private(set) var height: CGFloat = 255
    
    // cell grid layout parameters
    let cellMaximumWidth = Device.isPad ? 170 : 60
    let cellHeight = Device.isPad ? (255) : (90 + 44)
    
    let cellSpacingH = 9
    let cellPaddingLeft = 24
    let cellPaddingRight = 24
    
    let cellSpacingV = 9
    let cellPaddingTop = 24
    let cellPaddingBottom = 128
    
    private var _numberOfCells = 0
    private var _numberOfRows = 0
    private var _numberOfCols = 0 // needs to be computed BEFORE _numberOfRows
    
    private var _cellWidthArray = [Int]()
    private var _cellXArray = [Int]()
    
    private var _containerFrameInsetBySafeArea = CGRect.zero
    private var _containerFrameWithoutSafeArea = CGRect.zero
    private var _scrollContentFrame = CGRect.zero
    
    func clear() {
        _numberOfCells = 0
        _numberOfRows = 0
        _numberOfCols = 0 // needs to be computed BEFORE _numberOfRows
        
        _cellWidthArray = [Int]()
        _cellXArray = [Int]()
    }
    
    func getNumberOfCols() -> Int {
        _numberOfCols
    }
    
    func getNumberOfRows() -> Int {
        _numberOfRows
    }
    
    func registerNumberOfCells(_ numberOfCells: Int) {
        if numberOfCells != _numberOfCells {
            _numberOfCells = numberOfCells
            layoutGrid()
            refreshVisibleCells()
        }
    }
    
    func registerContainer(_ containerGeometry: GeometryProxy, _ numberOfCells: Int) {
        
        let newContainerFrameInsetBySafeArea = containerGeometry.frame(in: .global)
        
        let left = containerGeometry.safeAreaInsets.leading
        let right = containerGeometry.safeAreaInsets.trailing
        let top = containerGeometry.safeAreaInsets.top
        let bottom = containerGeometry.safeAreaInsets.bottom

        let expandedX = newContainerFrameInsetBySafeArea.minX - left
        let expandedY = newContainerFrameInsetBySafeArea.minY - top
        let expandedHeight = newContainerFrameInsetBySafeArea.height + (top + bottom)
        let expandedWidth = newContainerFrameInsetBySafeArea.width + (left + right)
        
        let newContainerFrameWithoutSafeArea = CGRect(x: expandedX,
                                                      y: expandedY,
                                                      width: expandedWidth,
                                                      height: expandedHeight)
        
        // Did something change? If so, we want to re-layout our grid!
        if newContainerFrameInsetBySafeArea != _containerFrameInsetBySafeArea ||
            newContainerFrameWithoutSafeArea != _containerFrameWithoutSafeArea ||
            numberOfCells != _numberOfCells {
            _containerFrameInsetBySafeArea = newContainerFrameInsetBySafeArea
            _containerFrameWithoutSafeArea = newContainerFrameWithoutSafeArea
            _numberOfCells = numberOfCells
            layoutGrid()
        }
    }
    
    func registerScrollContent(_ scrollContentGeometry: GeometryProxy) {
        /*
        if numberOfCells != _numberOfCells {
            _numberOfCells = numberOfCells
            updateGridWithNewNumberOfCells()
        }
        */
        
        let newScrollContentFrame = scrollContentGeometry.frame(in: .global)
        _scrollContentFrame = newScrollContentFrame
        refreshVisibleCells()
    }
    
    //use for clipping (show and hide cells, notify which cells are visible...)
    private static let onScreenPadding = 0
    
    func getTopRow() -> Int {
        let containerTop = getContainerTop() - Self.onScreenPadding
        var row = containerTop - cellPaddingTop
        row = (row / (cellHeight + cellSpacingV))
        if row >= _numberOfRows { row = _numberOfRows - 1 }
        if row < 0 { row = 0 }
        return row
    }
    
    func getBottomRow() -> Int {
        let containerBottom = getContainerBottom() + Self.onScreenPadding
        var row = containerBottom - cellPaddingTop// + cellHeight
        row = (row / (cellHeight + cellSpacingV))
        if row >= _numberOfRows { row = _numberOfRows - 1 }
        if row < 0 { row = 0 }
        return row
    }
    
    private var _allVisibleCellModels = [ThumbGridCellModel]()
    private var _allVisibleCellModelsTemp = [ThumbGridCellModel]()
    private var _allVisibleCellModelIndicesRemove = [Int]()
    private var _allVisibleCellModelIndicesAdd = [Int]()
    func getAllVisibleCellModels() -> [ThumbGridCellModel] {
        return _allVisibleCellModels
    }
    
    var _refreshBuffer = [Bool]()
    func refreshVisibleCells() {
        
        let _firstCellIndexOnScreen = firstCellIndexOnScreen()
        let _lastCellIndexOnScreen = lastCellIndexOnScreen()
        
        let count = (_lastCellIndexOnScreen - _firstCellIndexOnScreen) + 1
        while _refreshBuffer.count < count {
            _refreshBuffer.append(false)
        }
        
        if count > 0 {
            for index in 0..<count {
                _refreshBuffer[index] = false
            }
        }
        
        _allVisibleCellModelIndicesAdd.removeAll(keepingCapacity: true)
        _allVisibleCellModelIndicesRemove.removeAll(keepingCapacity: true)
        _allVisibleCellModelsTemp.removeAll(keepingCapacity: true)
        
        for cellModel in _allVisibleCellModels {
            if cellModel.index >= _firstCellIndexOnScreen && cellModel.index <= _lastCellIndexOnScreen {
                _allVisibleCellModelsTemp.append(cellModel)
                _refreshBuffer[cellModel.index - _firstCellIndexOnScreen] = true
            } else {
                _allVisibleCellModelIndicesRemove.append(cellModel.index)
            }
        }
        
        _allVisibleCellModels.removeAll(keepingCapacity: true)
        
        if count > 0 {
            for index in 0..<count {
                if _refreshBuffer[index] == false {
                    let cellModel = ThumbGridCellModel(index: index + _firstCellIndexOnScreen)
                    _allVisibleCellModelIndicesAdd.append(cellModel.index)
                    _allVisibleCellModels.append(cellModel)
                }
            }
        }
        
        for index in 0..<_allVisibleCellModelsTemp.count {
            let cellModel = _allVisibleCellModelsTemp[index]
            _allVisibleCellModels.append(cellModel)
        }
        
        if _allVisibleCellModelIndicesRemove.count > 0 {
            delegate?.cellsDidLeaveScreen(_allVisibleCellModelIndicesRemove)
        }
        
        if _allVisibleCellModelIndicesAdd.count > 0 {
            delegate?.cellsDidEnterScreen(_allVisibleCellModelIndicesAdd)
        }
        
    }
    
    private func layoutGrid() {
        
        _numberOfCols = numberOfCols()
        _numberOfRows = numberOfRows()
        _cellWidthArray = cellWidthArray()
        _cellXArray = cellXArray()
        
        //print("layout \(_numberOfCols) x \(_numberOfRows)")
        
        width = _containerFrameInsetBySafeArea.width
        height = CGFloat(_numberOfRows * cellHeight + (cellPaddingTop + cellPaddingBottom))
        //add the space between each cell vertically
        if _numberOfRows > 1 {
            height += CGFloat((_numberOfRows - 1) * cellSpacingV)
        }
    }
    
    func updateGridWithNewNumberOfCells() {
        print("updateGridWithNewNumberOfCells ==> \(1000)")
        _numberOfRows = numberOfRows()
        height = CGFloat(_numberOfRows * cellHeight + (cellPaddingTop + cellPaddingBottom))
        //add the space between each cell vertically
        if _numberOfRows > 1 {
            height += CGFloat((_numberOfRows - 1) * cellSpacingV)
        }
    }
    
    func index(rowIndex: Int, colIndex: Int) -> Int {
        return (_numberOfCols * rowIndex) + colIndex
    }
    
    func col(index: Int) -> Int {
        if _numberOfCols > 0 {
            return index % _numberOfCols
        }
        return 0
    }
    
    func row(index: Int) -> Int {
        if _numberOfCols > 0 {
            return index / _numberOfCols
        }
        return 0
    }
    
    func firstCellIndexOf(row rowIndex: Int) -> Int {
        _numberOfCols * rowIndex
    }
    
    func lastCellIndexOf(row rowIndex: Int) -> Int {
        (_numberOfCols * rowIndex) + (_numberOfCols - 1)
    }
    
    func firstCellIndexOnScreen() -> Int {
        let topRow = getTopRow()
        let result = firstCellIndexOf(row: topRow)
        return result
    }
    
    func lastCellIndexOnScreen() -> Int {
        let bottomRow = getBottomRow()
        let result = lastCellIndexOf(row: bottomRow)
        return result
    }
    
    
}

// clipping helpers
extension GridLayout {
    
    func getContainerTop() -> Int {
        Int(_containerFrameWithoutSafeArea.minY - _scrollContentFrame.minY)
    }
    
    func getContainerBottom() -> Int {
        Int(_containerFrameWithoutSafeArea.maxY - _scrollContentFrame.minY)
    }
    
    // cell top
    func getCellTop(withCellIndex cellIndex: Int) -> Int {
        getCellTop(withRowIndex: row(index: cellIndex))
    }
    
    func getCellTop(withRowIndex rowIndex: Int) -> Int {
        cellPaddingTop + rowIndex * (cellHeight + cellSpacingV)
    }
    
    // cell bottom
    func getCellBottom(withCellIndex cellIndex: Int) -> Int {
        getCellBottom(withRowIndex: row(index: cellIndex))
    }
    
    func getCellBottom(withRowIndex rowIndex: Int) -> Int {
        getCellTop(withRowIndex: rowIndex) + cellHeight
    }
    
    // cell left
    func getCellLeft(withCellIndex cellIndex: Int) -> Int {
        getCellLeft(withColIndex: col(index: cellIndex))
    }
    
    func getCellLeft(withColIndex colIndex: Int) -> Int {
        if _cellXArray.count > 0 {
            var colIndex = min(colIndex, _cellXArray.count - 1)
            colIndex = max(colIndex, 0)
            return Int(_cellXArray[colIndex])
        }
        return 0
    }
}

// cell frame helpers
extension GridLayout {
    
    func getX(at index: Int) -> CGFloat {
        var colIndex = col(index: index)
        if _cellXArray.count > 0 {
            colIndex = min(colIndex, _cellXArray.count - 1)
            colIndex = max(colIndex, 0)
            return CGFloat(_cellXArray[colIndex])
        }
        return 0
    }
    
    func getY(at index: Int) -> CGFloat {
        let rowIndex = row(index: index)
        return CGFloat(getCellTop(withRowIndex: rowIndex))
    }
    
    func getWidth(at index: Int) -> CGFloat {
        var colIndex = col(index: index)
        if _cellWidthArray.count > 0 {
            colIndex = min(colIndex, _cellWidthArray.count - 1)
            colIndex = max(colIndex, 0)
            return CGFloat(_cellWidthArray[colIndex])
        }
        return 0
    }
    
    func getHeight(at index: Int) -> CGFloat {
        return CGFloat(cellHeight)
    }
}

// grid layout helpers (internal)
extension GridLayout {
    
    func numberOfCells() -> Int {
        _numberOfCells
    }
    
    func numberOfRows() -> Int {
        if _numberOfCols > 0 {
            var result = _numberOfCells / _numberOfCols
            if (_numberOfCells % _numberOfCols) != 0 { result += 1 }
            return result
        }
        return 0
    }
    
    func numberOfCols() -> Int {
        
        if _numberOfCells <= 0 { return 0 }
        
        var result = 1
        let availableWidth = _containerFrameInsetBySafeArea.width - CGFloat(cellPaddingLeft + cellPaddingRight)
        
        //try out horizontal counts until the cells would be
        //smaller than the maximum width
        
        var horizontalCount = 2
        while horizontalCount < 1024 {
            
            //the amount of space between the cells for this horizontal count
            let totalSpaceWidth = CGFloat((horizontalCount - 1) * cellSpacingH)
            
            let availableWidthForCells = availableWidth - totalSpaceWidth
            let expectedCellWidth = availableWidthForCells / CGFloat(horizontalCount)
            
            if expectedCellWidth < CGFloat(cellMaximumWidth) {
                break
            } else {
                result = horizontalCount
                horizontalCount += 1
            }
        }
        return result
    }
    
    func cellWidthArray() -> [Int] {
        var result = [Int]()
        
        if _numberOfCols <= 0 {
            return result
        }
        
        var totalSpace = Int(_containerFrameInsetBySafeArea.width)
        totalSpace -= cellPaddingLeft
        totalSpace -= cellPaddingRight
        
        //subtract out the space between cells!
        if _numberOfCols > 1 {
            totalSpace -= (_numberOfCols - 1) * cellSpacingH
        }
        
        let baseWidth = totalSpace / _numberOfCols
        
        for _ in 0..<_numberOfCols {
            result.append(baseWidth)
            totalSpace -= baseWidth
        }
        
        //there might be a little space left over,
        //evenly distribute that remaining space...
        
        while totalSpace > 0 {
            for colIndex in 0..<_numberOfCols {
                result[colIndex] += 1
                totalSpace -= 1
                if totalSpace <= 0 { break }
            }
        }
        return result
    }
    
    func cellXArray() -> [Int] {
        var result = [Int]()
        var cellX = cellPaddingLeft
        for index in 0..<_numberOfCols {
            result.append(cellX)
            cellX += _cellWidthArray[index] + cellSpacingH
        }
        return result
    }
    
    func cellYArray() -> [Int] {
        var result = [Int]()
        var cellY = cellPaddingTop
        for _ in 0..<_numberOfRows {
            result.append(cellY)
            cellY += cellHeight + cellSpacingV
        }
        
        return result
    }
    
}
