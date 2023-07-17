//
//  Utilities.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/5/23.
//

import CommonCrypto
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

/**
 * Given a list of extension, normalize their case and return true if the provided file has an extension in the list
 */
func hasAllowedExtension(fileURL: URL, allowedExtensions: [String]) -> Bool {
    let ext = fileURL.pathExtension.lowercased()
    let status = allowedExtensions.contains(ext)
    return status
}

/**
  * Copy file creating destination directory if it does not already exist.
 */
func copyFile(at sourceURL: URL, to destinationURL: URL) throws {
    let fileManager = FileManager.default

    // Create the destination directory if it does not already exist
    try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(),
                                    withIntermediateDirectories: true,
                                    attributes: nil)

    // Copy the file to the destination
    try fileManager.copyItem(at: sourceURL, to: destinationURL)
}

/**
  * Checksum a file
 */
func getSha256Checksum(forFileAtPath path: URL) throws -> String? {
    // Open the file for reading
    let file = try FileHandle(forReadingFrom: path)

    // Initialize the SHA-256 context
    var context = CC_SHA256_CTX()
    CC_SHA256_Init(&context)

    // Read the file in chunks and update the context
    let chunkSize = 1024 * 1024 // 1 MB
    while autoreleasepool(invoking: {
        let data = file.readData(ofLength: chunkSize)
        if !data.isEmpty {
            data.withUnsafeBytes {
                _ = CC_SHA256_Update(&context, $0.baseAddress, CC_LONG(data.count))
            }
            return true
        } else {
            return false
        }
    })
    {}

    // Finalize the context and get the checksumt
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    CC_SHA256_Final(&digest, &context)
    let checksum = digest.map { String(format: "%02hhx", $0) }.joined()
    return checksum
}

/**
 * return the file size
 */
func getFileSize(fileURL: URL) throws -> Int64 {
    let fileAttribute = try FileManager.default.attributesOfItem(atPath: fileURL.absoluteURL.path)
    return fileAttribute[FileAttributeKey.size] as! Int64
}
 
/**
  * If the file has exif data return it, otherwise throw.
 */
func getExifData(from url: URL) throws -> [String: Any]? {
    let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)
    let properties = CGImageSourceCopyPropertiesAtIndex(imageSource!, 0, nil) as? [String: Any]
    return properties?[kCGImagePropertyExifDictionary as String] as? [String: Any]
}

func isImage(file:URL) -> Bool {
    return false
}

/**
  * get the files' CREATION date
  * first, by looking at exif data (if it exists)
  * and faling that by asking the FileManager.
 */
func getFileCreationDate(fileURL: URL) throws -> Date? {
   
    if isImage(file: fileURL) {
        do {
            // Attempt to get the exif data
            let exifData = try getExifData(from: fileURL)
            
            // We have exif data, now attempt to get the digitized date from the exif data
            let digitizedDateString = exifData?["DateTimeDigitized"] as! String
            
            // Parse the digitized date string using a date formatter
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            let digitizedDate = dateFormatter.date(from: digitizedDateString)
            
            return digitizedDate
            
        } catch {
            return try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.creationDate] as? Date
        }
    } else {
        return try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.creationDate] as? Date
    }
}

/**
  * Get the date components from a files' creation date.
 */
func getDateComponentsForCreationDate(fileURL: URL) throws -> Array<String> {
    let date = try getFileCreationDate(fileURL: fileURL) ?? Date()
    let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return [String(dateComponents.year!), String(dateComponents.month!), String(dateComponents.day!)]
}

/**
 * Create a file path (path + name) where the component right before the name is a date
 * fileURL:  file://Users/sam/bar.jgp with a creation date of 10/10/21 is passed in as the file.
 * destination: //MyData/photos/
 * The date is determined and then using 'destinationBase' the complete destination path is
 * calculated.
 *
 * final result returned file:///MyData/photos/YYYY/MM/DD/bar.jgp
 */
func getFileDestination(fileURL: URL, destinationBase: URL) throws -> URL {
    let fileName = fileURL.lastPathComponent
    let dateComponents = try getDateComponentsForCreationDate(fileURL: fileURL)
    let destination = dateComponents.reduce(destinationBase) { $0.appendingPathComponent($1) }.appendingPathComponent(fileName).path
    return URL(fileURLWithPath: destination)
}

/**
  * insert checksum into file name and return the new URL
 */
