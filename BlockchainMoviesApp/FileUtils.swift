//
//  FileUtils.swift
//  BlockchainMoviesApp
//
//  Created by Nicky Taylor on 4/9/24.
//

import UIKit

final class FileUtils {
    
    static let shared = FileUtils()
    
    lazy var mainBundleDirectory: String = {
        guard let resourcePath = Bundle.main.resourcePath else {
            return "c://"
        }
        var result = resourcePath
        result = result + "/"
        return result
    }()
    
    lazy var documentDirectory: String = {
        let directories = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard directories.count > 0 else {
            return "c://"
        }
        var result = directories[0]
        result = result + "/"
        return result
    }()
    
    func getDocumentPath(fileName: String?) -> String {
        var result = documentDirectory
        if let fileName = fileName {
            result = result + fileName
        }
        return result
    }
    
    func getMainBundleFilePath(fileName: String?) -> String {
        var result = mainBundleDirectory
        if let fileName = fileName {
            result = result + fileName
        }
        return result
    }
    
    func fileExists(_ filePath: String?) -> Bool {
        if let filePath = filePath {
            return FileManager.default.fileExists(atPath: filePath)
        }
        return false
    }
    
    func fileExists(_ url: URL?) -> Bool {
        if let url = url {
            return FileManager.default.fileExists(atPath: url.absoluteString)
        }
        return false
    }
    
    @discardableResult
    func save(data: Data?, filePath: String?) -> Bool {
        if let path = filePath, let data = data {
            do {
                try data.write(to: URL(fileURLWithPath: path), options: .atomicWrite)
                return true
            } catch {
                do {
                    let url = URL(fileURLWithPath: path).deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
                } catch let directoryError {
                    print("Saving Data To Path, Create Directory Error: {\(path)}")
                    print("ERROR!")
                    print(directoryError.localizedDescription)
                }
                do {
                    let url = URL(fileURLWithPath: path)
                    try data.write(to: url)
                } catch let secondaryFileError {
                    print("Secondary Saving Data To Path Error: {\(path)}")
                    print("ERROR!")
                    print(secondaryFileError.localizedDescription)
                }
            }
        }
        return false
    }
    
    func load(_ filePath: String?) -> Data? {
        if let path = filePath {
            
            do {
                let fileURL: URL
                if #available(iOS 16.0, *) {
                    fileURL = URL(filePath: path)
                } else {
                    // Fallback on earlier versions
                    fileURL = URL(fileURLWithPath: path)
                }
                let result = try Data(contentsOf: fileURL)
                return result
            } catch {
                print("Unable to load data [\(path)]")
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func saveImagePNG(image: UIImage?, filePath: String?) -> Bool {
        if image != nil {
            if let imageData = image?.pngData() {
                if save(data: imageData, filePath: filePath) {
                    return true
                }
            }
        }
        return false
    }
    
    func deleteFile(_ filePath: String?) -> Void {
        if let filePath = filePath {
            do {
                try FileManager.default.removeItem(atPath: filePath)
            } catch {
                print("Unable to delete file [\(filePath)]")
                print(error.localizedDescription)
            }
        }
    }
    
    func deleteFile(_ url: URL?) -> Void {
        if let url = url {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("Unable to delete file [\(url.absoluteString)]")
                print(error.localizedDescription)
            }
        }
    }
    
    @discardableResult
    func savePNG(image: UIImage?, filePath: String?) -> Bool {
        if let filePath = filePath {
            if image != nil {
                if let imageData = image?.pngData() {
                    if save(data: imageData, filePath: filePath) {
                        return true
                    } else {
                        print("Unable to save image (\(image!.size.width)x\(image!.size.height)) [\(filePath)]")
                    }
                } else {
                    print("Unable to save image (\(image!.size.width)x\(image!.size.height)) [\(filePath)]")
                }
            }
        }
        return false
    }
    
    func loadImage(_ filePath: String?) -> UIImage? {
        if let data = load(filePath) {
            return UIImage(data: data)
        }
        return nil
    }
}
