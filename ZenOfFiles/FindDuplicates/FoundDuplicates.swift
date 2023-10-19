//
//  FoundDuplicates.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/27/23.
//

import Foundation
import SwiftUI

//@MainActor
struct FindDuplicationConfigurationView: View {
    @EnvironmentObject var duplicates: DuplicateFiles
    @State var findDuplicatesConfigurationSettings = FindDuplicatesConfigurationSettings()
    @State private var selection: String? = ""
    @State private var order: [KeyPathComparator<FileInfo>] = [
        .init(\.id, order: SortOrder.forward),
    ]

    // Cancellation context for the task
    @State private var isCancelled = false
    @State private var taskRunning = false
    @StateObject var timerManager = TimerManager()

    var body: some View {
        HSplitView {
            Form {
                HStack {
                    SelectDirectory(selectedDirectory: $findDuplicatesConfigurationSettings.selectedDirectory, buttonLabel: "Select Starting Directory", directoryLabel: "Starting Directory")
                }
                Toggle("Look into sub directories", isOn: $findDuplicatesConfigurationSettings.traverse_subdirectories)
                    .toggleStyle(.switch)
                    .padding(10)

                Toggle("Use checksum(slow but 100% accurate)", isOn: $findDuplicatesConfigurationSettings.useChecksum)
                    .toggleStyle(.switch)
                    .padding(10)

                Toggle("Use file name", isOn: $findDuplicatesConfigurationSettings.useFileName)
                    .toggleStyle(.switch)
                    .padding(10)

                Toggle("Use file size", isOn: $findDuplicatesConfigurationSettings.useFileSize)
                    .toggleStyle(.switch)
                    .padding(10)

                Toggle("Create delete script", isOn: $findDuplicatesConfigurationSettings.createDeleteFileScript)
                    .toggleStyle(.switch)
                    .padding(10)

                Toggle("Delete by", isOn: $findDuplicatesConfigurationSettings.deleteFiles)
                    .toggleStyle(.switch)
                    .padding(10)

                HStack {
                    Button("Stop") {
                        // exit(0)
                        isCancelled = true
                        timerManager.stopTimer()
                    }.disabled(!taskRunning)

                    Button("Start") {
                        duplicates.list = []
                        Task {
                            isCancelled = false
                            taskRunning = true
                            timerManager.startTimer()
                          //  await findDuplicateFiles(config: findDuplicatesConfigurationSettings, dupList: duplicates, isCancelled: isCancelled)
                            taskRunning = false
                        }
                    }.disabled(findDuplicatesConfigurationSettings.selectedDirectory == nil || taskRunning)
                }

            }.formStyle(.grouped)

            OutputConsoleView(timerManager: timerManager)
        } 
    }
}


/**
 * Main entry point for finding dupilicate files.
 */
func findDuplicateFiles(config: FindDuplicatesConfigurationSettings, dupList: DuplicateFiles, isCancelled: Binding<Bool>) async {
    let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey])
    let fileManager = FileManager.default
    var filesCatalog: [String: FileInfo] = [:]
    var fileSizes: [Int64: [String]] = [:]
    var fileNames: [String: [String]] = [:]
    var fileChecksums: [String: [String]] = [:]
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

                    dupList.insert(fileInfo, location: 0)
                }
            } catch {
                print("Error processing file at \(fileURL): \(error)")
            }
        }
    }
}
