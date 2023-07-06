//
//  Models.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/5/23.
//

import Foundation
 

class ItemList: ObservableObject {
   @Published var list: [IdentifiableFoundDuplicate] = []
}

class IdentifiableFoundDuplicate:ObservableObject,Identifiable {
  let id: String
  
  let name: String
  let path: String
  let url: String
  let checksum: String
  let dateModified: Date
  let dateCreated: Date
  let size: Int64
  
  init(identifier: String, name:String, path:String, url:String, checksum:String, dateCreated:Date, dateModified:Date, size:Int64) {
      self.id = identifier
      self.name = name
      self.path = path
      self.url = url
      self.checksum = checksum
      self.dateModified = dateModified
      self.dateCreated = dateCreated
      self.size = size
  }
  
}


struct FindDuplicatesConfigurationSettings {
  var id = UUID()
  var traverse_subdirectories: Bool = false
  var useChecksum: Bool = false
  var useFileName: Bool = false
  var useFileSize: Bool = false
  var createDeleteFileScript: Bool = false
  var deleteFiles: Bool = false
  var useSubdirs: Bool = false
  var selectedDirectory: URL?
}
  
enum DeleteBy: String, CaseIterable, Hashable {
  case oldest = "Oldest"
  case newest = "Newest"
}

