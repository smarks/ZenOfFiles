//
//  ZenOfFilesApp.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/5/23.
//

import SwiftUI

@main
struct ZenOfFilesApp: App {
    
    @StateObject var myItemList = MyItemList()
    var body: some Scene {
        WindowGroup {
            MyView(myItemList: myItemList)
            Button("Add One Please") {
                print("adding one please, please")
                let item = IdentifiableItem(identifier: "hello",
                                            name: "name",
                                            path: "path")

                myItemList.list.append(item)
            }
        }
    }
}

 class MyItemList: ObservableObject {
    @Published var list: [IdentifiableItem] = []
}

struct MyView: View {
    @State private var selection: String? = ""
    @StateObject var myItemList: MyItemList

    @State private var order = [KeyPathComparator(\IdentifiableItem.id)]

    var body: some View {
        HStack {
            Button {
                print("Copy")
                let item = IdentifiableItem(identifier: "hello",
                                            name: "name",
                                            path: "path")

                myItemList.list.append(item)

            } label: {
                Image(systemName: "square.and.arrow.down")
            }

            Button {
                print("Save \(myItemList.list.count)")
                for item in myItemList.list {
                    print(item)
                }
            } label: {
                Image(systemName: "doc.on.doc")
            }

        }.padding(10)

        Table(selection: $selection, sortOrder: $order) {
            //   TableColumn("Id", value: \.id)
            TableColumn("Name", value: \.name)
            TableColumn("Path", value: \.path) { Text($0.path) }
        } rows: {
            ForEach(myItemList.list) { item in
                TableRow(item)
                    .contextMenu {
                        Button("Copy") {
                            print(item)
                        }
                    }
            }
        }.onChange(of: order) { newOrder in
            myItemList.list.sort(using: newOrder)
        }
    }
}

class IdentifiableItem: ObservableObject, Identifiable {
    let id: String
    let name: String
    let path: String

    init(identifier: String, name: String, path: String) {
        id = identifier
        self.name = name
        self.path = path
    }
}
