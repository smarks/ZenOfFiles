//
//  Widgets.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/27/23.
//

import SwiftUI

struct SelectDirectory: View {

    /**
     * View for selecting a directory
     */
    @Binding var selectedDirectory: URL?
    var buttonLabel: String
    var directoryLabel: String

    var body: some View {
        Button(buttonLabel, action: {
            let dialog = NSOpenPanel()
            dialog.title = buttonLabel
            dialog.canChooseFiles = false
            dialog.canChooseDirectories = true
            dialog.allowsMultipleSelection = false
            dialog.directoryURL = selectedDirectory

            if dialog.runModal() == .OK {
                selectedDirectory = dialog.url
            }
        })

        if let directory = selectedDirectory {
            Text("\(directory.path)")
        }
    }
}
