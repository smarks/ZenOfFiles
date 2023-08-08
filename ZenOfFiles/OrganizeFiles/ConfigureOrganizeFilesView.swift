//
//  ConfigureOrganizeFiles.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 8/1/23.
//

import Foundation
import SwiftUI

struct ConfigureOrganizeFilesView: View {
    
    @EnvironmentObject  var settings: OrganizeFilesSettings
     
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
            
            Toggle("Don't move files, copy them", isOn: $settings.keepOrignals)
                .toggleStyle(.checkbox)
                .font(Font.title2)
            
            Toggle("Overwrite existing files", isOn: $settings.overSameNamedFiles)
                .toggleStyle(.checkbox)
                .font(Font.title2)
            
      
       
    }
}

