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

    var body: some View {
        Form {
            Section {
                Text("Options").font(Font.title)
                ConfigureOrganizeFiles(organizeFilesConfiguration: organizeFilesConfiguration)
            }

            Section {
                Text("Destination Format").font(Font.title)
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
            }

            Section {
                Text("Filters").font(Font.title)
                FileFilterView(organizeFilesConfiguration: organizeFilesConfiguration)
            }   

            Section("Control") {
                HStack {
                    Button("Stop") {
                        // exit(0)
                        isCancelled = true
                        timerManager.stopTimer()
                    }.disabled(!taskRunning)

                    Button("Start") {
                        print(organizeFilesConfiguration)
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
            Section("Status") {
                OrganizeFileControlPanel(timerManager: timerManager).font(Font.body)
            }.font(Font.title)
                .frame(maxWidth:
                    .infinity)

        }.formStyle(.grouped).frame(maxWidth: .infinity)
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
    var beforeDateActive: Bool = false
    var startDate: Date = Date.now
    var endDateActive: Bool = false
    var endDate: Date = Date.now
    var minFileSizeActive: Bool = false
    var maxFileSizeActive: Bool = false
    var minFileSize: Int64 = 0
    var maxFileSize: Int64 = 0
    var filterByFileTypes: [FileTypes] = [FileTypes.DEFAULT]
    var fileType: FileTypes = FileTypes.DEFAULT

    var groupByDay: Bool = false
    var groupByMonth: Bool = false
    var groupByYear: Bool = false
    var overSameNamedFiles: Bool = false

    var useFileType: Bool = false
    var useFileExtension: Bool = false
    var skipFIlesWithoutExtensions: Bool = false
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
