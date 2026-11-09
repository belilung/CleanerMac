import SwiftUI

struct StartupItemsView: View {
    @Environment(StartupItemsService.self) private var startupService

    @State private var searchText = ""

    private var filteredItems: [StartupItem] {
        if searchText.isEmpty {
            return startupService.startupItems
        }
        return startupService.startupItems.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.bundleIdentifier?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var enabledCount: Int {
        startupService.startupItems.filter(\.isEnabled).count
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()

            if startupService.isScanning {
                scanningView
            } else if startupService.startupItems.isEmpty {
                promptToScan
            } else {
                itemsList
            }
        }
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 16) {
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 44, height: 44)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text("Startup Items")
                    .font(.title2.weight(.semibold))
                Text("\(enabledCount) items run at login")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !startupService.startupItems.isEmpty {
                Button {
                    Task {
                        await startupService.scan()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
            }

            TextField("Search...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
        }
        .padding(20)
    }

    // MARK: - Scanning

    private var scanningView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text("Scanning startup items...")
                .font(.headline)
                .foregroundStyle(.secondary)
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
                            colors: [.orange.opacity(0.15), .orange.opacity(0.03)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 8) {
                Text("Startup Items")
                    .font(.title.weight(.semibold))
                Text("Manage apps and services that launch when you log in.\nDisable unnecessary items to speed up your Mac's boot time.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            Button {
                Task {
                    await startupService.scan()
                }
            } label: {
                Label("Scan Startup Items", systemImage: "magnifyingglass")
                    .font(.headline)
                    .frame(width: 220, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Items List

    private var itemsList: some View {
        VStack(spacing: 0) {
            // Info banner
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text("Toggle items off to prevent them from launching at login. Changes take effect after restart.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(12)
            .background(.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 20)
            .padding(.top, 12)

            List {
                ForEach(filteredItems) { item in
                    StartupItemRow(item: item) {
                        startupService.toggleItem(item)
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }
}

// MARK: - Startup Item Row

struct StartupItemRow: View {
    let item: StartupItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()

            Image(systemName: item.type == .launchAgent ? "gearshape.2" : "person.crop.circle")
                .font(.title3)
                .foregroundStyle(item.isEnabled ? .blue : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(item.isEnabled ? .primary : .secondary)

                if let bundleId = item.bundleIdentifier {
                    Text(bundleId)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(item.type.rawValue)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.fill.tertiary, in: Capsule())

            // Status indicator
            Circle()
                .fill(item.isEnabled ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    StartupItemsView()
        .environment(StartupItemsService())
        .frame(width: 700, height: 500)
}
