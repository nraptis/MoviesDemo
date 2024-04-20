//
//  StaticGridLayout.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/19/24.
//

import UIKit
import SwiftUI

protocol StaticGridLayoutDelegate: AnyObject {
    func layoutDidChangeVisibleCells()
    func layoutDidChangeWidth()
    func layoutDidChangeHeight()
    func layoutContainerSizeDidChange()
}

@MainActor class StaticGridLayout {
    
    nonisolated init() {
        
    }
    
    weak var delegate: StaticGridLayoutDelegate?
    
    // The content (grid) entire width and height
    private(set) var width: CGFloat = 255
    private(set) var height: CGFloat = 255
    
    // cell grid layout parameters
    private let cellMaximumWidth = Device.isPad ? 170 : 100
    private var cellWidth = 100
    private var cellHeight = 100
    
    
    private let cellSpacingH = 9
    private let cellPaddingLeft = 24
    private let cellPaddingRight = 24
    
    private let cellSpacingV = 9
    private let cellPaddingTop = 24
    private let cellPaddingBottom = 128
    
    private var _numberOfCells = 0
    private var _numberOfRows = 0
    private var _numberOfCols = 0
    
    private var _maximumNumberOfVisibleCells = 0
    private var _cellXArray = [Int]()
    
    private var _containerFrame = CGRect.zero
    private var _scrollContentFrame = CGRect.zero
    
    func clear() {
        _numberOfCells = 0
        _numberOfRows = 0
        _numberOfCols = 0 // needs to be computed BEFORE _numberOfRows
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
    
    func registerContainer(_ newContainerFrame: CGRect, _ numberOfCells: Int) {
        if newContainerFrame != _containerFrame || numberOfCells != _numberOfCells {
            print("🤡 [StaticGridLayout] registerContainer [\(newContainerFrame.width) x \(newContainerFrame.height)], #\(numberOfCells) cells.")
            _containerFrame = newContainerFrame
            _numberOfCells = numberOfCells
            layoutGrid()
            calculateMaximumNumberOfVisibleCells()
            delegate?.layoutContainerSizeDidChange()
        }
    }
    
    func registerScrollContent(_ newScrollContentFrame: CGRect) {
        _scrollContentFrame = newScrollContentFrame
        refreshVisibleCells()
    }
    
    func getTopRowIndex() -> Int {
        let containerTop = getContainerTop()
        var row = containerTop - cellPaddingTop
        row = (row / (cellHeight + cellSpacingV))
        if row >= _numberOfRows { row = _numberOfRows - 1 }
        if row < 0 { row = 0 }
        return row
    }
    
    func getBottomRowIndex() -> Int {
        let containerBottom = getContainerBottom()
        var row = containerBottom - cellPaddingTop
        row = (row / (cellHeight + cellSpacingV))
        if row >= _numberOfRows { row = _numberOfRows - 1 }
        if row < 0 { row = 0 }
        return row
    }
    
    var isAnyItemPresent: Bool {
        _numberOfCells > 0
    }
    
    private var _previousFirstCellIndexOnScreen = -1
    private var _previousLastCellIndexOnScreen = -1
    func refreshVisibleCells() {
        
        _calculateLastCellIndexOnScreen()
        _calculateFirstCellIndexOnScreen()
        
        if (_previousFirstCellIndexOnScreen != _firstCellIndexOnScreen) ||
            (_previousLastCellIndexOnScreen != _lastCellIndexOnScreen) {
            _previousFirstCellIndexOnScreen = _firstCellIndexOnScreen
            _previousLastCellIndexOnScreen = _lastCellIndexOnScreen
            delegate?.layoutDidChangeVisibleCells()
        }
    }
    
    private func layoutGrid() {
        
        calculateNumberOfCols()
        calculateNumberOfRows()
        calculateCellWidth()
        calculateCellXArray()
        
        cellHeight = (cellWidth) + (cellWidth >> 2)
        
        let previousWidth = width
        let previousHeight = height
        
        width = _containerFrame.width
        height = CGFloat(_numberOfRows * cellHeight + (cellPaddingTop + cellPaddingBottom))
        //add the space between each cell vertically
        if _numberOfRows > 1 {
            height += CGFloat((_numberOfRows - 1) * cellSpacingV)
        }
        
        if previousWidth != width {
            delegate?.layoutDidChangeWidth()
        }
        
        if previousHeight != height {
            delegate?.layoutDidChangeHeight()
        }
    }
    
    func getCellIndex(rowIndex: Int, colIndex: Int) -> Int {
        return (_numberOfCols * rowIndex) + colIndex
    }
    
    func getColIndex(cellIndex: Int) -> Int {
        if _numberOfCols > 0 {
            return cellIndex % _numberOfCols
        }
        return 0
    }
    
    func getRowIndex(cellIndex: Int) -> Int {
        if _numberOfCols > 0 {
            return cellIndex / _numberOfCols
        }
        return 0
    }
    
    private func getFirstCellIndex(rowIndex: Int) -> Int {
        _numberOfCols * rowIndex
    }
    
    private func getLastCellIndex(rowIndex: Int) -> Int {
        (_numberOfCols * rowIndex) + (_numberOfCols - 1)
    }
    
    private var _firstCellIndexOnScreen = -1
    func getFirstCellIndexOnScreen() -> Int {
        _firstCellIndexOnScreen
    }
    
    private func _calculateFirstCellIndexOnScreen() {
        let topRowIndex = getTopRowIndex()
        _firstCellIndexOnScreen = getFirstCellIndex(rowIndex: topRowIndex)
    }
    
    private var _lastCellIndexOnScreen = -1
    func getLastCellIndexOnScreen() -> Int {
        _lastCellIndexOnScreen
    }
    
    func _calculateLastCellIndexOnScreen() {
        let bottomRowIndex = getBottomRowIndex()
        _lastCellIndexOnScreen = getLastCellIndex(rowIndex: bottomRowIndex)
    }
    
    func getNumberOfCells() -> Int {
        _numberOfCells
    }
    
    func getMaximumNumberOfVisibleCells() -> Int {
        return _maximumNumberOfVisibleCells
    }
}

// clipping helpers
extension StaticGridLayout {
    
