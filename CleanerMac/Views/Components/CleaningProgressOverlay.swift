import SwiftUI

struct CleaningProgressOverlay: View {
    @Environment(CleanerService.self) private var cleanerService

    var body: some View {
        if cleanerService.isCleaning {
            ZStack {
                // Dimmed background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                // Progress card
                VStack(spacing: 24) {
                    // Animated cleaning icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.blue.opacity(0.2), .clear],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 100, height: 100)

                        ProgressRing(
                            progress: cleanerService.progress,
                            lineWidth: 6,
                            size: 80,
                            gradientColors: [.blue, .cyan]
                        ) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.blue)
                                .symbolEffect(.bounce, value: cleanerService.progress)
                        }
                    }

                    VStack(spacing: 8) {
                        Text("Cleaning...")
                            .font(.title3.weight(.semibold))

                        Text("\(Int(cleanerService.progress * 100))%")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.blue)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.2), value: cleanerService.progress)

                        if let currentFile = cleanerService.currentFileName {
                            Text(currentFile)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: 280)
                        }
                    }

                    // Live freed space counter
                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("Freed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(ByteCountFormatter.string(fromByteCount: cleanerService.cleanedSize, countStyle: .file))
                                .font(.headline)
                                .monospacedDigit()
                                .foregroundStyle(.green)
                                .contentTransition(.numericText())
                                .animation(.easeInOut, value: cleanerService.cleanedSize)
                        }

                        Divider()
                            .frame(height: 30)

                        VStack(spacing: 2) {
                            Text("Items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(cleanerService.processedCount)/\(cleanerService.totalCount)")
                                .font(.headline)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.easeInOut, value: cleanerService.processedCount)
                        }
                    }

                    // Cancel button
                    Button("Cancel") {
                        cleanerService.cancelCleaning()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(40)
                .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}

// MARK: - Cleaning Complete View

struct CleaningCompleteView: View {
    let freedSpace: Int64
    let itemCount: Int
    let errors: [CleanerService.CleanError]
    let onDismiss: () -> Void

    @State private var animateIn = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 28) {
                // Success icon with animation
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.green.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(animateIn ? 1 : 0.5)

                    Image(systemName: errors.isEmpty ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(errors.isEmpty ? .green : .orange)
                        .scaleEffect(animateIn ? 1 : 0)
                        .symbolEffect(.bounce, value: animateIn)
                }

                VStack(spacing: 8) {
                    Text(errors.isEmpty ? "Cleaning Complete!" : "Cleaning Complete with Warnings")
                        .font(.title2.weight(.bold))

                    Text("You freed up disk space successfully.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Stats
                HStack(spacing: 32) {
                    StatBubble(
                        icon: "externaldrive.fill",
                        value: ByteCountFormatter.string(fromByteCount: freedSpace, countStyle: .file),
                        label: "Freed",
                        color: .green
                    )

                    StatBubble(
                        icon: "doc.fill",
                        value: "\(itemCount)",
                        label: "Items Cleaned",
                        color: .blue
                    )

                    if !errors.isEmpty {
                        StatBubble(
                            icon: "exclamationmark.triangle.fill",
                            value: "\(errors.count)",
                            label: "Errors",
                            color: .orange
                        )
                    }
                }

                if !errors.isEmpty {
                    DisclosureGroup("Show errors") {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(errors) { error in
                                    HStack(spacing: 6) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                        Text(error.path.lastPathComponent)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 100)
                    }
                    .padding(.horizontal, 20)
                    .font(.caption)
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(width: 160, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
            .padding(40)
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
            .scaleEffect(animateIn ? 1 : 0.9)
            .opacity(animateIn ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                animateIn = true
            }
        }
    }
}

struct StatBubble: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 100)
    }
}

#Preview("Cleaning Progress") {
    ZStack {
        Color(.windowBackgroundColor)
        CleaningProgressOverlay()
            .environment(CleanerService())
    }
    .frame(width: 800, height: 600)
}

#Preview("Cleaning Complete") {
    CleaningCompleteView(
        freedSpace: 2_500_000_000,
        itemCount: 142,
        errors: [],
        onDismiss: {}
    )
    .frame(width: 800, height: 600)
}
