//
//  TImerView.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/10/23.
//

import CoreData
import Foundation
import SwiftUI

class TimerManager: ObservableObject {
    @Published var startTime: Date?
    @Published var elapsedTime: TimeInterval = 0.0
    @Published var isTimerRunning = false

    private var timer: DispatchSourceTimer?

    func startTimer() {
        startTime = Date()
        elapsedTime = 0.0
        isTimerRunning = true

        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timer?.schedule(deadline: .now(), repeating: 1.0)
        timer?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                guard let startTime = self?.startTime else {
                    self?.stopTimer()
                    return
                }

                self?.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
        timer?.resume()
    }

    func stopTimer() {
        timer?.cancel()
        timer = nil
        isTimerRunning = false
    }

    func formattedElapsedTime() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad

        return formatter.string(from: elapsedTime) ?? ""
    }
}

struct TimerDisplayView: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        Text("Elapsed Time: \(timerManager.formattedElapsedTime())")
            .padding()
    }
}

struct TimerControlView: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        Button(action: {
            if timerManager.isTimerRunning {
                timerManager.stopTimer()
            } else {
                timerManager.startTimer()
            }
        }) {
            Text(timerManager.isTimerRunning ? "Stop Timer" : "Start Timer")
        }
    }
}