    func getContainerTop() -> Int {
        Int(_containerFrame.minY - _scrollContentFrame.minY)
    }
    
    func getContainerBottom() -> Int {
        Int(_containerFrame.maxY - _scrollContentFrame.minY)
    }
    
    // cell top
    func getCellTop(cellIndex: Int) -> Int {
        let rowIndex = getRowIndex(cellIndex: cellIndex)
        return getCellTop(rowIndex: rowIndex)
    }
    
    func getCellTop(rowIndex: Int) -> Int {
        cellPaddingTop + rowIndex * (cellHeight + cellSpacingV)
    }
    
    // cell bottom
    func getCellBottom(cellIndex: Int) -> Int {
        let rowIndex = getRowIndex(cellIndex: cellIndex)
        return getCellBottom(rowIndex: rowIndex)
    }
    
    func getCellBottom(rowIndex: Int) -> Int {
        getCellTop(rowIndex: rowIndex) + cellHeight
    }
    
    // cell left
    func getCellLeft(cellIndex: Int) -> Int {
        let colIndex = getColIndex(cellIndex: cellIndex)
        return getCellLeft(colIndex: colIndex)
    }
    
    func getCellLeft(colIndex: Int) -> Int {
        if _cellXArray.count > 0 {
            var colIndex = min(colIndex, _cellXArray.count - 1)
            colIndex = max(colIndex, 0)
            return _cellXArray[colIndex]
        }
        return 0
    }
}

// cell frame helpers
extension StaticGridLayout {
    
    func getCellX(cellIndex: Int) -> CGFloat {
        var colIndex = getColIndex(cellIndex: cellIndex)
        if _cellXArray.count > 0 {
            colIndex = min(colIndex, _cellXArray.count - 1)
            colIndex = max(colIndex, 0)
            return CGFloat(_cellXArray[colIndex])
        }
        return 0
    }
    
    func getCellY(cellIndex: Int) -> CGFloat {
        let rowIndex = getRowIndex(cellIndex: cellIndex)
        return CGFloat(getCellTop(rowIndex: rowIndex))
    }
    
    func getCellWidth(cellIndex: Int) -> CGFloat {
        return CGFloat(cellWidth)
    }
    
    func getCellHeight(cellIndex: Int) -> CGFloat {
        return CGFloat(cellHeight)
    }
}

// grid layout helpers (internal)
extension StaticGridLayout {
    
    private func calculateNumberOfRows() {
        if _numberOfCols > 0 {
            _numberOfRows = _numberOfCells / _numberOfCols
            if (_numberOfCells % _numberOfCols) != 0 {
                _numberOfRows += 1
            }
        } else {
            _numberOfRows = 0
        }
    }
    
    private func calculateNumberOfCols() {
        
        //if _numberOfCells <= 0 { return 0 }
        
        _numberOfCols = 1
        let availableWidth = _containerFrame.width - CGFloat(cellPaddingLeft + cellPaddingRight)
        
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
                _numberOfCols = horizontalCount
                horizontalCount += 1
            }
        }
    }
    
    private func calculateCellWidth() {
        if _numberOfCols <= 0 {
            cellWidth = 16
            return
        }
        
        var totalSpace = Int(_containerFrame.width)
        totalSpace -= cellPaddingLeft
        totalSpace -= cellPaddingRight
        
        //subtract out the space between cells!
        if _numberOfCols > 1 {
            totalSpace -= (_numberOfCols - 1) * cellSpacingH
        }
        
        cellWidth = totalSpace / _numberOfCols
        
        if cellWidth < 16 {
            cellWidth = 16
        }
    }
    
    private func calculateCellXArray() {
        
        _cellXArray.removeAll(keepingCapacity: true)
        
        // We are doing all same width, so we may need to make a slight adjustment.
        var spaceConsumed = cellPaddingLeft + cellPaddingRight
        
        spaceConsumed += cellWidth * _numberOfCols
        if _numberOfCols > 1 {
            spaceConsumed += cellSpacingH * (_numberOfCols - 1)
        }
        
        let realWidth = Int(_containerFrame.width + 0.5)
        let extraOffset = (realWidth - spaceConsumed) / 2
        
        var cellX = cellPaddingLeft + extraOffset
        for _ in 0..<_numberOfCols {
            _cellXArray.append(cellX)
            cellX += cellWidth + cellSpacingH
        }
    }
    
    private func calculateMaximumNumberOfVisibleCells() {
        
        let totalSpace = Int(_containerFrame.height + 0.5)
        
        if totalSpace <= 0 {
            _maximumNumberOfVisibleCells = 0
            return
        }
        
        if _numberOfCols <= 0 {
            _maximumNumberOfVisibleCells = 0
            return
        }
        
        if cellHeight <= 0 {
            _maximumNumberOfVisibleCells = 0
            return
        }
        
        var y = -(cellHeight) + 1
        var numberOfRows = 1
        
        y += cellHeight
        y += cellSpacingV
        
        while y < totalSpace {
            numberOfRows += 1
            y += cellHeight
            y += cellSpacingV
        }
        
        _maximumNumberOfVisibleCells = _numberOfCols * numberOfRows
    }
}
