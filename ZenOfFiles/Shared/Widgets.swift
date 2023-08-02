//
//  Widgets.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/27/23.
//

import SwiftUI


struct NumericTextField: View {
    @Binding var numericText: String
    @Binding var amount: Int64
    
    var body: some View {
        TextField("", text: $numericText)
            .onChange(of: numericText) { newValue in
                numericText = filterNumericText(from: newValue)
                amount = Int64(numericText) ??  0
            }.background(Color.white).padding(.trailing).font(Font.body)

    }

    private func filterNumericText(from text: String) -> String {
        let allowedCharacterSet = CharacterSet(charactersIn: "0123456789")

        // only allow digits
        return String(text.unicodeScalars.filter { allowedCharacterSet.contains($0) })
    }
}


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
