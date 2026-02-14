import SwiftUI

// MARK: - Browser Data Models

enum BrowserType: String, CaseIterable, Identifiable {
    case safari = "Safari"
    case chrome = "Google Chrome"
    case firefox = "Firefox"
    case edge = "Microsoft Edge"
    case brave = "Brave"
    case opera = "Opera"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .safari: return "safari"
        case .chrome: return "globe"
        case .firefox: return "flame"
        case .edge: return "globe.americas"
        case .brave: return "shield.lefthalf.filled"
        case .opera: return "circle.grid.cross"
        }
    }

    var color: Color {
        switch self {
        case .safari: return .blue
        case .chrome: return .green
        case .firefox: return .orange
        case .edge: return .cyan
        case .brave: return .red
        case .opera: return .red
        }
    }

    var applicationPath: String {
        "/Applications/\(rawValue).app"
    }

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: applicationPath)
    }
}

enum BrowserDataType: String, CaseIterable, Identifiable {
    case cache = "Cache"
    case history = "History"
    case cookies = "Cookies"
    case downloads = "Downloads History"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cache: return "internaldrive"
        case .history: return "clock"
        case .cookies: return "birthday.cake"
        case .downloads: return "arrow.down.circle"
        }
    }
}

struct BrowserCleanOption: Identifiable {
    let id = UUID()
    let browser: BrowserType
    let dataType: BrowserDataType
    var isSelected: Bool
    var size: Int64
}

// MARK: - Privacy View

struct PrivacyView: View {
    @Environment(ScannerService.self) private var scannerService
    @Environment(CleanerService.self) private var cleanerService

    @State private var browserOptions: [BrowserCleanOption] = []
    @State private var showCleanConfirmation = false
    @State private var showCleanedAlert = false
    @State private var cleanedAmount: Int64 = 0
    @State private var hasInitialized = false

    private var installedBrowsers: [BrowserType] {
        BrowserType.allCases.filter(\.isInstalled)
    }

    private var selectedOptions: [BrowserCleanOption] {
        browserOptions.filter(\.isSelected)
    }

    private var selectedSize: Int64 {
        selectedOptions.reduce(0) { $0 + $1.size }
    }