func getNewName(fileURL: URL, destinationURL: URL, incoming_file_checksum: String) -> URL {
    let fileName = fileURL.lastPathComponent
    let newFileName = "\(incoming_file_checksum)_\(fileName)"
    return destinationURL.deletingLastPathComponent().appendingPathComponent(newFileName)
}

/**
  * construct a CSV row from file data.
 */
func catalogFiles(fileURL: URL) throws -> String {
    let checksum = try getSha256Checksum(forFileAtPath: fileURL)
    let fileAttribute = try FileManager.default.attributesOfItem(atPath: fileURL.absoluteURL.path)
    let fileSize = fileAttribute[FileAttributeKey.size] as! Int64
    let filePath = fileURL.absoluteURL.path
    let fileName = fileURL.lastPathComponent

    return "\(fileName), \(filePath),\(String(fileSize)),\(String(describing: checksum))"
}

/**
  * Gee, I wonder what this one does.
 */
func isDirectory(url: URL) -> Bool {
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
        return isDir.boolValue
    } else {
        return false
    }
}

func getNumberOfFiles(startingDirectory: URL)  -> Int {
    var count = 0
    if let enumerator = FileManager.default.enumerator(at: startingDirectory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
        for case let fileURL as URL in enumerator {
            do {
                let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                if fileAttributes.isRegularFile! {
                    count = count + 1
                }
            } catch { print(error, fileURL) }
        }
    }
    return count
}

/**
  * Main entry point for finding dupilicate files.
 */
func findDuplicateFiles(config: FindDuplicatesConfigurationSettings, dupList: FoundFiles, isCancelled: Binding<Bool>) async {

    
    let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey])
    let fileManager = FileManager.default
    var filesCatalog: [String:FileInfo] = [:]
    var fileSizes: [Int64:[String] ] = [:]
    var fileNames: [String:[String] ] = [:]
    var fileChecksums: [String:[String]] = [:]
    let NOT_YET_DETERMINED: String = "NYD"
    var checksumValue: String = NOT_YET_DETERMINED
    
    if let startingBase = config.selectedDirectory {
        
        let urlResourceKeyArray = Array(resourceKeys)
        let directoryEnumerator = fileManager.enumerator(at: startingBase, includingPropertiesForKeys: urlResourceKeyArray, options: .skipsHiddenFiles)!
        
        for case let fileURL as URL in directoryEnumerator {
            if isCancelled.wrappedValue == true {
                return
            }
            // if hasAllowedExtension(fileURL: fileURL, allowedExtensions: image_extensions), let bigEnough = try? isBigEnough(fileURL: fileURL, fileManager: fileManager), bigEnough {
            do {
                if isDirectory(url: fileURL) == false {
                    
                       
                    let fileAttribute = try fileManager.attributesOfItem(atPath: fileURL.absoluteURL.path)
                    let fileSize = fileAttribute[FileAttributeKey.size] as! Int64
                    let modDate = fileAttribute[FileAttributeKey.modificationDate] as! Date
                    let fileInfo = FileInfo(id: UUID().uuidString,
                                            name: fileURL.lastPathComponent,
                                            path: fileURL.path,
                                            url: fileURL.absoluteString,
                                            checksum: "\(checksumValue)",
                                            dateModified: modDate,
                                            dateCreated: try getFileCreationDate(fileURL: fileURL) ?? Date.distantPast,
                                            size: fileSize)
                                        
                    filesCatalog.updateValue(fileInfo, forKey: fileInfo.id)
                   
                    
                    // update checksums
                    if config.useChecksum {
                        checksumValue = try getSha256Checksum(forFileAtPath: fileURL) ?? "ERROR"
                        var sameChecksumList = fileChecksums[checksumValue] ?? []
                        sameChecksumList.append(fileInfo.id)
                        fileChecksums.updateValue(sameChecksumList, forKey: checksumValue)
                    }
                    
                    // update dictionary of files with same size (key: size value: array of files' UUID as String who have same size)
                    var sameFileSizesList = fileSizes[fileSize] ?? []
                    sameFileSizesList.append(fileInfo.id)
                    fileSizes.updateValue(sameFileSizesList, forKey: fileSize)
                                           
                    // update dictionary of files by name (key: filename value: array of files' UUID as String who have same id
                    var sameFileNameList = fileNames[fileInfo.name] ?? []
                    sameFileNameList.append(fileInfo.id)
                    fileNames.updateValue(sameFileNameList, forKey: fileInfo.name)
                    
                   
                        await dupList.insert(fileInfo, location: 0)
                    
                }
            } catch {
                print("Error processing file at \(fileURL): \(error)")
            }
        }
    }
    
}
