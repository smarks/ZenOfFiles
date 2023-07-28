//
//  OrganizeFilesConfigurationView.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/27/23.
//
import SwiftUI

/**
 * For Organize Files Funcationality - ui not started yet.
 */
struct OrganizeFilesConfigurationView: View {
    @State var startingBaseDirectory: URL?
    @State var destinationBaseDirectory: URL?

    @State var organizeFilesConfiguration = OrganizeFilesConfigurationSettings()
    @State private var selection: String? = ""
    @State private var order: [KeyPathComparator<FileInfo>] = [
        .init(\.id, order: SortOrder.forward),
    ]

    // Cancellation context for the task
    @State private var isCancelled = false
    @State private var taskRunning = false
    @StateObject var timerManager = TimerManager()

    var body: some View {
        Form {
            OrganizeFileControlPanel(timerManager: timerManager)

            SelectDirectory(selectedDirectory: $organizeFilesConfiguration.startingBaseDirectory,
                            buttonLabel: "Select Starting Directory", directoryLabel: "Starting Directory:").padding(.trailing)

            SelectDirectory(selectedDirectory: $organizeFilesConfiguration.destinationBaseDirectory, buttonLabel: "Select Destination Directory", directoryLabel: "Destination Directory:").padding(.trailing)

            Toggle("Include Sub Directories", isOn: $organizeFilesConfiguration.traverse_subdirectories)
                .toggleStyle(.checkbox)
                .padding(.trailing)

            Toggle("Don't move files, copy them", isOn: $organizeFilesConfiguration.keepOrignals)
                .toggleStyle(.checkbox)
                .padding(.trailing)

            HStack {
                Button("Stop") {
                    // exit(0)
                    isCancelled = true
                    timerManager.stopTimer()
                }.disabled(!taskRunning)

                Button("Start") {
                    Task {
                        isCancelled = false
                        taskRunning = true
                        timerManager.startTimer()
                        await orgainizeFiles(config: organizeFilesConfiguration, isCancelled: $isCancelled)
                        taskRunning = false
                    }
                }.disabled(organizeFilesConfiguration.destinationBaseDirectory == nil
                    ||
                    taskRunning
                    ||
                    organizeFilesConfiguration.startingBaseDirectory == nil
                )
            }

        }.formStyle(.grouped)
    }
}

struct OrganizeFileControlPanel: View {
    @EnvironmentObject var duplicates: FoundFiles
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        HStack {
            /*
             // top of table 'control panel'
             Button {
                 print("Copy \(duplicates.list.count)")

             } label: {
                 Image(systemName: "square.and.arrow.down")
             }

             Button {
                 print("Save \(duplicates.list.count)")
                 for item in duplicates.list {
                     print(item)
                 }
             } label: {
                 Image(systemName: "doc.on.doc")
             }
              */
            //  Text("File Count: \(duplicates.list.count)")
            TimerDisplayView(timerManager: timerManager)
        }
    }
}

struct OrganizeFilesConfigurationSettings {
    var id = UUID()
    var traverse_subdirectories: Bool = false
    var startingBaseDirectory: URL?
    var destinationBaseDirectory: URL?
    var keepOrignals: Bool = false
}