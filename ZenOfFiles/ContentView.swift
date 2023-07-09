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

    @State private var selection: String? = ""
    @State var findDuplicatesConfigurationSettings = FindDuplicatesConfigurationSettings()
    @State private var order: [KeyPathComparator<FileInfo>] = [
        .init(\.id, order: SortOrder.forward),
    ]

    let name = "Configuration"

    var body: some View {
        HStack {
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
                    Button("Quit") {
                        exit(0)
                    }

                    Button("Find Duplicates") {
                        Task {
                            await findDuplicateFiles(config: findDuplicatesConfigurationSettings, dupList: duplicates)
                        }
                    }.disabled(findDuplicatesConfigurationSettings.selectedDirectory == nil)
                }

            }.formStyle(.grouped)

            OutputConsoleView()
        }  
    }
}

