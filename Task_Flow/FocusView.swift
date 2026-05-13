//
//  FocusView.swift
//  Task_Flow
import SwiftUI
import Combine

struct FocusView: View {
    @AppStorage("tf_dark_mode") private var darkMode = false

    // MARK: - Timer State

    // Stores the remaining focus time in seconds.
    @State private var secondsLeft = 25 * 60

    // Tracks whether the focus timer is currently running.
    @State private var running = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                background

                VStack(spacing: 22) {
                    Spacer()

                    Text(timeString(secondsLeft))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(primaryText)

                    HStack(spacing: 12) {
                        Button(running ? "Pause" : "Start") {
                            running.toggle()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Reset") {
                            running = false
                            secondsLeft = 25 * 60
                        }
                        .buttonStyle(.bordered)
                    }

                    Text("Focus / Pomodoro Mode")
                        .font(.subheadline)
                        .foregroundColor(secondaryText)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Focus")
            .toolbarBackground(darkMode ? Color.black : Color.white, for: .navigationBar)
            .toolbarColorScheme(darkMode ? .dark : .light, for: .navigationBar)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard running else {
                return
            }

            if secondsLeft > 0 {
                secondsLeft -= 1
            } else {
                running = false
            }
        }
    }

    // MARK: - Theme

    // Main background used for both light and dark mode.
    private var background: some View {
        LinearGradient(
            colors: darkMode
            ? [
                Color.black,
                Color(red: 8/255, green: 12/255, blue: 42/255),
                Color.black
            ]
            : [
                Color(red: 0.96, green: 0.97, blue: 1.00),
                Color.white
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // Main timer text color based on the selected theme.
    private var primaryText: Color {
        darkMode ? .white : .black
    }

    // Secondary text color used for the screen subtitle.
    private var secondaryText: Color {
        darkMode ? .white.opacity(0.7) : .black.opacity(0.55)
    }

    // MARK: - Timer Helper

    // Converts total seconds into a readable minute and second format.
    private func timeString(_ s: Int) -> String {
        let m = s / 60
        let r = s % 60

        return String(format: "%02d:%02d", m, r)
    }
}
