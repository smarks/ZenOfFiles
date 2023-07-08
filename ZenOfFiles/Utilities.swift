//
//  Utilities.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/5/23.
//

import SwiftUI

import CommonCrypto
import Foundation
import UniformTypeIdentifiers

import ImageIO

func hasAllowedExtension(fileURL: URL, allowedExtensions: [String]) -> Bool {
    let ext = fileURL.pathExtension.lowercased()
    let status = allowedExtensions.contains(ext)
    return status
}

func copyFile(at sourceURL: URL, to destinationURL: URL) throws {
    let fileManager = FileManager.default

    // Create the destination directory if it does not already exist
    try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(),
                                    withIntermediateDirectories: true,
                                    attributes: nil)

    // Copy the file to the destination
    try fileManager.copyItem(at: sourceURL, to: destinationURL)
}

func getSha256Checksum(forFileAtPath path: URL) throws -> String? {
    // Open the file for reading
    print("opening: \(path)")
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

func isBigEnough(fileURL: URL, fileManager: FileManager) throws -> Bool {
    return true

    let fileAttribute = try fileManager.attributesOfItem(atPath: fileURL.absoluteURL.path)
    let fileSize = fileAttribute[FileAttributeKey.size] as! Int64
    //        let fileSizeMB = Double(fileSize) / (1024 * 1024)
    let minKbFileSze: Int64 = 299 * 1024 // 299 in bytes
    if fileSize < minKbFileSze {
        //            print("File size is less than 299kb, skipping: " + fileURL.path)
        return false
    }

    return true
}

func getDateFromFileURL(fileURL: URL) throws -> Date? {
    // Attempt to get the exif data
    guard let exifData = getExifData(from: fileURL) else {
        // If getting the exif data fails, attempt to get the file creation date
        return try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.creationDate] as? Date
    }

    // Attempt to get the digitized date from the exif data
    guard let digitizedDateString = exifData["DateTimeDigitized"] as? String else {
        // If the digitized date doesn't exist in the exif data, use the file creation date
        return try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.creationDate] as? Date
    }

    // Parse the digitized date string using a date formatter
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
    guard let digitizedDate = dateFormatter.date(from: digitizedDateString) else {
        // If parsing the digitized date string fails, use the file creation date
        return try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.creationDate] as? Date
    }

    // Return the digitized date if it exists, or the file creation date if not
    return digitizedDate
}

func getDateComponents(fileURL: URL, fileManager: FileManager) throws -> Array<String> {
    let date = try getDateFromFileURL(fileURL: fileURL) ?? Date()
    let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return [String(dateComponents.year!), String(dateComponents.month!), String(dateComponents.day!)]
}

func getFileDestination(fileURL: URL, destinationBase: URL, fileManager: FileManager) throws -> URL {
    let fileName = fileURL.lastPathComponent
    let dateComponents = try getDateComponents(fileURL: fileURL, fileManager: fileManager)
    let destination = dateComponents.reduce(destinationBase) { $0.appendingPathComponent($1) }.appendingPathComponent(fileName).path
    return URL(fileURLWithPath: destination)
}

func areFilesTheSame(destinationURL: URL, incoming_file_checksum: String) throws -> Bool {
    // is it the same?
    let checksum_of_existing_file = try getSha256Checksum(forFileAtPath: destinationURL)
    if checksum_of_existing_file == incoming_file_checksum {
        return true
    } else {
        return false
    }
}

func getNewName(fileURL: URL, destinationURL: URL, incoming_file_checksum: String) -> URL {
    let fileName = fileURL.lastPathComponent
    let newFileName = "\(incoming_file_checksum)_\(fileName)"
    return destinationURL.deletingLastPathComponent().appendingPathComponent(newFileName)
}

