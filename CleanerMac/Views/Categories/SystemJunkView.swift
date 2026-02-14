import SwiftUI

struct SystemJunkView: View {
    @Environment(ScannerService.self) private var scannerService

    private var hasScanned: Bool {
        scannerService.scanResult.items[.systemJunk] != nil
    }

    var body: some View {
        Group {
            if hasScanned || scannerService.isScanning {
                ScanResultsView(category: .systemJunk)
            } else {
                promptToScan
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasScanned)
    }

    private var promptToScan: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                CleaningCategoryType.systemJunk.color.opacity(0.15),
                                CleaningCategoryType.systemJunk.color.opacity(0.03)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: CleaningCategoryType.systemJunk.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(CleaningCategoryType.systemJunk.color)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 8) {
                Text("System Junk")
                    .font(.title.weight(.semibold))

                Text("Scan your Mac to find system caches, logs, and temporary files that can be safely removed.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            Button {
                Task {
                    await scannerService.startScan(categories: Set([.systemJunk]))
                }
            } label: {
                Label("Scan for System Junk", systemImage: "magnifyingglass")
                    .font(.headline)
                    .frame(width: 220, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text(CleaningCategoryType.systemJunk.description)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: 350)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

#Preview {
    SystemJunkView()
        .environment(ScannerService())
        .environment(CleanerService())
        .frame(width: 700, height: 500)
}
