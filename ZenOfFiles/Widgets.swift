//
//  Widgets.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/27/23.
//

import SwiftUI


struct NumericTextField: View {
    @Binding var numericText: String
    @Binding var amountDouble: Double
    
    var body: some View {
        TextField("", text: $numericText)
            .onChange(of: numericText) { newValue in
                numericText = filterNumericText(from: newValue)
                amountDouble = Double(numericText) ??  0.0
            }.background(Color.white).padding(.trailing).font(Font.body)

    }

    private func filterNumericText(from text: String) -> String {
        let allowedCharacterSet = CharacterSet(charactersIn: "0123456789.")

        let tokens = text.components(separatedBy: ".")

        // allow only one '.' decimal character
        if tokens.count > 2   {
            return String(text.dropLast(1))
        }
        
        // allow only two digits after ater '.' decimal character
        if (tokens.count > 1 && tokens[1].count > 2) {
            return String(text.dropLast(1))
        }

        // only allow digits and decimals
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
