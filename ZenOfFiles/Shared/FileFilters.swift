//
//  FileFilters.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 8/1/23.
//

import Foundation
import SwiftUI

struct FileFilterView: View {
    @State var organizeFilesConfiguration: OrganizeFilesConfigurationSettings = OrganizeFilesConfigurationSettings()

    init(organizeFilesConfiguration: OrganizeFilesConfigurationSettings) {
        self.organizeFilesConfiguration = organizeFilesConfiguration
    }

    @State var fileExtension: String = ""
    @State var minFileSizeStr: String = ""
    @State var maxFileSizeStr: String = ""
    @State var fileExtensions: [String] = []

    var body: some View {
        Section {
            HStack {
                Toggle("Exclude files before", isOn: $organizeFilesConfiguration.beforeDateActive)
                    .toggleStyle(.checkbox)

                DatePicker(selection: $organizeFilesConfiguration.startDate, in: ...Date.now, displayedComponents: .date) {
                }.disabled(organizeFilesConfiguration.beforeDateActive == false)

                Toggle("Exclude files after", isOn: $organizeFilesConfiguration.endDateActive)
                    .toggleStyle(.checkbox)

                DatePicker(selection: $organizeFilesConfiguration.endDate, in: ...Date.now, displayedComponents: .date) {
                }.disabled(organizeFilesConfiguration.endDateActive == false)
            }

        } header: {
            Text("By date")
        }

        Section {
            HStack {
                Toggle("Minimum File Size", isOn: $organizeFilesConfiguration.minFileSizeActive)
                    .toggleStyle(.checkbox)

                NumericTextField(numericText: $minFileSizeStr, amount: $organizeFilesConfiguration.minFileSize)
                    .disabled(organizeFilesConfiguration.minFileSizeActive == false)

                Picker("", selection: $organizeFilesConfiguration.minFileSize) {
                    ForEach(FileSizes.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }

                Toggle("Maximum File Size", isOn: $organizeFilesConfiguration.maxFileSizeActive)
                    .toggleStyle(.checkbox)

                NumericTextField(numericText: $maxFileSizeStr, amount: $organizeFilesConfiguration.maxFileSize)
                    .disabled(organizeFilesConfiguration.minFileSizeActive == false)

                Picker("", selection: $organizeFilesConfiguration.minFileSize) {
                    ForEach(FileSizes.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }.disabled(organizeFilesConfiguration.minFileSizeActive == false)
            }

        } header: {
            Text("By size")
        }

        Section {
            Toggle("Skip files without extensions", isOn: $organizeFilesConfiguration.skipFIlesWithoutExtensions)
                .toggleStyle(.checkbox)
                .padding()

            Toggle("Include file with these extensions", isOn: $organizeFilesConfiguration.useFileExtension)
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
            }.disabled(organizeFilesConfiguration.useFileExtension == false)

            Toggle("Use system file type", isOn: $organizeFilesConfiguration.useFileType)
                .toggleStyle(.checkbox)

            Picker("\(organizeFilesConfiguration.fileType.rawValue)", selection: $organizeFilesConfiguration.fileType) {
                ForEach(FileTypes.allCases, id: \.self) {
                    Text($0.rawValue)
                }

            }.disabled(organizeFilesConfiguration.useFileType == false)
        } header: {
            Text("By file type")
        }
    } // end body
} // end struct