func processFile(fileURL: URL, destinationBase: URL, fileManager: FileManager, existing_files_checksum: inout Set<String>) throws {
    if let incoming_file_checksum = try getSha256Checksum(forFileAtPath: fileURL) {
        if existing_files_checksum.contains(incoming_file_checksum) == false {
            existing_files_checksum.insert(incoming_file_checksum)
            do {
                // construct the file path with date
                var destinationURL = try getFileDestination(fileURL: fileURL, destinationBase: destinationBase, fileManager: fileManager)

                // if a file already exists with the same name and same checksum value, we are done here
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    let areTheyTheSame = try? areFilesTheSame(destinationURL: destinationURL, incoming_file_checksum: incoming_file_checksum)
                    if areTheyTheSame == true {
                        return
                    }
                }

                // otherwise append checksum file to filename
                destinationURL = getNewName(fileURL: fileURL, destinationURL: destinationURL, incoming_file_checksum: incoming_file_checksum)

                // now see if new name is already there and if so nothing left to do...
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    return
                }

                // finally, if get here, copy the file
                try copyFile(at: fileURL, to: destinationURL)
                print("copied " + fileURL.path + " to " + destinationURL.path)

            } catch {
                print("Error copying file: \(error)")
            }
        }
    }
}

func checkForDuplicates(fileURL: URL,
                        fileManager: FileManager,
                        existing_files_checksum: inout [String: String],
                        listOfDuplicates: inout ItemList
) throws {
    if let checksum = try getSha256Checksum(forFileAtPath: fileURL) {
        if existing_files_checksum[checksum] != nil {
            // this keeps the longer file name
            print("# " + fileURL.absoluteString + " is a duiplicate of " + existing_files_checksum[checksum]!)
            print("rm " + fileURL.absoluteString)
            let identifiableFoundDuplicate = IdentifiableFoundDuplicate(identifier: checksum,
                                                                        name: fileURL.absoluteString,
                                                                        path: fileURL.absoluteString,
                                                                        url: fileURL.absoluteString,
                                                                        checksum: checksum,
                                                                        dateCreated: Date(),
                                                                        dateModified: Date(),
                                                                        size: 100)
            listOfDuplicates.list.append(identifiableFoundDuplicate)

        } else {
            existing_files_checksum[checksum] = fileURL.path
        }
    }
}

func catalogFiles(fileURL: URL, fileManager: FileManager) throws {
    if let checksum = try getSha256Checksum(forFileAtPath: fileURL) {
        let fileAttribute = try fileManager.attributesOfItem(atPath: fileURL.absoluteURL.path)
        let fileSize = fileAttribute[FileAttributeKey.size] as! Int64
        let filePath = fileURL.absoluteURL.path
        let fileName = fileURL.lastPathComponent
        if fileName.starts(with: ".") {
            return
        }
        print(fileName + ", " + filePath + ", " + String(fileSize) + ", " + checksum)
    }
}

func isDirectory(fileManager: FileManager, url: URL) -> Bool {
    var isDir: ObjCBool = false
    if fileManager.fileExists(atPath: url.path, isDirectory: &isDir) {
        return isDir.boolValue
    } else {
        return false
    }
}

func getExifData(from url: URL) -> [String: Any]? {
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        // print("Error: could not create image source from URL")
        return nil
    }

    guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
        // print("Error: could not get properties from image source")
        return nil
    }

    guard let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] else {
        // print("Error: could not get Exif metadata from properties")
        return nil
    }

    return exif
}

