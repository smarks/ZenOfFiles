//
//  ConfigureOrganizeFiles.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 8/1/23.
//

import Foundation
import SwiftUI

struct ConfigureOrganizeFilesView: View {
    @EnvironmentObject var settings: OrganizeFilesSettings
    @State var selectionValue: String = "Copy"
    
    var body: some View {
        HStack {
            Text("Starting Directory")
                .font(Font.title3)

            SelectDirectory(selectedDirectory: $settings.startingBaseDirectory,
                            buttonLabel: "...", directoryLabel: "Starting Directory:")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 16, design: .monospaced))
        }
        HStack {
            Text("Destination Directory")
                .font(Font.title3)
            SelectDirectory(selectedDirectory: $settings.destinationBaseDirectory,
                            buttonLabel: "...", directoryLabel: "Destination Directory:")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 16, design: .monospaced))
        }

        Toggle("Include Sub Directories", isOn: $settings.traverse_subdirectories)
            .toggleStyle(.checkbox)
            .padding(.trailing)
            .font(Font.title2)

        Picker("Copy or Move files from desintation:", selection: $settings.copyOrMoveFile) {
            ForEach(CopyOrMoveFile.allCases, id: \.self) {
                Text($0.rawValue)
            }
        }.pickerStyle(.radioGroup)
        .font(Font.title2)
        .horizontalRadioGroupLayout()

        HStack {
            Toggle("Overwrite existing files with same **name**", isOn: $settings.overwriteSameNamedFiles)
                .toggleStyle(.checkbox)
                .font(Font.title2)
            Toggle("Only overwrite if files are identical (have same checksum value)", isOn: $settings.overwriteSameNamedFilesOnlyIfIdentical)
                .toggleStyle(.checkbox)
                .font(Font.title2).disabled(settings.overwriteSameNamedFiles)
        }
        HStack {
            Toggle("Overwrite existing files with same **size**", isOn: $settings.overwriteSameSizedFiles)
                .toggleStyle(.checkbox)
                .font(Font.title2)
            Toggle("Only overwrite if files are identical (have same checksum value)", isOn: $settings.overwriteSameNamedFilesOnlyIfIdentical)
                .toggleStyle(.checkbox)
                .font(Font.title2).disabled(settings.overwriteSameSizedFilesOnlyIfIdentical)
        }
    }
}
