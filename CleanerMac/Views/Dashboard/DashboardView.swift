import SwiftUI

struct DashboardView: View {
    @Environment(ScannerService.self) private var scannerService
    @Environment(CleanerService.self) private var cleanerService
    @Environment(DiskUsageService.self) private var diskUsageService

    var navigateToCategory: (CleaningCategoryType) -> Void

    @State private var showCleanConfirmation = false
    @State private var cleanedAmount: Int64 = 0
    @State private var showCleanedAlert = false
    @State private var hoveredCategory: CleaningCategoryType?
    @State private var appearAnimation = false

    private var scanResult: ScanResult { scannerService.scanResult }
    private var hasResults: Bool { scanResult.totalCount > 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                heroSection

                if hasResults && !scannerService.isScanning {
                    resultsSummary
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if hasResults || scannerService.isScanning {
                    categoryGrid
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(32)
        }
        .background(backgroundGradient)
        .animation(.spring(duration: 0.6, bounce: 0.3), value: scannerService.isScanning)
        .animation(.spring(duration: 0.6, bounce: 0.3), value: hasResults)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appearAnimation = true
            }
        }
        .alert("Cleaning Complete", isPresented: $showCleanedAlert) {
            Button("OK") { }
        } message: {
            Text("Successfully cleaned \(ByteCountFormatter.string(fromByteCount: cleanedAmount, countStyle: .file))")
        }
        .confirmationDialog(
            "Clean \(scanResult.selectedCount) items?",
            isPresented: $showCleanConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                performClean(permanent: false)
            }
            Button("Delete Permanently", role: .destructive) {
                performClean(permanent: true)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will free up \(ByteCountFormatter.string(fromByteCount: scanResult.selectedSize, countStyle: .file)) of space.")
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 24) {
            ZStack {
                DiskUsageChart(diskUsage: diskUsageService.diskUsage)
                    .frame(width: 220, height: 220)
                    .opacity(appearAnimation ? 1 : 0)
                    .scaleEffect(appearAnimation ? 1 : 0.8)

                if scannerService.isScanning {
                    scanningOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }

            actionButton
        }
        .padding(.top, 8)
    }

    private var scanningOverlay: some View {
        VStack(spacing: 12) {
            ProgressRing(
                progress: scannerService.progress,
                lineWidth: 6,
                size: 100,
                gradientColors: [.blue, .cyan]
            ) {
                VStack(spacing: 2) {
                    Text("\(Int(scannerService.progress * 100))%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    if let category = scannerService.currentCategory {
                        Text(categoryName(category))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var actionButton: some View {
        Group {
            if scannerService.isScanning {
                Button {
                    // Cancel scanning if needed
                } label: {
                    Label("Scanning...", systemImage: "magnifyingglass")
                        .font(.headline)
                        .frame(width: 200, height: 44)
                }
                .buttonStyle(.bordered)
                .disabled(true)
            } else if hasResults {
                HStack(spacing: 16) {
                    Button {
                        startScan()
                    } label: {
                        Label("Rescan", systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.medium))
                            .frame(height: 40)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        showCleanConfirmation = true
                    } label: {
                        Label("Clean \(ByteCountFormatter.string(fromByteCount: scanResult.selectedSize, countStyle: .file))", systemImage: "trash")
                            .font(.headline)
                            .frame(width: 240, height: 44)
                    }
                    .buttonStyle(GradientButtonStyle(colors: [.red, .orange]))
                    .disabled(scanResult.selectedCount == 0)
                }
            } else {
                Button {
                    startScan()
                } label: {
                    Label("Scan My Mac", systemImage: "magnifyingglass")
                        .font(.title3.weight(.semibold))
                        .frame(width: 240, height: 50)
                }
                .buttonStyle(GradientButtonStyle(colors: [.blue, .cyan]))
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .animation(.spring(duration: 0.5), value: scannerService.isScanning)
        .animation(.spring(duration: 0.5), value: hasResults)
    }

    // MARK: - Results Summary

    private var resultsSummary: some View {
        HStack(spacing: 24) {
            SummaryStatView(
                title: "Total Junk Found",
                value: ByteCountFormatter.string(fromByteCount: scanResult.totalSize, countStyle: .file),
                icon: "externaldrive.fill",
                color: .orange
            )

            SummaryStatView(
                title: "Items Found",
                value: "\(scanResult.totalCount)",
                icon: "doc.fill",
                color: .blue
            )

            SummaryStatView(
                title: "Selected",
                value: ByteCountFormatter.string(fromByteCount: scanResult.selectedSize, countStyle: .file),
                icon: "checkmark.circle.fill",
                color: .green
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(CleaningCategoryType.allCases, id: \.self) { category in
                    CategoryCard(
                        category: category,
                        size: categorySize(for: category),
                        itemCount: categoryItemCount(for: category),
                        isScanning: scannerService.isScanning && scannerService.currentCategory == category,
                        isHovered: hoveredCategory == category
                    )
                    .onTapGesture {
                        navigateToCategory(category)
                    }
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hoveredCategory = hovering ? category : nil
                        }
                    }
                }
            }
        }
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

    // MARK: - Helpers

    private func startScan() {
        Task {
            await scannerService.startScan(categories: Set(CleaningCategoryType.allCases))
            diskUsageService.refresh()
        }
    }

    private func performClean(permanent: Bool) {
        Task {
            let allSelected = scanResult.items.values.flatMap { $0 }.filter(\.isSelected)
            let cleaned: Int64
            if permanent {
                cleaned = await cleanerService.clean(items: allSelected)
            } else {
                cleaned = await cleanerService.moveToTrash(items: allSelected)
            }
            cleanedAmount = cleaned
            showCleanedAlert = true
            diskUsageService.refresh()
        }
    }

    private func categorySize(for category: CleaningCategoryType) -> Int64? {
        guard let items = scanResult.items[category], !items.isEmpty else { return nil }
        return items.reduce(0) { $0 + $1.size }
    }

    private func categoryItemCount(for category: CleaningCategoryType) -> Int {
        scanResult.items[category]?.count ?? 0
    }

    private func categoryName(_ category: CleaningCategoryType) -> String {
        switch category {
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

// MARK: - Summary Stat View

struct SummaryStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Gradient Button Style

struct GradientButtonStyle: ButtonStyle {
    let colors: [Color]

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: colors.first?.opacity(0.3) ?? .clear, radius: configuration.isPressed ? 2 : 6, y: configuration.isPressed ? 1 : 3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    DashboardView(navigateToCategory: { _ in })
        .environment(ScannerService())
        .environment(CleanerService())
        .environment(DiskUsageService())
        .frame(width: 900, height: 700)
}
