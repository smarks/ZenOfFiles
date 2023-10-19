//
//  OrganizeFilesControlller.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 10/18/23.
//

import Foundation

class OrganizeFilesTask {
    private var workItem: DispatchWorkItem = DispatchWorkItem{}
    
    private var config: OrganizeFilesSettings
    private var processedFiles: ProcessedFiles
    
    init(config: OrganizeFilesSettings, processedFiles: ProcessedFiles) {
        self.config = config
        self.processedFiles = processedFiles
    }
    
        func startTask() {
        
            workItem = DispatchWorkItem {
                
                orgainizeFiles(settings: self.config, task: self.workItem, processedFiles: self.processedFiles)
        }

            DispatchQueue.global().async(execute: workItem)
    }

    func cancelTask() {
        workItem.cancel()

     }
}
