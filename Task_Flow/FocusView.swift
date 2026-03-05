//
//  FocusView.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty on 2/11/26.
//

import SwiftUI
import Combine


struct FocusView: View {
    @State private var secondsLeft = 25 * 60
    @State private var running = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text(timeString(secondsLeft))
                    .font(.system(size: 56, weight: .bold, design: .rounded))

                HStack(spacing: 12) {
                    Button(running ? "Pause" : "Start") { running.toggle() }
                        .buttonStyle(.borderedProminent)
                    Button("Reset") {
                        running = false
                        secondsLeft = 25 * 60
                    }
                    .buttonStyle(.bordered)
                }

                Text("Focus / Pomodoro Mode")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Focus")
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard running else { return }
            if secondsLeft > 0 { secondsLeft -= 1 } else { running = false }
        }
    }

    private func timeString(_ s: Int) -> String {
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
}

