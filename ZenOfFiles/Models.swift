//
//  Models.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/5/23.
//

import Foundation


struct FileInfo: Identifiable {
    let id: String

    let name: String
    let path: String
    let url: String
    let checksum: String
    let dateModified: Date
    let dateCreated: Date
    let size: Int64
}

 


struct FindDuplicatesConfigurationSettings  {
  var id = UUID()
  var traverse_subdirectories: Bool = false
  var useChecksum: Bool = false
  var useFileName: Bool = false
  var useFileSize: Bool = false
  var createDeleteFileScript: Bool = false
  var deleteFiles: Bool = false
  var selectedDirectory: URL?
}
  
enum DeleteBy: String, CaseIterable, Hashable {
  case oldest = "Oldest"
  case newest = "Newest"
}

