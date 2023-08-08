//
//  Models.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/5/23.
//

import Foundation

enum FileSizes: String, CaseIterable,Identifiable {
    var id: Self { self }

    
    case KB = "KiloBytes"
    case MB = "MegaBytes"
    case GB = "GigaBytes"
}

enum FileTypes: String, CaseIterable,Identifiable {
    var id: Self { self }

    case DEFAULT = "All"
    case TXT = "Text"
    case IMAGE = "Image"
    case VIDEO = "Video"
}

struct FileInfo: Identifiable {
    let id: String
    let name: String
    let path: String
    let url: String
    let checksum: String
    let dateModified: Date
    let dateCreated: Date
    let size: Int64
}

struct FindDuplicatesConfigurationSettings {
    var id = UUID()
    var traverse_subdirectories: Bool = false
    var useChecksum: Bool = false
    var useFileName: Bool = false
    var useFileSize: Bool = false
    var createDeleteFileScript: Bool = false
    var deleteFiles: Bool = false
    var selectedDirectory: URL?
}

enum DeleteBy: String, CaseIterable, Hashable, Identifiable  {
    var id: Self { self }

    case oldest = "Oldest"
    case newest = "Newest"
}

enum NoFiles: Error {
    case noCurrentFile(String)
}

/**
   List of files found by application using specified config values
 */
@MainActor
class DuplicateFiles: ObservableObject {
    @Published var list: [FileInfo] = []

    func append(_ fileInfo: FileInfo) {
        list.append(fileInfo)
    }

    func insert(_ fileInfo: FileInfo, location: Int) {
        list.insert(fileInfo, at: location)
    }

    @Published var totalFiles = Float(0.0)

    func totalFiles(_ totalFiles: Float) {
        self.totalFiles = totalFiles
    }

    func getCurrentFile() throws -> FileInfo {
        if let lastElement = list.last {
            return lastElement
        } else {
            throw NoFiles.noCurrentFile("There's no current file; totalFiles() before calling me.")
        }
    }
}

/**
   List of files found by application using specified config values
 */
@MainActor
class ProcessedFiles: ObservableObject {
    @Published var list: [URL] = []
    @Published var messages: [String] = []

    func append(_ fileInfo: URL) {
        list.append(fileInfo)
    }

    func insert(_ fileInfo: URL, location: Int) {
        list.insert(fileInfo, at: location)
    }

    @Published var totalFiles = Float(0.0)

    func totalFiles(_ totalFiles: Float) {
        self.totalFiles = totalFiles
    }

    func hasErrors() -> Bool {
        return messages.isEmpty
    }

    func appendMessage(_ message: String) {
        messages.append(message)
    }
}



class OrganizeFilesSettings : ObservableObject {
    @Published var id = UUID()
    @Published var traverse_subdirectories: Bool = false
    @Published var startingBaseDirectory: URL?
    @Published var destinationBaseDirectory: URL?
    @Published var keepOrignals: Bool = false
    @Published var filter: Bool = false
    @Published var filterByTypes: Bool = false
    @Published var filterBySize: Bool = false
    @Published var maxFileSizeUnits = FileSizes.MB
    @Published var minFileSizeUnits = FileSizes.MB
    @Published var filterByDate: Bool = false
    @Published var beforeDateActive: Bool = false
    @Published var startDate: Date = Date.now
    @Published var endDateActive: Bool = false
    @Published var endDate: Date = Date.now
    @Published var minFileSizeActive: Bool = false
    @Published var maxFileSizeActive: Bool = false
    @Published var minFileSize: Int64 = 0
    @Published var maxFileSize: Int64 = 0
    @Published var filterByFileTypes: [FileTypes] = [FileTypes.DEFAULT]
    @Published var fileType: FileTypes = FileTypes.DEFAULT

    @Published var groupByDay: Bool = false
    @Published var groupByMonth: Bool = false
    @Published var groupByYear: Bool = false
    @Published var overSameNamedFiles: Bool = false

    @Published var useFileType: Bool = false
    @Published var useFileExtension: Bool = false
    @Published var skipFIlesWithoutExtensions: Bool = false
}
