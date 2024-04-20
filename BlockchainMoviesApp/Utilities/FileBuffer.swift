//
//  FileBuffer.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/11/24.
//

import Foundation

class FileBuffer {
    
    private var buffer = [UInt8]()
    private var capacity = 0
    private var length = 0
    private var readCursor = 0
    private var writeCursor = 0
    
    private var buffer8 = [UInt8](repeating: 0, count: 1)
    private var buffer16 = [UInt8](repeating: 0, count: 2)
    private var buffer32 = [UInt8](repeating: 0, count: 4)
    private var buffer64 = [UInt8](repeating: 0, count: 8)
    
    var isEmpty: Bool {
        length <= 0
    }
    
    var data: Data {
        let fileData: Data
        if length == capacity {
            fileData = Data(buffer)
        } else {
            var dataBuffer = [UInt8](repeating: 0, count: length)
            for index in 0..<length {
                dataBuffer[index] = buffer[index]
            }
            fileData = Data(dataBuffer)
            dataBuffer.removeAll()
        }
        return fileData
    }
    
    func clear() {
        buffer.removeAll()
        length = 0
        readCursor = 0
        writeCursor = 0
        capacity = 0
    }
    
    func writeUInt8(_ value: UInt8) {
        if writeCursor >= capacity {
            let newCapacity = (writeCursor + (writeCursor >> 1) + 1)
            reserveCapacity(minimumCapacity: newCapacity)
        }
        buffer[writeCursor] = value
        writeCursor += 1
        
        if writeCursor > length {
            length = writeCursor
        }
    }
    
    func readUInt8() -> UInt8? {
        var result: UInt8?
        if readCursor < length {
            result = buffer[readCursor]
            readCursor += 1
        }
        return result
    }
    
    func writeInt8(_ value: Int8) {
        if writeCursor >= capacity {
            let newCapacity = (writeCursor + (writeCursor >> 1) + 1)
            reserveCapacity(minimumCapacity: newCapacity)
        }
        var value = value
        withUnsafeBytes(of: &value) { bytes in
            buffer8[0] = bytes[0]
        }
        buffer[writeCursor] = buffer8[0]
        writeCursor += 1
        if writeCursor > length {
            length = writeCursor
        }
    }
    
    func readInt8() -> Int8? {
        var result: Int8?
        if readCursor < length {
            buffer8[0] = buffer[readCursor]
            readCursor += 1
            buffer8.withUnsafeBytes { bytePointer in
                result = bytePointer.load(as: Int8.self)
            }
        }
        return result
    }
    
    func writeUInt16(_ value: UInt16) {
        if (writeCursor + 1) >= capacity {
            let newCapacity = (writeCursor + (writeCursor >> 1) + 2)
            reserveCapacity(minimumCapacity: newCapacity)
        }
        var value = value
        withUnsafeBytes(of: &value) { bytes in
            for index in 0..<2 {
                buffer16[index] = bytes[index]
            }
        }
        for index in 0..<2 {
            buffer[writeCursor] = buffer16[index]
            writeCursor += 1
        }
        if writeCursor > length {
            length = writeCursor
        }
    }
    
    func readUInt16() -> UInt16? {
        var result: UInt16?
        if (readCursor + 1) < length {
            for index in 0..<2 {
                buffer16[index] = buffer[readCursor]
                readCursor += 1
            }
            buffer16.withUnsafeBytes { bytePointer in
                result = bytePointer.load(as: UInt16.self)
            }
        }
        return result
    }
    
    func writeInt16(_ value: Int16) {
        if (writeCursor + 1) >= capacity {
            let newCapacity = (writeCursor + (writeCursor >> 1) + 2)
            reserveCapacity(minimumCapacity: newCapacity)
        }
        var value = value
        withUnsafeBytes(of: &value) { bytes in
            for index in 0..<2 {
                buffer16[index] = bytes[index]
            }
        }
        for index in 0..<2 {
            buffer[writeCursor] = buffer16[index]
            writeCursor += 1
        }
        if writeCursor > length {
            length = writeCursor
        }
    }
    
    
    func readInt16() -> Int16? {
        var result: Int16?
        if (readCursor + 1) < length {
            for index in 0..<2 {
                buffer16[index] = buffer[readCursor]
                readCursor += 1
            }
            buffer16.withUnsafeBytes { bytePointer in
                result = bytePointer.load(as: Int16.self)
            }
        }
        return result
    }
    