    private var hasScanned: Bool {
        scannerService.scanResult.items[.browserData] != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()

            if !hasScanned && !scannerService.isScanning {
                promptToScan
            } else {
                browserList
            }

            Divider()
            bottomBar
        }
        .background(Color(.windowBackgroundColor))
        .onAppear {
            if !hasInitialized {
                initializeOptions()
                hasInitialized = true
            }
        }
        .onChange(of: scannerService.scanResult.items[.browserData]) { _, _ in
            updateSizes()
        }
        .confirmationDialog(
            "Clean browser data?",
            isPresented: $showCleanConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clean Selected Data", role: .destructive) {
                performClean()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            let cookiesSelected = selectedOptions.contains { $0.dataType == .cookies }
            if cookiesSelected {
                Text("Warning: Cleaning cookies will log you out of websites. This will free up \(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)).")
            } else {
                Text("This will free up \(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)).")
            }
        }
        .alert("Cleaning Complete", isPresented: $showCleanedAlert) {
            Button("OK") { }
        } message: {
            Text("Successfully cleaned \(ByteCountFormatter.string(fromByteCount: cleanedAmount, countStyle: .file)) of browser data.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 16) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 28))
                .foregroundStyle(.indigo)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 44, height: 44)
                .background(.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text("Privacy & Browser Data")
                    .font(.title2.weight(.semibold))
                Text("Clean browser caches, history, and cookies")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if installedBrowsers.count > 0 {
                Text("\(installedBrowsers.count) browsers found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.fill.tertiary, in: Capsule())
            }
        }
        .padding(20)
    }

    // MARK: - Browser List

    private var browserList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Cookie warning banner
                if selectedOptions.contains(where: { $0.dataType == .cookies }) {
                    cookieWarning
                }

                ForEach(installedBrowsers) { browser in
                    BrowserSectionCard(
                        browser: browser,
                        options: optionsForBrowser(browser),
                        onToggle: { dataType in
                            toggleOption(browser: browser, dataType: dataType)
                        }
                    )
                }

                if installedBrowsers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                        Text("No supported browsers detected")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(40)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Cookie Warning

    private var cookieWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Cookie Removal Warning")
                    .font(.subheadline.weight(.semibold))
                Text("Removing cookies will log you out of all websites in the selected browsers.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.yellow.opacity(0.3), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: selectedOptions.contains(where: { $0.dataType == .cookies }))
    }

    // MARK: - Prompt

    private var promptToScan: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "globe")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("Scan to detect browser data")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await scannerService.startScan(categories: Set([.browserData]))
                }
            } label: {
                Label("Scan Browser Data", systemImage: "magnifyingglass")
                    .font(.headline)
                    .frame(width: 220, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Text("\(selectedOptions.count) data types selected")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            SizeText(bytes: selectedSize, style: .subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Button {
                showCleanConfirmation = true
            } label: {
                Label("Clean Selected", systemImage: "trash")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(selectedOptions.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    private func initializeOptions() {
        browserOptions = installedBrowsers.flatMap { browser in
            BrowserDataType.allCases.map { dataType in
                BrowserCleanOption(
                    browser: browser,
                    dataType: dataType,
                    isSelected: dataType == .cache,
                    size: 0
                )
            }
        }
    }

    private func updateSizes() {
        guard let items = scannerService.scanResult.items[.browserData] else { return }
        // Distribute sizes across browser options based on items
        let totalSize = items.reduce(0) { $0 + $1.size }
        let perOption = totalSize / max(1, Int64(browserOptions.count))

        for index in browserOptions.indices {
            browserOptions[index].size = perOption
        }
    }

    private func optionsForBrowser(_ browser: BrowserType) -> [BrowserCleanOption] {
        browserOptions.filter { $0.browser == browser }
    }

    private func toggleOption(browser: BrowserType, dataType: BrowserDataType) {
        if let index = browserOptions.firstIndex(where: { $0.browser == browser && $0.dataType == dataType }) {
            browserOptions[index].isSelected.toggle()
        }
    }

    private func performClean() {
        Task {
            let allItems = scannerService.scanResult.items[.browserData] ?? []
            let cleaned = await cleanerService.moveToTrash(items: allItems.filter(\.isSelected))
            cleanedAmount = cleaned
            showCleanedAlert = true
        }
    }
}

// MARK: - Browser Section Card

struct BrowserSectionCard: View {
    let browser: BrowserType
    let options: [BrowserCleanOption]
    let onToggle: (BrowserDataType) -> Void

    @State private var isHovered = false

    private var totalSize: Int64 {
        options.reduce(0) { $0 + $1.size }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Browser header
            HStack(spacing: 12) {
                Image(systemName: browser.icon)
                    .font(.title2)
                    .foregroundStyle(browser.color)
                    .frame(width: 36, height: 36)
                    .background(browser.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(browser.rawValue)
                        .font(.headline)
                    if totalSize > 0 {
                        Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(16)

            Divider()
                .padding(.leading, 64)

            // Data type toggles
            VStack(spacing: 0) {
                ForEach(options) { option in
                    HStack(spacing: 12) {
                        Toggle(isOn: Binding(
                            get: { option.isSelected },
                            set: { _ in onToggle(option.dataType) }
                        )) {
                            HStack(spacing: 8) {
                                Image(systemName: option.dataType.icon)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)

                                Text(option.dataType.rawValue)
                                    .font(.subheadline)
                            }
                        }
                        .toggleStyle(.checkbox)

                        Spacer()

                        if option.size > 0 {
                            Text(ByteCountFormatter.string(fromByteCount: option.size, countStyle: .file))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .padding(.leading, 48)
                }
            }
            .padding(.vertical, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 8 : 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.separator.opacity(0.5), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    PrivacyView()
        .environment(ScannerService())
        .environment(CleanerService())
        .frame(width: 700, height: 600)
}
