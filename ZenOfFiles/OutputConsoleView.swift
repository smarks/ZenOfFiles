//
//  OutputConsoleView.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/9/23.
//

import Foundation

import CoreData
import SwiftUI
import UniformTypeIdentifiers

/**
 * icons on top row of table for saving, copying etc.
 */
struct ControlPanel : View  {
    @EnvironmentObject var duplicates: FoundFiles

    var body: some View {
        
        HStack {
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
        }
    }
}

/**
  * Table the shows found files
 */
struct OutputConsoleView: View {
    @State private var count = 0
    @State private var selection: String? = ""
    @EnvironmentObject var duplicates: FoundFiles
    private let pastboard = NSPasteboard.general

    @State var findDuplicatesConfigurationSettings = FindDuplicatesConfigurationSettings()

    @State private var order = [KeyPathComparator(\FileInfo.id)]

    var body: some View {
        VStack {
           ControlPanel()

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
                                // "right click" in table functionality.
                                pastboard.setString(duplicate.path, forType: .string)
                                print("right click for \(duplicate)")
                            }
                        }
                }
            }.onChange(of: order) { newOrder in
                duplicates.list.sort(using: newOrder)
            }
        }.padding(10)
    }
}


 
/**
 * For Organize Files Funcationality - ui not started yet.
 */
struct OrganizeFilesConfigurationView: View {
    @State var selectedDirectory: URL?
    var body: some View {
        SelectDirectory(selectedDirectory: $selectedDirectory)
    }
}
