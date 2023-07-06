//
//  ContentView.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/5/23.
//

import CoreData
import SwiftUI
import UniformTypeIdentifiers


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

class FoundDuplicates: ObservableObject {
    @Published var list: [FileInfo] = []
}

struct ContentView: View {
    @StateObject var duplicates = FoundDuplicates()

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
    }
}

struct SelectDirectory: View {
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
    @EnvironmentObject var duplicates: FoundDuplicates

    @State private var selection: String? = ""

    @State var findDuplicatesConfigurationSettings = FindDuplicatesConfigurationSettings()

    @State private var order: [KeyPathComparator<FileInfo>] = [
        .init(\.id, order: SortOrder.forward),
    ]

    let name = "Configuration"

    var body: some View {
        Form {
            SelectDirectory(selectedDirectory: $findDuplicatesConfigurationSettings.selectedDirectory)

            Toggle("look into sub directories", isOn: $findDuplicatesConfigurationSettings.useSubdirs)
                .toggleStyle(.switch)

            Toggle("use checksum (slow but 100% accurate)", isOn: $findDuplicatesConfigurationSettings.useChecksum)
                .toggleStyle(.switch)

            Toggle("use file name", isOn: $findDuplicatesConfigurationSettings.useFileName)
                .toggleStyle(.switch)

            Toggle("use file size", isOn: $findDuplicatesConfigurationSettings.useFileSize)
                .toggleStyle(.switch)

            Toggle("create delete script", isOn: $findDuplicatesConfigurationSettings.createDeleteFileScript)
                .toggleStyle(.switch)

            Toggle("delete by", isOn: $findDuplicatesConfigurationSettings.deleteFiles)
                .toggleStyle(.switch)

            VStack {
                Text("Output")
                ConsoleView().environmentObject(duplicates)
            }

            HStack {
                Button("Quit") {
                    exit(0)
                }
                Spacer()
                Button("Find Duplicates") {
                    Task {
                        await findDuplicates(config: findDuplicatesConfigurationSettings, dupList:duplicates)
                    }
                }.disabled(findDuplicatesConfigurationSettings.selectedDirectory == nil)
            }

        }.formStyle(.grouped) // end form
    }
} // end of FindDuplicationConfigurationView


struct ConsoleView: View {
    
    @State private var count = 0
    @State private var selection: String? = ""
    @EnvironmentObject var duplicates: FoundDuplicates
    
    @State var findDuplicatesConfigurationSettings = FindDuplicatesConfigurationSettings()

    @State private var order = [KeyPathComparator(\FileInfo.id)]

    var body: some View {
        HStack {
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

        }.padding(10)

        Table(selection: $selection, sortOrder: $order) {
            //   TableColumn("Id", value: \.id)
            TableColumn("Name", value: \.name)
            TableColumn("Path", value: \.path) { Text($0.path) }
            TableColumn("URL", value: \.url) { Text($0.url) }
            TableColumn("Checksum", value: \.checksum) { Text("\($0.checksum)") }
            TableColumn("Date Created", value: \.dateCreated) { Text("\($0.dateCreated)") }
            TableColumn("Date Modified", value: \.dateModified) { Text("\($0.dateModified)") }
            TableColumn("Size", value: \.size) { Text("\($0.size)") }
        } rows: {
            ForEach(duplicates.list) { duplicate in
                TableRow(duplicate)
                    .contextMenu {
                        Button("Copy") {
                            print(duplicate)
                    
                        }
                    }
            }
        }.onChange(of: order) { newOrder in
            duplicates.list.sort(using: newOrder)
        }
    }
}

func copyMe(fileInfo: FileInfo) {
    print(fileInfo)
}

struct OrganizeFilesConfigurationView: View {
    @State var selectedDirectory: URL?
    var body: some View {
        SelectDirectory(selectedDirectory: $selectedDirectory)
    }
}
