//
//  OrganizeFilesConfigurationView.swift
//  ZenOfFiles
//
 //
import SwiftUI

/**
 * For Organize Files Funcationality 
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
                ConfigureOrganizeFilesView().environmentObject(settings)
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

                Toggle("Group by **year**", isOn: $settings.groupByYear).font(Font.title3).toggleStyle(.checkbox)
                Toggle("Group by **month**", isOn: $settings.groupByMonth).font(Font.title3).toggleStyle(.checkbox)
                Toggle("Group by **day**", isOn: $settings.groupByDay).font(Font.title3).toggleStyle(.checkbox)
            }

            Section {
                Text("Filters").font(Font.title)
                FileFilterView().environmentObject(settings)
            }

            Section("Control") {
                
                let task = OrganizeFilesTask(config: settings, processedFiles: processedFiles)

                HStack {
                    Button("Stop") {
                        // exit(0)
                        isCancelled = true
                        timerManager.stopTimer()
                        
                       task.cancelTask()
                     // taskRunning = false
                    }.disabled(!taskRunning)

                    Button("Start") {
                        debugSettings(settings: settings)
                        processedFiles.list = []

                        task.startTask()
                        taskRunning = true
                        
                        /*     Task {
                            isCancelled = false
                            taskRunning = true
                            timerManager.startTimer()
                            await orgainizeFiles(settings: settings, isCancelled: $isCancelled, processedFiles: processedFiles)
                            taskRunning = false
                            timerManager.stopTimer()
                            processedFiles.appendMessage("All Done")
                        }
                    */
                    
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

func debugSettings(settings: OrganizeFilesSettings) {
    print("settings.id: \(settings.id)")
    print("traverse_subdirectories \(settings.traverse_subdirectories)")
    print("startingBaseDirectory \(String(describing: settings.startingBaseDirectory))")
    print("destinationBaseDirectory \(String(describing: settings.destinationBaseDirectory))")
    print("keepOrignals \(settings.copyOrMoveFile)")
    print("beforeDateActive \(settings.beforeDateActive)")
    print("startDate \(settings.startDate)")
    print("endDateActive \(settings.endDateActive)")
    print("endDate \(settings.endDate)")
    print("minFileSizeActive \(settings.minFileSizeActive)")
    print("maxFileSizeActive \(settings.maxFileSizeActive)")
    print("minFileSize \(settings.minFileSize)")
    print("maxFileSize \(settings.maxFileSize)")
    print("filterByFileTypes \(settings.filterByFileTypes)")
    print("fileType \(settings.fileType)")
    print("groupByDay \(settings.groupByDay)")
    print("groupByMonth \(settings.groupByMonth)")
    print("groupByYear \(settings.groupByYear)")
    print("overSameNamedFiles \(settings.overwriteSameNamedFiles)")
    print("useFileType \(settings.useFileType)")
    print("useFileExtension \(settings.useFileExtension)")
    print("skipFilesWithoutExtensions \(settings.skipFilesWithoutExtensions)")
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

/**
 * Main entry point for organizing files by date.
 */
func orgainizeFiles(settings: OrganizeFilesSettings, task:  DispatchWorkItem, processedFiles: ProcessedFiles)  {
    let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey])
    let fileManager = FileManager.default
    let destinationBase = settings.destinationBaseDirectory!
    var options: [FileManager.DirectoryEnumerationOptions] = []
    
    if (settings.skipsHiddenFiles) {
        options.append(.skipsHiddenFiles)
    }
    if (settings.traverse_subdirectories == false) {
        options.append(.skipsSubdirectoryDescendants)
    }
    
    if let startingBase = settings.startingBaseDirectory {
        
        let urlResourceKeyArray = Array(resourceKeys)
        let directoryEnumerator = fileManager.enumerator(at: startingBase, includingPropertiesForKeys: urlResourceKeyArray, options: .skipsHiddenFiles)!
        var fileDestination: URL

        for case let fileURL as URL in directoryEnumerator {
            print(task)
            if task.isCancelled  == true {
                print("Task cancelled")
                return
            }
            do {
                if isDirectory(url: fileURL) == false {
                     processedFiles.append(fileURL)
                    if (okToProcess(settings: settings, fileURL: fileURL) == true) {
                        try fileDestination = getFileDestination(fileURL: fileURL, destinationBase: destinationBase)
                        var deleteOriginal: Bool = false
                        (settings.copyOrMoveFile == CopyOrMoveFile.MOVE) ? (deleteOriginal = true) : (deleteOriginal = false)

                        try copyFile(at: fileURL, to: fileDestination, deleteOriginal: deleteOriginal)
                          processedFiles.appendMessage("✓ \(fileURL.absoluteString) --> \(fileDestination.absoluteString)")
                    } else {
                          processedFiles.appendMessage("Skipping \(fileURL.absoluteString)")
                    }
                }
            } catch {
                let errorMessage = "❌ \(fileURL.absoluteString): \(error.localizedDescription) "
                print(errorMessage)
                  processedFiles.appendMessage(errorMessage)
            }
        }
    }
}

func okToProcess(settings: OrganizeFilesSettings, fileURL: URL) -> Bool {
    var status: Bool = false

    return status
}
