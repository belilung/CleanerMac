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

    /// Items that are safe to clean (auto-selected, no personal data)
    private var safeSelectedSize: Int64 {
        scanResult.items
            .filter { $0.key.riskLevel == .safe || $0.key.riskLevel == .moderate }
            .values.flatMap { $0 }
            .filter(\.isSelected)
            .reduce(0) { $0 + $1.size }
    }

    private var safeSelectedCount: Int {
        scanResult.items
            .filter { $0.key.riskLevel == .safe || $0.key.riskLevel == .moderate }
            .values.flatMap { $0 }
            .filter(\.isSelected)
            .count
    }

    /// Items that need review (large files, duplicates, etc.)
    private var reviewItemsSize: Int64 {
        scanResult.items
            .filter { $0.key.riskLevel == .caution }
            .values.flatMap { $0 }
            .reduce(0) { $0 + $1.size }
    }

    private var reviewItemsCount: Int {
        scanResult.items
            .filter { $0.key.riskLevel == .caution }
            .values.flatMap { $0 }
            .count
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 32) {
                    heroSection

                    if hasResults && !scannerService.isScanning {
                        cleaningSection
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

            // Floating scan progress bubble
            if scannerService.isScanning {
                VStack {
                    Spacer()
                    scanProgressBubble
                        .padding(.bottom, 24)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
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
            Text("Freed \(ByteCountFormatter.string(fromByteCount: cleanedAmount, countStyle: .file)) of disk space.")
        }
        .confirmationDialog(
            "Clean \(safeSelectedCount) safe items?",
            isPresented: $showCleanConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash") {
                performSafeClean(permanent: false)
            }
            Button("Delete Permanently", role: .destructive) {
                performSafeClean(permanent: true)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will free up \(ByteCountFormatter.string(fromByteCount: safeSelectedSize, countStyle: .file)). Only safe items (caches, logs, temp files) will be cleaned.")
        }
    }

    // MARK: - Floating Scan Progress Bubble

    private var scanProgressBubble: some View {
        HStack(spacing: 16) {
            // Animated progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: scannerService.progress)
                    .stroke(
                        LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: scannerService.progress)

                Text("\(Int(scannerService.progress * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Scanning...")
                    .font(.subheadline.weight(.semibold))

                if let category = scannerService.currentCategory {
                    Text(category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Live size counter
            VStack(alignment: .trailing, spacing: 3) {
                Text(ByteCountFormatter.string(fromByteCount: scanResult.totalSize, countStyle: .file))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.easeInOut, value: scanResult.totalSize)

                Text("found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .padding(.horizontal, 32)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 24) {
            DiskUsageChart(diskUsage: diskUsageService.diskUsage)
                .frame(width: 220, height: 220)
                .opacity(appearAnimation ? 1 : 0)
                .scaleEffect(appearAnimation ? 1 : 0.8)

            if !scannerService.isScanning && !hasResults {
                Button {
                    startScan()
                } label: {
                    Label("Scan My Mac", systemImage: "magnifyingglass")
                        .font(.title3.weight(.semibold))
                        .frame(width: 240, height: 50)
                }
                .buttonStyle(GradientButtonStyle(colors: [.blue, .cyan]))
                .keyboardShortcut(.return, modifiers: .command)
            } else if !scannerService.isScanning && hasResults {
                Button {
                    startScan()
                } label: {
                    Label("Rescan", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.medium))
                        .frame(height: 36)
                        .padding(.horizontal, 20)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Cleaning Section (two-tier)

    private var cleaningSection: some View {
        VStack(spacing: 20) {
            // Results summary
            HStack(spacing: 24) {
                SummaryStatView(
                    title: "Total Found",
                    value: ByteCountFormatter.string(fromByteCount: scanResult.totalSize, countStyle: .file),
                    icon: "externaldrive.fill",
                    color: .orange
                )
                SummaryStatView(
                    title: "Safe to Clean",
                    value: ByteCountFormatter.string(fromByteCount: safeSelectedSize, countStyle: .file),
                    icon: "checkmark.shield.fill",
                    color: .green
                )
                SummaryStatView(
                    title: "Needs Review",
                    value: ByteCountFormatter.string(fromByteCount: reviewItemsSize, countStyle: .file),
                    icon: "eye.fill",
                    color: .orange
                )
            }

            // Two-tier cleaning buttons
            HStack(spacing: 16) {
                // Safe clean button — primary action
                Button {
                    showCleanConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Clean Safe Items")
                                .font(.subheadline.weight(.semibold))
                            Text(ByteCountFormatter.string(fromByteCount: safeSelectedSize, countStyle: .file))
                                .font(.caption)
                                .opacity(0.8)
                        }
                    }
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(CleanButtonStyle(color: .blue))
                .disabled(safeSelectedCount == 0)

                // Review button — secondary action
                if reviewItemsCount > 0 {
                    Button {
                        // Navigate to first caution category with items
                        if let first = CleaningCategoryType.allCases.first(where: {
                            $0.riskLevel == .caution && (scanResult.items[$0]?.isEmpty == false)
                        }) {
                            navigateToCategory(first)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "eye.fill")
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Review \(reviewItemsCount) Items")
                                    .font(.subheadline.weight(.semibold))
                                Text(ByteCountFormatter.string(fromByteCount: reviewItemsSize, countStyle: .file))
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                        }
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
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

    private func performSafeClean(permanent: Bool) {
        Task {
            // Only clean items from safe/moderate categories
            let safeItems = scanResult.items
                .filter { $0.key.riskLevel == .safe || $0.key.riskLevel == .moderate }
                .values.flatMap { $0 }
                .filter(\.isSelected)

            let cleaned: Int64
            if permanent {
                cleaned = await cleanerService.clean(items: safeItems)
            } else {
                cleaned = await cleanerService.moveToTrash(items: safeItems)
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

// MARK: - Clean Button Style (solid red + white text)

struct CleanButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
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