    func writeFloat32(_ value: Float) {
        if (writeCursor + 3) >= capacity {
            let newCapacity = (writeCursor + (writeCursor >> 1) + 4)
            reserveCapacity(minimumCapacity: newCapacity)
        }
        var value = value
        withUnsafeBytes(of: &value) { bytes in
            for index in 0..<4 {
                buffer32[index] = bytes[index]
            }
        }
        for index in 0..<4 {
            buffer[writeCursor] = buffer32[index]
            writeCursor += 1
        }
        if writeCursor > length {
            length = writeCursor
        }
    }
    
    func readFloat32() -> Float32? {
        var result: Float32?
        if (readCursor + 3) < length {
            for index in 0..<4 {
                buffer32[index] = buffer[readCursor]
                readCursor += 1
            }
            buffer32.withUnsafeBytes { bytePointer in
                result = bytePointer.load(as: Float32.self)
            }
        }
        return result
    }
    
    func writeInt32(_ value: Int32) {
        if (writeCursor + 3) >= capacity {
            let newCapacity = (writeCursor + (writeCursor >> 1) + 4)
            reserveCapacity(minimumCapacity: newCapacity)
        }
        var value = value
        withUnsafeBytes(of: &value) { bytes in
            for index in 0..<4 {
                buffer32[index] = bytes[index]
            }
        }
        for index in 0..<4 {
            buffer[writeCursor] = buffer32[index]
            writeCursor += 1
        }
        if writeCursor > length {
            length = writeCursor
        }
    }
    
    func readInt32() -> Int32? {
        var result: Int32?
        if (readCursor + 3) < length {
            for index in 0..<4 {
                buffer32[index] = buffer[readCursor]
                readCursor += 1
            }
            buffer32.withUnsafeBytes { bytePointer in
                result = bytePointer.load(as: Int32.self)
            }
        }
        return result
    }
    
    func writeUInt32(_ value: UInt32) {
        if (writeCursor + 3) >= capacity {
            let newCapacity = (writeCursor + (writeCursor >> 1) + 4)
            reserveCapacity(minimumCapacity: newCapacity)
        }
        var value = value
        withUnsafeBytes(of: &value) { bytes in
            for index in 0..<4 {
                buffer32[index] = bytes[index]
            }
        }
        for index in 0..<4 {
            buffer[writeCursor] = buffer32[index]
            writeCursor += 1
        }
        if writeCursor > length {
            length = writeCursor
        }
    }
    
    func readUInt32() -> UInt32? {
        var result: UInt32?
        if (readCursor + 3) < length {
            for index in 0..<4 {
                buffer32[index] = buffer[readCursor]
                readCursor += 1
            }
            buffer32.withUnsafeBytes { bytePointer in
                result = bytePointer.load(as: UInt32.self)
            }
        }
        return result
    }
    
    func writeFloat64(_ value: Float64) {
        if (writeCursor + 7) >= capacity {
            let newCapacity = (writeCursor + (writeCursor >> 1) + 8)
            reserveCapacity(minimumCapacity: newCapacity)
        }
        var value = value
        withUnsafeBytes(of: &value) { bytes in
            for index in 0..<8 {
                buffer64[index] = bytes[index]
            }
        }
        for index in 0..<8 {
            buffer[writeCursor] = buffer64[index]
            writeCursor += 1
        }
        if writeCursor > length {
            length = writeCursor
        }
    }
    
    func readFloat64() -> Float64? {
        var result: Float64?
        if (readCursor + 7) < length {
            for index in 0..<8 {
                buffer64[index] = buffer[readCursor]
                readCursor += 1
            }
            buffer64.withUnsafeBytes { bytePointer in
                result = bytePointer.load(as: Float64.self)
            }
        }
        return result
    }
    
    func writeInt64(_ value: Int64) {
        if (writeCursor + 7) >= capacity {
            let newCapacity = (writeCursor + (writeCursor >> 1) + 8)
            reserveCapacity(minimumCapacity: newCapacity)
        }
        var value = value
        withUnsafeBytes(of: &value) { bytes in
            for index in 0..<8 {
                buffer64[index] = bytes[index]
            }
        }
        for index in 0..<8 {
            buffer[writeCursor] = buffer64[index]
            writeCursor += 1
        }
        if writeCursor > length {
            length = writeCursor
        }
    }
    func readInt64() -> Int64? {
        var result: Int64?
        if (readCursor + 7) < length {
            for index in 0..<8 {
                buffer64[index] = buffer[readCursor]
                readCursor += 1
            }
            buffer64.withUnsafeBytes { bytePointer in
                result = bytePointer.load(as: Int64.self)
            }
        }
        return result
    }
    
