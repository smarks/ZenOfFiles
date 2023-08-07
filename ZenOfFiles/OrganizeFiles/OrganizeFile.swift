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

    @State private var isCancelled = false
    @State private var taskRunning = false
    
    @StateObject var timerManager = TimerManager()
    @StateObject var settings = OrganizeFilesSettings()

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    
    var body: some View {
        Form {
            Section {
                Text("Options").font(Font.title)
                ConfigureOrganizeFiles().environmentObject(settings)
            }
            
            Section {
                Text("Destination Format").font(Font.title)
                let format: DestinationFormat = {
                    DestinationFormat(organizeFilesConfiguration: settings)
                }()

                Text("\(format.format)")
                    .font(.system(size: 16, design: .monospaced))
                    .padding(.leading).frame(maxWidth: .infinity, alignment: .leading)

                Text("\(format.example)")
                    .font(.system(size: 16, design: .monospaced))
                    .padding(.leading).frame(maxWidth: .infinity, alignment: .leading)

                Toggle("Group by year", isOn: $settings.groupByYear).font(Font.title3).toggleStyle(.checkbox)
                Toggle("Group by month", isOn: $settings.groupByMonth).font(Font.title3).toggleStyle(.checkbox)
                Toggle("Group by day", isOn: $settings.groupByDay).font(Font.title3).toggleStyle(.checkbox)
            }

            Section {
                Text("Filters").font(Font.title)
                FileFilterView(organizeFilesConfiguration: settings)
            }   

            Section("Control") {
                HStack {
                    Button("Stop") {
                        // exit(0)
                        isCancelled = true
                        timerManager.stopTimer()
                    }.disabled(!taskRunning)

                    Button("Start") {
                        print(settings)
                        processedFiles.list = []
                        Task {
                            isCancelled = false
                            taskRunning = true
                            timerManager.startTimer()
                            await orgainizeFiles(config: settings, isCancelled: $isCancelled, processedFiles: processedFiles)
                            taskRunning = false
                            timerManager.stopTimer()
                            processedFiles.appendMessage("All Done")
                        }
                    }.disabled(settings.destinationBaseDirectory == nil
                        ||
                        taskRunning
                        ||
                        settings.startingBaseDirectory == nil
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
    let organizeFilesConfiguration: OrganizeFilesSettings
    var format: String = ""
    var example: String = ""

    init(organizeFilesConfiguration: OrganizeFilesSettings) {
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

class OrganizeFilesSettings : ObservableObject {
    @Published var id = UUID()
    @Published var traverse_subdirectories: Bool = false
    @Published var startingBaseDirectory: URL?
    @Published var destinationBaseDirectory: URL?
    @Published var keepOrignals: Bool = false
    @Published var filter: Bool = false
    @Published var filterByTypes: Bool = false
    @Published var filterBySize: Bool = false
    @Published var filterByDate: Bool = false
    @Published var beforeDateActive: Bool = false
    @Published var startDate: Date = Date.now
    @Published var endDateActive: Bool = false
    @Published var endDate: Date = Date.now
    @Published var minFileSizeActive: Bool = false
    @Published var maxFileSizeActive: Bool = false
    @Published var minFileSize: Int64 = 0
    @Published var maxFileSize: Int64 = 0
    @Published var filterByFileTypes: [FileTypes] = [FileTypes.DEFAULT]
    @Published var fileType: FileTypes = FileTypes.DEFAULT

    @Published var groupByDay: Bool = false
    @Published var groupByMonth: Bool = false
    @Published var groupByYear: Bool = false
    @Published var overSameNamedFiles: Bool = false

    @Published var useFileType: Bool = false
    @Published var useFileExtension: Bool = false
    @Published var skipFIlesWithoutExtensions: Bool = false
}

/**
 * Main entry point for organizing files by date.
 */
func orgainizeFiles(config: OrganizeFilesSettings, isCancelled: Binding<Bool>, processedFiles: ProcessedFiles) async {
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
