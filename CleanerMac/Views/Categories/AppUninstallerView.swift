import SwiftUI

struct AppUninstallerView: View {
    @Environment(AppUninstallerService.self) private var appService
    @Environment(CleanerService.self) private var cleanerService

    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .size
    @State private var selectedApp: InstalledApp?
    @State private var showUninstallConfirmation = false

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case size = "Size"
        case lastUsed = "Last Used"
    }

    private var filteredApps: [InstalledApp] {
        var apps = appService.installedApps

        if !searchText.isEmpty {
            apps = apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        switch sortOrder {
        case .name:
            apps.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .size:
            apps.sort { $0.totalSize > $1.totalSize }
        case .lastUsed:
            apps.sort { ($0.lastUsedDate ?? .distantPast) < ($1.lastUsedDate ?? .distantPast) }
        }

        return apps
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()

            if appService.isScanning {
                scanningView
            } else if appService.installedApps.isEmpty {
                promptToScan
            } else {
                HStack(spacing: 0) {
                    appList
                    if selectedApp != nil {
                        Divider()
                        appDetail
                    }
                }
            }
        }
        .background(Color(.windowBackgroundColor))
        .confirmationDialog(
            "Uninstall \(selectedApp?.name ?? "")?",
            isPresented: $showUninstallConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move App & Leftovers to Trash", role: .destructive) {
                if let app = selectedApp {
                    uninstallApp(app)
                }
            }
            Button("Remove Leftovers Only") {
                if let app = selectedApp {
                    removeLeftoversOnly(app)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let app = selectedApp {
                Text("App size: \(ByteCountFormatter.string(fromByteCount: app.size, countStyle: .file))\nLeftovers: \(ByteCountFormatter.string(fromByteCount: app.totalLeftoverSize, countStyle: .file))")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 16) {
            Image(systemName: "app.badge.checkmark")
                .font(.system(size: 28))
                .foregroundStyle(.purple)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 44, height: 44)
                .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text("App Manager")
                    .font(.title2.weight(.semibold))
                Text("\(appService.installedApps.count) apps installed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !appService.installedApps.isEmpty {
                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }

            TextField("Search apps...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
        }
        .padding(20)
    }

    // MARK: - Scanning View

    private var scanningView: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressRing(
                progress: appService.progress,
                lineWidth: 6,
                size: 80,
                gradientColors: [.purple, .pink]
            ) {
                Text("\(Int(appService.progress * 100))%")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            VStack(spacing: 8) {
                Text("Scanning Applications...")
                    .font(.headline)

                if let name = appService.currentAppName {
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Prompt

    private var promptToScan: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.15), .purple.opacity(0.03)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "app.badge.checkmark")
                    .font(.system(size: 56))
                    .foregroundStyle(.purple)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 8) {
                Text("App Manager")
                    .font(.title.weight(.semibold))
                Text("Find installed apps, their sizes, and leftover files.\nUninstall apps completely with one click.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            Button {
                Task {
                    await appService.scanInstalledApps()
                }
            } label: {
                Label("Scan Applications", systemImage: "magnifyingglass")
                    .font(.headline)
                    .frame(width: 220, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - App List

    private var appList: some View {
        List(selection: $selectedApp) {
            ForEach(filteredApps) { app in
                AppRowView(app: app)
                    .tag(app)
                    .contentShape(Rectangle())
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .frame(minWidth: 350)
    }

    // MARK: - App Detail

    private var appDetail: some View {
        Group {
            if let app = selectedApp {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // App header
                        HStack(spacing: 16) {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 64, height: 64)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(app.name)
                                    .font(.title2.weight(.bold))
                                Text(app.bundleIdentifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let date = app.lastUsedDate {
                                    Text("Last used: \(date, style: .relative) ago")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }

                        // Size info
                        HStack(spacing: 24) {
                            VStack(spacing: 4) {
                                Text("App Size")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(ByteCountFormatter.string(fromByteCount: app.size, countStyle: .file))
                                    .font(.title3.weight(.semibold))
                                    .monospacedDigit()
                            }

                            VStack(spacing: 4) {
                                Text("Leftovers")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(ByteCountFormatter.string(fromByteCount: app.totalLeftoverSize, countStyle: .file))
                                    .font(.title3.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(app.totalLeftoverSize > 0 ? .orange : .green)
                            }

                            VStack(spacing: 4) {
                                Text("Total")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(ByteCountFormatter.string(fromByteCount: app.totalSize, countStyle: .file))
                                    .font(.title3.weight(.bold))
                                    .monospacedDigit()
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                        // Leftovers
                        if !app.leftovers.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Leftover Files")
                                    .font(.headline)

                                ForEach(app.leftovers) { leftover in
                                    HStack(spacing: 10) {
                                        Image(systemName: leftoverIcon(for: leftover.type))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 20)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(leftover.name)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                            Text(leftover.type.rawValue)
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }

                                        Spacer()

                                        Text(ByteCountFormatter.string(fromByteCount: leftover.size, countStyle: .file))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .monospacedDigit()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("No leftover files found")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        }

                        Spacer()

                        // Action buttons
                        HStack {
                            Button {
                                NSWorkspace.shared.activateFileViewerSelecting([app.path])
                            } label: {
                                Label("Show in Finder", systemImage: "folder")
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            if !app.leftovers.isEmpty {
                                Button {
                                    showUninstallConfirmation = true
                                } label: {
                                    Label("Uninstall", systemImage: "trash")
                                        .font(.subheadline.weight(.medium))
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                            }
                        }
                    }
                    .padding(24)
                }
                .frame(minWidth: 350)
            }
        }
    }

    // MARK: - Actions

    private func uninstallApp(_ app: InstalledApp) {
        Task {
            // Move app to trash
            var items: [ScannedItem] = []
            items.append(ScannedItem(
                path: app.path,
                name: app.name,
                size: app.size,
                category: .systemJunk,
                modificationDate: nil
            ))

            // Add leftovers
            for leftover in app.leftovers {
                items.append(ScannedItem(
                    path: leftover.path,
                    name: leftover.name,
                    size: leftover.size,
                    category: .systemJunk,
                    modificationDate: nil
                ))
            }

            _ = await cleanerService.moveToTrash(items: items)
            selectedApp = nil
            await appService.scanInstalledApps()
        }
    }

    private func removeLeftoversOnly(_ app: InstalledApp) {
        Task {
            let items = app.leftovers.map {
                ScannedItem(
                    path: $0.path,
                    name: $0.name,
                    size: $0.size,
                    category: .systemJunk,
                    modificationDate: nil
                )
            }
            _ = await cleanerService.moveToTrash(items: items)
            await appService.scanInstalledApps()
        }
    }

    private func leftoverIcon(for type: AppLeftover.LeftoverType) -> String {
        switch type {
        case .cache: return "internaldrive"
        case .preferences: return "gearshape"
        case .applicationSupport: return "folder"
        case .containers: return "shippingbox"
        case .savedState: return "clock.arrow.circlepath"
        case .cookies: return "globe"
        case .logs: return "doc.text"
        case .other: return "questionmark.folder"
        }
    }
}

// MARK: - App Row View

struct AppRowView: View {
    let app: InstalledApp

    var body: some View {
        HStack(spacing: 12) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app")
                    .font(.title2)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(ByteCountFormatter.string(fromByteCount: app.totalSize, countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !app.leftovers.isEmpty {
                        Text("\(app.leftovers.count) leftovers")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(.orange.opacity(0.12), in: Capsule())
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AppUninstallerView()
        .environment(AppUninstallerService())
        .environment(CleanerService())
        .frame(width: 900, height: 600)
}
