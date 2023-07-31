//
//  OrganizeFilesConfigurationView.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/27/23.
//
import SwiftUI

/**
 * For Organize Files Funcationality - ui not started yet.
 */
struct OrganizeFilesConfigurationView: View {
    @EnvironmentObject var processedFiles: ProcessedFiles
    @State var startingBaseDirectory: URL?
    @State var destinationBaseDirectory: URL?
    @State var organizeFilesConfiguration = OrganizeFilesConfigurationSettings()
    @State private var selection: String? = ""
    @State private var order: [KeyPathComparator<FileInfo>] = [
        .init(\.id, order: SortOrder.forward),
    ]

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    @State private var isCancelled = false
    @State private var taskRunning = false
    @StateObject var timerManager = TimerManager()

    @State var startDate: Date = Date.now
    @State var endDate: Date = Date.now

    @State var beforeDateActive: Bool = false
    @State var endDateActive: Bool = false
    @State var minFileSizeActive: Bool = false
    @State var maxFileSizeActive: Bool = false
    @State var fileSize: FileSizes = FileSizes.MB
    @State var fileType: FileTypes = FileTypes.DEFAULT

    @State var minFileSizeStr: String = ""
    @State var maxFileSizeStr: String = ""
    @State var minFileSize: Double = 0.0
    @State var maxFileSize: Double = 0.0
    @State var filterByDate: Bool = false
    @State var filterBySize: Bool = false
    @State var filterByType: Bool = false

