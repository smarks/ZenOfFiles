//
//  ContentView.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/5/23.
//

import CoreData
import SwiftUI

/**
 * show tabs for each peice of discrect funtionality
 */
struct ContentView: View {
    @StateObject var duplicates = DuplicateFiles()
    @StateObject var processedFiles = ProcessedFiles()

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
                }.environmentObject(processedFiles)
        }
        .padding(15)
    }
}
