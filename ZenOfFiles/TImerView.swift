//
//  TImerView.swift
//  ZenOfFiles
//
//  Created by Spencer Marks on 7/10/23.
//

import Foundation
import SwiftUI
struct TimerView: View {
    @State var startDate = Date.now
    @State var timeElapsed: Int = 0
       
       // 1
    @State  var timer:Timer.TimerPublisher

       
       var body: some View {
           Text("Time elapsed: \(timeElapsed) sec")
               // 2
               .onReceive(timer) { firedDate in
                timeElapsed = Int(firedDate.timeIntervalSince(startDate))

               }
                
       }
    func stopTimer() {
     //  self.$timer.upstream.connect.cancel
    }
    
    func startTimer() {
    //    self.timer  = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    }
}