func findDuplicateFiles(config: FindDuplicatesConfigurationSettings, dupList: FoundDuplicates) async {
    let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey])
    var existingFilesChecksumMap: [String: String] = [:]
    var existingFilesChecksumSet = Set<String>()
    let fileManager = FileManager.default
    let destinationBase = config.selectedDirectory
    var count = 1

    if let startingBase = config.selectedDirectory {
        let urlResourceKeyArray = Array(resourceKeys)
        let directoryEnumerator = fileManager.enumerator(at: startingBase, includingPropertiesForKeys: urlResourceKeyArray, options: .skipsHiddenFiles)!

        for case let fileURL as URL in directoryEnumerator {
            // if hasAllowedExtension(fileURL: fileURL, allowedExtensions: image_extensions), let bigEnough = try? isBigEnough(fileURL: fileURL, fileManager: fileManager), bigEnough {
            do {
               
                if isDirectory(fileManager: fileManager, url: fileURL) == false {
                    let checksumValue = try getSha256Checksum(forFileAtPath: fileURL)
                    let fileAttribute = try fileManager.attributesOfItem(atPath: fileURL.absoluteURL.path)
                    let fileSize = fileAttribute[FileAttributeKey.size] as! Int64
                    
                    let fileInfo = try FileInfo(id: UUID().uuidString,
                                                name: fileURL.lastPathComponent,
                                                path: fileURL.path,
                                                url: fileURL.absoluteString,
                                                checksum: "\(checksumValue!)",
                                                dateModified: Date(),
                                                dateCreated: Date(),
                                                size: fileSize)
                    
                    await dupList.append(fileInfo)
                    count = count + 1
                }
            } catch {
                print("Error processing file at \(fileURL): \(error)")
            }
        }
    }
}

func findDuplicates(config: FindDuplicatesConfigurationSettings, dupList: FoundDuplicates) async {
    let image_extensions = ["raw",
                            "heic",
                            "heif",
                            "jpeg",
                            "jpg",
                            "dng",
                            "png",
                            "gif",
                            "tiff",
                            "tif",
                            "cr2",
                            "cr3",
                            "dng",
                            "eps",
                            "bmp",
                            "psd",
                            "svg",
                            "mov"]
    let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey])
    var existingFilesChecksumMap: [String: String] = [:]
    var existingFilesChecksumSet = Set<String>()
    let fileManager = FileManager.default
    let destinationBase = config.selectedDirectory
    var count = 1

    if let startingBase = config.selectedDirectory {
        let urlResourceKeyArray = Array(resourceKeys)
        let directoryEnumerator = fileManager.enumerator(at: startingBase, includingPropertiesForKeys: urlResourceKeyArray, options: .skipsHiddenFiles)!

        for case let fileURL as URL in directoryEnumerator {
            if hasAllowedExtension(fileURL: fileURL, allowedExtensions: image_extensions), let bigEnough = try? isBigEnough(fileURL: fileURL, fileManager: fileManager), bigEnough {
                do {
                    let fileInfo = try FileInfo(id: "\(count)",
                                                name: "fileURL.absoluteString",
                                                path: "fileURL.absoluteString",
                                                url: "fileURL.absoluteString",
                                                checksum: "checksum",
                                                dateModified: Date(),
                                                dateCreated: Date(),
                                                size: 100)
                    await dupList.append(fileInfo)
                    count = count + 1

                } catch {
                    print("Error processing file at \(fileURL): \(error)")
                }
            }
        }
    }

    //
    //  if let startingBase = URL(string: "file:///Volumes/photos_1") {
    //
    //      let urlResourceKeyArray = Array(resourceKeys)
    //      let directoryEnumerator = fileManager.enumerator(at: startingBase, includingPropertiesForKeys: urlResourceKeyArray, options: .skipsHiddenFiles)!

    //      for case let fileURL as URL in directoryEnumerator {
    //
    //          if hasAllowedExtension(fileURL:fileURL, allowedExtensions:image_extensions), let bigEnough = try? isBigEnough(fileURL: fileURL,fileManager:fileManager), bigEnough {
    //              do {
    //                  try checkForDuplicates(fileURL: fileURL,  fileManager: fileManager,  existing_files_checksum: &existingFilesChecksumMap)
    //                  //print(count)
    //                  count = count + 1
    //              } catch {
    //                  print("Error processing file at \(fileURL): \(error)")
    //              }
    //          }
    //      }
    //  }
}