    var body: some View {
        Form {
            Section("Configure") {
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

                Section("Destination Format") {
                    let format: DestinationFormat = {
                        DestinationFormat(organizeFilesConfiguration: organizeFilesConfiguration)
                    }()
                    Text("\(format.format)")
                        .font(.system(size: 16, design: .monospaced))
                        .padding(.leading).frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(format.example)")
                        .font(.system(size: 16, design: .monospaced))
                        .padding(.leading).frame(maxWidth: .infinity, alignment: .leading)

                    Toggle("Group by year", isOn: $organizeFilesConfiguration.groupByYear).font(Font.title3).toggleStyle(.checkbox)
                    Toggle("Group by month", isOn: $organizeFilesConfiguration.groupByMonth).font(Font.title3).toggleStyle(.checkbox)
                    Toggle("Group by day", isOn: $organizeFilesConfiguration.groupByDay).font(Font.title3).toggleStyle(.checkbox)

                }.font(Font.title2) // configure

                Section("Filters") {
                    Toggle("By date", isOn: $filterByDate).font(Font.title2).toggleStyle(.switch).padding(.leading)

                    DisclosureGroup("", isExpanded: $filterByDate) {
                        HStack {
                            Toggle("Exclude files before", isOn: $beforeDateActive).font(Font.title3).toggleStyle(.checkbox)
                            DatePicker(selection: $startDate, in: ...Date.now, displayedComponents: .date) {
                            }.disabled(beforeDateActive == false)

                            Toggle("Exclude files after", isOn: $endDateActive).font(Font.title3).toggleStyle(.checkbox)
                            DatePicker(selection: $endDate, in: ...Date.now, displayedComponents: .date) {
                            }.disabled(endDateActive == false)
                        }

                    }.disabled(filterByDate == false).padding(.leading)

                    Toggle("By size", isOn: $filterBySize).font(Font.title2).toggleStyle(.switch).padding(.leading)

                    DisclosureGroup("", isExpanded: $filterBySize) {
                        HStack {
                            Toggle("Minium File Size", isOn: $minFileSizeActive).font(Font.title3).toggleStyle(.checkbox)
                            NumericTextField(numericText: $minFileSizeStr, amountDouble: $minFileSize).disabled(minFileSizeActive == false)
                            Picker("", selection: $fileSize) {
                                ForEach(FileSizes.allCases, id: \.self) {
                                    Text($0.rawValue)
                                }
                            }.disabled(minFileSizeActive == false).padding(.leading)

                        }.disabled(filterBySize == false).padding(.leading)

                        HStack {
                            Toggle("Maxium File Size", isOn: $maxFileSizeActive).font(Font.title3).toggleStyle(.checkbox)
                            NumericTextField(numericText: $maxFileSizeStr, amountDouble: $maxFileSize).font(Font.body).disabled(filterBySize == false)
                            Picker("", selection: $fileSize) {
                                ForEach(FileSizes.allCases, id: \.self) {
                                    Text($0.rawValue)
                                }
                            }.disabled(maxFileSizeActive == false).padding(.leading)
                        }.disabled(filterBySize == false).padding(.leading)
                    }.padding(.leading)
                }

                VStack {
                    
                    Picker("File Type: \(fileType.rawValue)", selection: $fileType) {
                        ForEach(FileTypes.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }.padding(.trailing)
                }.padding(.trailing).font(Font.title2)

            }.font(Font.title)

            Section("Status") {
                OrganizeFileControlPanel(timerManager: timerManager).font(Font.body)
            }.font(Font.title)
                .frame(maxWidth:
                    .infinity)

            Section {
                HStack {
                    Button("Stop") {
                        // exit(0)
                        isCancelled = true
                        timerManager.stopTimer()
                    }.disabled(!taskRunning)

                    Button("Start") {
                        processedFiles.list = []
                        Task {
                            isCancelled = false
                            taskRunning = true
                            timerManager.startTimer()
                            await orgainizeFiles(config: organizeFilesConfiguration, isCancelled: $isCancelled, processedFiles: processedFiles)
                            taskRunning = false
                            timerManager.stopTimer()
                            processedFiles.appendMessage("All Done")
                        }
                    }.disabled(organizeFilesConfiguration.destinationBaseDirectory == nil
                        ||
                        taskRunning
                        ||
                        organizeFilesConfiguration.startingBaseDirectory == nil
                    )
                }
            }
        }.formStyle(.grouped).frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DestinationFormat {
    let organizeFilesConfiguration: OrganizeFilesConfigurationSettings
    var format: String = ""
    var example: String = ""

    init(organizeFilesConfiguration: OrganizeFilesConfigurationSettings) {
        self.organizeFilesConfiguration = organizeFilesConfiguration
        let now: Date = Date.now
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: now)

        if let base = (organizeFilesConfiguration.destinationBaseDirectory?.path) {
            format.append("[destination directory]")
            example.append("\(base)")
        } else {
            format.append("[destination directory]")
            example.append("[destination directory]")
        }

        if organizeFilesConfiguration.groupByYear {
            format.append("/[YYYY]")
            example.append(String(dateComponents.year!))
        }

        if organizeFilesConfiguration.groupByMonth {
            format.append("/[MM]")
            example.append("/")
            example.append("\(String(dateComponents.month!))")
        }

        if organizeFilesConfiguration.groupByDay {
            format.append("/[DD]")
            example.append("/")
            example.append("\(String(dateComponents.day!))")
        }
        format.append("/[filename]")
        example.append("/filename.txt")
    }
}

struct OrganizeFileControlPanel: View {
    @ObservedObject var timerManager: TimerManager
    @EnvironmentObject var processedFiles: ProcessedFiles

    var body: some View {
        HStack {
            /*
             // top of table 'control panel'
             Button {
                 print("Copy \(duplicates.list.count)")

             } label: {
                 Image(systemName: "square.and.arrow.down")
             }

             Button {
                 print("Save \(duplicates.list.count)")
                 for item in duplicates.list {
                     print(item)
                 }
             } label: {
                 Image(systemName: "doc.on.doc")
             }
              */
            Text("File Count: \(processedFiles.list.count)")
            TimerDisplayView(timerManager: timerManager)
        }

        if let filePath = processedFiles.list.last?.absoluteString {
            Text("Current File: \(filePath)")
                .font(Font.title3)

        } else {
            Text("Current File: ")
                .font(Font.title3)
        }
        if let message = processedFiles.messages.last {
            Text(message).font(.system(size: 16, design: .monospaced))

        } else {
            Text("")
        }
    }
}

struct OrganizeFilesConfigurationSettings {
    var id = UUID()
    var traverse_subdirectories: Bool = false
    var startingBaseDirectory: URL?
    var destinationBaseDirectory: URL?
    var keepOrignals: Bool = false
    var filter: Bool = false
    var filterByTypes: Bool = false
    var filterBySize: Bool = false
    var filterByDate: Bool = false
    var groupByDay: Bool = false
    var groupByMonth: Bool = false
    var groupByYear: Bool = false
}

/**
 * Main entry point for organizing files by date.
 */
func orgainizeFiles(config: OrganizeFilesConfigurationSettings, isCancelled: Binding<Bool>, processedFiles: ProcessedFiles) async {
    let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey])
    let fileManager = FileManager.default
    let destinationBase = config.destinationBaseDirectory!

    if let startingBase = config.startingBaseDirectory {
        let urlResourceKeyArray = Array(resourceKeys)
        let directoryEnumerator = fileManager.enumerator(at: startingBase, includingPropertiesForKeys: urlResourceKeyArray, options: .skipsHiddenFiles)!
        var fileDestination: URL

        for case let fileURL as URL in directoryEnumerator {
            if isCancelled.wrappedValue == true {
                return
            }
            do {
                if isDirectory(url: fileURL) == false {
                    await processedFiles.append(fileURL)
                    try fileDestination = getFileDestination(fileURL: fileURL, destinationBase: destinationBase)
                    try copyFile(at: fileURL, to: fileDestination)
                    await processedFiles.appendMessage("\(fileURL.absoluteString) --> \(fileDestination.absoluteString) ✓")
                }
            } catch {
                let errorMessage = "\(fileURL.absoluteString): \(error.localizedDescription) ❌"
                print(errorMessage)
                await processedFiles.appendMessage(errorMessage)
            }
        }
    }
}
