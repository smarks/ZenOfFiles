//
//  ConfigureOrganizeFiles.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 8/1/23.
//

import Foundation
import SwiftUI

struct ConfigureOrganizeFiles: View {
    
    @State var organizeFilesConfiguration: OrganizeFilesConfigurationSettings = OrganizeFilesConfigurationSettings()
    
    init(organizeFilesConfiguration: OrganizeFilesConfigurationSettings) {
        self.organizeFilesConfiguration = organizeFilesConfiguration
    }
    
    var body: some View {
       
            HStack {
                Text("Starting Directory")
                    .font(Font.title3)
                SelectDirectory(selectedDirectory: $organizeFilesConfiguration.startingBaseDirectory,
                                buttonLabel: "...", directoryLabel: "Starting Directory:")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 16, design: .monospaced))
            }
            
            HStack {
                Text("Destination Directory")
                    .font(Font.title3)
                SelectDirectory(selectedDirectory: $organizeFilesConfiguration.destinationBaseDirectory,
                                buttonLabel: "...", directoryLabel: "Destination Directory:")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 16, design: .monospaced))
            }
            
            Toggle("Include Sub Directories", isOn: $organizeFilesConfiguration.traverse_subdirectories)
                .toggleStyle(.checkbox)
                .padding(.trailing)
                .font(Font.title2)
            
            Toggle("Don't move files, copy them", isOn: $organizeFilesConfiguration.keepOrignals)
                .toggleStyle(.checkbox)
                .font(Font.title2)
            
            Toggle("Overwrite existing files", isOn: $organizeFilesConfiguration.overSameNamedFiles)
                .toggleStyle(.checkbox)
                .font(Font.title2)
            
      
       
    }
}
