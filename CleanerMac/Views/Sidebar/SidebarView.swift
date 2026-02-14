import SwiftUI

struct SidebarView: View {
    @Binding var selection: NavigationItem?
    @Environment(ScannerService.self) private var scannerService

    var body: some View {
        List(selection: $selection) {
            NavigationLink(value: NavigationItem.dashboard) {
                Label {
                    Text("Dashboard")
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "gauge.medium")
                        .foregroundStyle(.blue)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .listItemTint(.blue)

            Section("Categories") {
                ForEach(CleaningCategoryType.allCases, id: \.self) { category in
                    NavigationLink(value: NavigationItem.category(category)) {
                        SidebarCategoryRow(
                            category: category,
                            isScanning: scannerService.isScanning && scannerService.currentCategory == category,
                            scannedSize: scannedSize(for: category)
                        )
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    // Toggle sidebar visibility handled by system
                } label: {
                    Image(systemName: "sidebar.leading")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Divider()
                if scannerService.isScanning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Scanning...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(scannerService.progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private func scannedSize(for category: CleaningCategoryType) -> Int64? {
        guard scannerService.scanResult.isComplete || !scannerService.isScanning else { return nil }
        guard let items = scannerService.scanResult.items[category], !items.isEmpty else { return nil }
        return items.reduce(0) { $0 + $1.size }
    }
}

struct SidebarCategoryRow: View {
    let category: CleaningCategoryType
    let isScanning: Bool
    let scannedSize: Int64?

    var body: some View {
        Label {
            HStack {
                Text(category.name)
                    .lineLimit(1)

                Spacer()

                if isScanning {
                    ProgressView()
                        .controlSize(.small)
                        .transition(.opacity)
                } else if let size = scannedSize, size > 0 {
                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.fill.tertiary, in: Capsule())
                        .transition(.scale.combined(with: .opacity))
                }
            }
        } icon: {
            Image(systemName: category.icon)
                .foregroundStyle(category.color)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 14))
        }
        .animation(.easeInOut(duration: 0.3), value: isScanning)
        .animation(.spring(duration: 0.4), value: scannedSize)
    }
}

private extension CleaningCategoryType {
    var name: String {
        switch self {
        case .systemJunk: return "System Junk"
        case .userCache: return "User Cache"
        case .developerJunk: return "Developer Junk"
        case .largeFiles: return "Large Files"
        case .duplicates: return "Duplicates"
        case .browserData: return "Browser Data"
        case .mailAttachments: return "Mail Attachments"
        case .iOSBackups: return "iOS Backups"
        case .trash: return "Trash"
        }
    }
}

#Preview {
    SidebarView(selection: .constant(.dashboard))
        .environment(ScannerService())
}
