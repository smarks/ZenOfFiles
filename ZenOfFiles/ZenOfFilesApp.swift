//
//  ZenOfFilesApp.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/5/23.
//

import SwiftUI
 

import CommonCrypto
import Foundation
import UniformTypeIdentifiers

import ImageIO
@main
struct ZenOfFilesApp: App {
    
    @StateObject var duplicateFileList = ItemList()
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