    func writeUInt64(_ value: UInt64) {
        if (writeCursor + 7) >= capacity {
            let newCapacity = (writeCursor + (writeCursor >> 1) + 8)
            reserveCapacity(minimumCapacity: newCapacity)
        }
        var value = value
        withUnsafeBytes(of: &value) { bytes in
            for index in 0..<8 {
                buffer64[index] = bytes[index]
            }
        }
        for index in 0..<8 {
            buffer[writeCursor] = buffer64[index]
            writeCursor += 1
        }
        if writeCursor > length {
            length = writeCursor
        }
    }
    
    func readUInt64() -> UInt64? {
        var result: UInt64?
        if (readCursor + 7) < length {
            for index in 0..<8 {
                buffer64[index] = buffer[readCursor]
                readCursor += 1
            }
            buffer64.withUnsafeBytes { bytePointer in
                result = bytePointer.load(as: UInt64.self)
            }
        }
        return result
    }
    
    func writeBool(_ value: Bool) {
        if value {
            writeUInt8(1)
        } else {
            writeUInt8(0)
        }
    }
    
    func readBool() -> Bool? {
        if let char = readUInt8() {
            return (char != 0)
        }
        return false
    }
    
    func writeString(_ string: String) {
        writeData(Data(string.utf8))
    }
    
    func readString() -> String? {
        if let data = readData() {
            if let string = String(data: data, encoding: .utf8) {
                return string
            }
        }
        return nil
    }
    
    func writeData(_ data: Data) {
        let count = Int64(data.count)
        writeInt64(count)
        let bytes = [UInt8](data)
        if (writeCursor + bytes.count) > capacity {
            let newCapacity = ((writeCursor + bytes.count) + ((writeCursor + bytes.count) >> 1) + 1)
            reserveCapacity(minimumCapacity: newCapacity)
        }
        for byteIndex in 0..<bytes.count {
            buffer[writeCursor] = bytes[byteIndex]
            writeCursor += 1
        }
        if writeCursor > length {
            length = writeCursor
        }
    }
    
    func readData() -> Data? {
        if let count = readInt64() {
            let count = Int(count)
            if count >= 0 && count < 4_294_967_295 {
                if (readCursor + count) <= length {
                    var bytes = [UInt8](repeating: 0, count: Int(count))
                    for byteIndex in 0..<count {
                        bytes[byteIndex] = buffer[readCursor]
                        readCursor += 1
                    }
                    return Data(bytes)
                }
            }
        }
        return nil
    }
    
    func reserveCapacity(minimumCapacity: Int) {
        if minimumCapacity > capacity {
            buffer.reserveCapacity(minimumCapacity)
            while buffer.count < minimumCapacity {
                buffer.append(0)
            }
            capacity = minimumCapacity
        }
    }
    
    func removeAll(keepingCapacity: Bool) {
        if keepingCapacity == false {
            buffer.removeAll(keepingCapacity: false)
            capacity = 0
        }
        length = 0
        readCursor = 0
        writeCursor = 0
    }
    
    func save(filePath: String?) {
        let fileData: Data
        if length == capacity {
            fileData = Data(buffer)
        } else {
            var bufferBuffer = [UInt8](repeating: 0, count: length)
            for index in 0..<length {
                bufferBuffer[index] = buffer[index]
            }
            fileData = Data(bufferBuffer)
            bufferBuffer.removeAll()
        }
        _ = save(data: fileData, filePath: filePath)
    }
    
    func load(data: Data) {
        clear()
        self.buffer = [UInt8](data)
        self.length = self.buffer.count
        self.capacity = self.buffer.count
    }
    
    func load(filePath: String?) {
        clear()
        if let fileData = load(filePath) {
            let bufferBuffer = [UInt8](fileData)
            if bufferBuffer.count > capacity {
                reserveCapacity(minimumCapacity: bufferBuffer.count)
            }
            for index in 0..<bufferBuffer.count {
                buffer[index] = bufferBuffer[index]
            }
            length = bufferBuffer.count
        }
    }
    
    private func save(data: Data?, filePath: String?) -> Bool {
        if let path = filePath, let data = data {
            do {
                try data.write(to: URL(fileURLWithPath: path), options: .atomicWrite)
                return true
            } catch {
                do {
                    let url = URL(fileURLWithPath: path).deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
                } catch let directoryError {
                    print(directoryError.localizedDescription)
                }
                do {
                    let url = URL(fileURLWithPath: path)
                    try data.write(to: url)
                } catch let secondaryFileError {
                    print(secondaryFileError.localizedDescription)
                }
            }
        }
        return false
    }
    
    private func load(_ filePath: String?) -> Data? {
        if let path = filePath {
            do {
                let fileURL = URL(fileURLWithPath: path)
                let result = try Data(contentsOf: fileURL)
                return result
            } catch {
                print("Unable to load data [\(path)]")
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
