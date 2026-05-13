//
//  OnboardingView.swift
//  Task_Flow

import SwiftUI

// Shows three introduction pages before the user reaches the login screen.
struct OnboardingView: View {
    let onFinish: () -> Void

    // MARK: - View State

    // Tracks the current introduction page.
    @State private var currentPage = 0

    // Stores the three onboarding pages shown to the user.
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "checklist.checked",
            title: "Plan Your Day Smarter",
            subtitle: "Task Flow helps you manage daily tasks, reminders, notes, goals, and habits in one place."
        ),
        OnboardingPage(
            icon: "clock.badge.checkmark",
            title: "Track Work and Progress",
            subtitle: "Record work hours, calculate earnings, track expenses, monitor habits, and review productivity analytics."
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Secure and Smart Tools",
            subtitle: "Use Firebase login, Face ID access, password vault, push notifications, and location-based reminders."
        )
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            background

            VStack(spacing: 24) {
                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        onboardingPage(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageDots

                Button {
                    nextAction()
                } label: {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal, 28)

                Button {
                    onFinish()
                } label: {
                    Text("Skip")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.72))
                }

                Spacer()
                    .frame(height: 35)
            }
        }
    }

    // MARK: - Page View

    // Builds one introduction page with an icon, title, and short project explanation.
    private func onboardingPage(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Image(systemName: page.icon)
                .font(.system(size: 78, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(page.title)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(page.subtitle)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 34)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Page Dots

    // Shows which introduction page the user is currently viewing.
    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.pink : Color.white.opacity(0.25))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }

    // MARK: - Button Logic

    // Moves to the next page or finishes onboarding on the final page.
    private func nextAction() {
        if currentPage < pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            onFinish()
        }
    }

    // MARK: - Background

    // Main onboarding background matching the Task Flow dark theme.
    private var background: some View {
        LinearGradient(
            colors: [
                Color.black,
                Color(red: 8/255, green: 12/255, blue: 42/255),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Onboarding Page Model

// Stores the content for one introduction screen.
private struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
}
