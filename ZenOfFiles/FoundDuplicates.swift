//
//  FoundDuplicates.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/27/23.
//

import Foundation
import SwiftUI

/**
   List of files found by application using specified config values
 */
@MainActor
class FoundFiles: ObservableObject {
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
}

struct FindDuplicationConfigurationView: View {
    @EnvironmentObject var duplicates: FoundFiles
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
                    SelectDirectory(selectedDirectory: $findDuplicatesConfigurationSettings.selectedDirectory, buttonLabel: "Select Starting Directory")
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
                            await findDuplicateFiles(config: findDuplicatesConfigurationSettings, dupList: duplicates, isCancelled: $isCancelled)
                            taskRunning = false
                        }
                    }.disabled(findDuplicatesConfigurationSettings.selectedDirectory == nil || taskRunning)
                }

            }.formStyle(.grouped)

            OutputConsoleView(timerManager: timerManager)
        }
    }
}

