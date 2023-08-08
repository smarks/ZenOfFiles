//
//  FileFilters.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 8/1/23.
//

import Foundation
import SwiftUI

struct FileFilterView: View {
    @EnvironmentObject var settings: OrganizeFilesSettings

    @State var fileExtension: String = ""
    @State var minFileSizeStr: String = ""
    @State var maxFileSizeStr: String = ""
    @State var fileExtensions: [String] = []

    var body: some View {
        Section {
            HStack {
                Toggle("Exclude files before", isOn: $settings.beforeDateActive)
                    .toggleStyle(.checkbox)

                DatePicker(selection: $settings.startDate, in: ...Date.now, displayedComponents: .date) {
                }.disabled(settings.beforeDateActive == false)

                Toggle("Exclude files after", isOn: $settings.endDateActive)
                    .toggleStyle(.checkbox)

                DatePicker(selection: $settings.endDate, in: ...Date.now, displayedComponents: .date) {
                }.disabled(settings.endDateActive == false)
            }

        } header: {
            Text("By date")
        }

        Section {
            HStack {
                Toggle("Minimum File Size", isOn: $settings.minFileSizeActive)
                    .toggleStyle(.checkbox)

                NumericTextField(numericText: $minFileSizeStr, amount: $settings.minFileSize)
                    .disabled(settings.minFileSizeActive == false)

                Picker("Size Unit", selection: $settings.minFileSizeUnits) {
                    ForEach(FileSizes.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }.disabled(settings.minFileSizeActive == false)

                Toggle("Maximum File Size", isOn: $settings.maxFileSizeActive)
                    .toggleStyle(.checkbox)

                NumericTextField(numericText: $maxFileSizeStr, amount: $settings.maxFileSize)
                    .disabled(settings.maxFileSizeActive == false)

                Picker("Size Unit", selection: $settings.maxFileSizeUnits) {
                    ForEach(FileSizes.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }.disabled(settings.maxFileSizeActive == false)
            }

        } header: {
            Text("By size")
        }

        Section {
            Toggle("Skip files without extensions", isOn: $settings.skipFIlesWithoutExtensions)
                .toggleStyle(.checkbox)
                .padding()

            Toggle("Include file with these extensions", isOn: $settings.useFileExtension)
                .toggleStyle(.checkbox)
                .padding()

            HStack {
                Text("File Extensions")
                TextField("Coma separated list e.g. png,tiff,jpeg", text: $fileExtension)
                    .background(Color.white)
                    .font(Font.caption)
                Button("Add") {
                    fileExtensions.append(fileExtension)
                    print(fileExtensions)
                }
            }.disabled(settings.useFileExtension == false)

            Toggle("Use system file type", isOn: $settings.useFileType)
                .toggleStyle(.checkbox)

            Picker("\(settings.fileType.rawValue)", selection: $settings.fileType) {
                ForEach(FileTypes.allCases, id: \.self) {
                    Text($0.rawValue)
                }

            }.disabled(settings.useFileType == false)
        } header: {
            Text("By file type")
        }
    } // end body
} // end struct
