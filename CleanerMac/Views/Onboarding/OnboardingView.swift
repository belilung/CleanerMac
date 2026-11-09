import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentStep = 0
    @State private var animateIn = false
    @State private var checkingAccess = false
    @State private var hasFullDiskAccess = false

    private let totalSteps = 3

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                // Step content
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    permissionStep.tag(1)
                    readyStep.tag(2)
                }
                .tabViewStyle(.automatic)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom navigation
                bottomBar
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .onAppear {
            hasFullDiskAccess = PermissionManager.shared.checkFullDiskAccess()
            withAnimation(.easeOut(duration: 0.8)) {
                animateIn = true
            }
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 120
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateIn ? 1 : 0.5)
                    .opacity(animateIn ? 1 : 0)

                Image(systemName: "sparkles")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateIn ? 1 : 0.3)
                    .opacity(animateIn ? 1 : 0)
            }

            VStack(spacing: 12) {
                Text("Welcome to CleanerMac")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)

                Text("Keep your Mac clean, fast, and organized.\nScan for junk, find duplicates, and free up space in seconds.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
            }

            // Feature highlights
            HStack(spacing: 24) {
                FeatureHighlight(icon: "bolt.fill", title: "Fast Scan", description: "Analyzes your disk in seconds", color: .blue)
                FeatureHighlight(icon: "shield.fill", title: "Safe", description: "Risk-based protection for your files", color: .green)
                FeatureHighlight(icon: "sparkles", title: "Smart", description: "Auto-detects what's safe to clean", color: .purple)
            }
            .padding(.top, 8)
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 30)

            Spacer()
        }
        .animation(.easeOut(duration: 0.8).delay(0.2), value: animateIn)
    }

    // MARK: - Step 2: Permissions

    private var permissionStep: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(hasFullDiskAccess ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 160, height: 160)

                Image(systemName: hasFullDiskAccess ? "checkmark.shield.fill" : "lock.shield.fill")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(hasFullDiskAccess ? .green : .orange)
                    .symbolEffect(.bounce, value: hasFullDiskAccess)
            }

            VStack(spacing: 12) {
                Text("Full Disk Access")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                if hasFullDiskAccess {
                    Label("Full Disk Access is enabled", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.green)
                } else {
                    Text("CleanerMac needs Full Disk Access to scan all areas of your system.\nThis is a one-time setup — you won't be asked again.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 450)
                }
            }

            if !hasFullDiskAccess {
                VStack(spacing: 16) {
                    // Step-by-step guide
                    VStack(alignment: .leading, spacing: 12) {
                        PermissionStepRow(number: 1, text: "Click \"Open System Settings\" below")
                        PermissionStepRow(number: 2, text: "Find CleanerMac in the list")
                        PermissionStepRow(number: 3, text: "Toggle the switch to enable access")
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    HStack(spacing: 16) {
                        Button {
                            PermissionManager.shared.requestFullDiskAccess()
                        } label: {
                            Label("Open System Settings", systemImage: "gear")
                                .font(.headline)
                                .frame(height: 44)
                                .padding(.horizontal, 24)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button {
                            checkingAccess = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                hasFullDiskAccess = PermissionManager.shared.checkFullDiskAccess()
                                checkingAccess = false
                            }
                        } label: {
                            if checkingAccess {
                                ProgressView()
                                    .controlSize(.small)
                                    .frame(width: 120, height: 44)
                            } else {
                                Label("Check Status", systemImage: "arrow.clockwise")
                                    .frame(height: 44)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
            }

            if !hasFullDiskAccess {
                Text("You can skip this step, but some scan results may be limited.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
    }

    // MARK: - Step 3: Ready

    private var readyStep: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.green.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("CleanerMac is ready to scan your Mac.\nClick the button below to get started.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            Button {
                withAnimation(.spring(duration: 0.4)) {
                    hasCompletedOnboarding = true
                }
            } label: {
                Label("Start Using CleanerMac", systemImage: "arrow.right")
                    .font(.title3.weight(.semibold))
                    .frame(width: 280, height: 52)
            }
            .buttonStyle(GradientButtonStyle(colors: [.blue, .cyan]))
            .keyboardShortcut(.return, modifiers: .command)

            Spacer()
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            // Step indicators
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step == currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(step == currentStep ? 1.2 : 1.0)
                        .animation(.spring(duration: 0.3), value: currentStep)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation(.spring(duration: 0.4)) {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }

                if currentStep < totalSteps - 1 {
                    Button {
                        withAnimation(.spring(duration: 0.4)) {
                            currentStep += 1
                        }
                    } label: {
                        Text(currentStep == 1 && !hasFullDiskAccess ? "Skip" : "Next")
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.windowBackgroundColor),
                Color(.windowBackgroundColor).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Feature Highlight

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)
                .frame(width: 56, height: 56)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(width: 140)
        }
    }
}

// MARK: - Permission Step Row

struct PermissionStepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue, in: Circle())

            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    OnboardingView()
        .frame(width: 800, height: 600)
}
