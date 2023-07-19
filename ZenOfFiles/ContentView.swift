//
//  ContentView.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/5/23.
//

import CoreData
import SwiftUI
import UniformTypeIdentifiers

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
         
            list.insert(fileInfo, at:location)
        
    }

    @Published var totalFiles = Float(0.0)

    func totalFiles(_ totalFiles: Float) {
        self.totalFiles = totalFiles
    }
}

/**
 * show tabs for each peice of discrect funtionality
 */
struct ContentView: View {
    @StateObject var duplicates = FoundFiles()

    var body: some View {
        TabView {
            FindDuplicationConfigurationView()
                .tabItem {
                    Label("Find Duplicates", systemImage: "circle")
                }
                .environmentObject(duplicates)

            OrganizeFilesConfigurationView()
                .tabItem {
                    Label("Organize Files", systemImage: "circle")
                }
        }
        .padding(15)
    }
}

struct SelectDirectory: View {
    /**
     * View for selecting a directory
     */
    @Binding var selectedDirectory: URL?

    var body: some View {
        HStack {
            Button("Select Directory", action: {
                let dialog = NSOpenPanel()
                dialog.title = "Select a Directory"
                dialog.canChooseFiles = false
                dialog.canChooseDirectories = true
                dialog.allowsMultipleSelection = false
                dialog.directoryURL = selectedDirectory

                if dialog.runModal() == .OK {
                    selectedDirectory = dialog.url
                }
            })

            Spacer()

            if let directory = selectedDirectory {
                Text("Selected Directory: \(directory.path)")
            }
        }
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
                SelectDirectory(selectedDirectory: $findDuplicatesConfigurationSettings.selectedDirectory)
                
                Toggle("look into sub directories", isOn: $findDuplicatesConfigurationSettings.useSubdirs)
                    .toggleStyle(.switch)
                    .padding(10)
                
                Toggle("use checksum(slow but 100% accurate)", isOn: $findDuplicatesConfigurationSettings.useChecksum)
                    .toggleStyle(.switch)
                    .padding(10)
                
                Toggle("use file name", isOn: $findDuplicatesConfigurationSettings.useFileName)
                    .toggleStyle(.switch)
                    .padding(10)
                
                Toggle("use file size", isOn: $findDuplicatesConfigurationSettings.useFileSize)
                    .toggleStyle(.switch)
                    .padding(10)
                
                Toggle("create delete script", isOn: $findDuplicatesConfigurationSettings.createDeleteFileScript)
                    .toggleStyle(.switch)
                    .padding(10)
                
                Toggle("delete by", isOn: $findDuplicatesConfigurationSettings.deleteFiles)
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
                    }.disabled(findDuplicatesConfigurationSettings.selectedDirectory == nil || taskRunning )
                }
                
            }.formStyle(.grouped)
            
            OutputConsoleView(timerManager: timerManager)
        }
    }
}
 
/**
 * For Organize Files Funcationality - ui not started yet.
 */
struct OrganizeFilesConfigurationView: View {
    @State var selectedDirectory: URL?
    var body: some View {
//        SelectDirectory(selectedDirectory: $selectedDirectory)
        Label("Nothing here are at the moment, please come back later", systemImage: "figure.mind.and.body")
            .font(.title)
    }
}
       
 
