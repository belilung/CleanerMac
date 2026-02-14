import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            ExclusionsSettingsTab()
                .tabItem {
                    Label("Exclusions", systemImage: "nosign")
                }

            AboutSettingsTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 520, height: 400)
    }
}

// MARK: - General Settings

struct GeneralSettingsTab: View {
    @AppStorage("deleteMethod") private var deleteMethod: DeleteMethod = .moveToTrash
    @AppStorage("largeFileThreshold") private var largeFileThreshold: Double = 100
    @AppStorage("showConfirmation") private var showConfirmation = true
    @AppStorage("scanOnLaunch") private var scanOnLaunch = false

    enum DeleteMethod: String, CaseIterable {
        case moveToTrash = "Move to Trash"
        case permanentDelete = "Permanent Delete"

        var description: String {
            switch self {
            case .moveToTrash: return "Files are moved to the Trash and can be recovered"
            case .permanentDelete: return "Files are permanently deleted and cannot be recovered"
            }
        }

        var icon: String {
            switch self {
            case .moveToTrash: return "trash"
            case .permanentDelete: return "xmark.bin"
            }
        }
    }

    var body: some View {
        Form {
            Section {
                Picker("Deletion method:", selection: $deleteMethod) {
                    ForEach(DeleteMethod.allCases, id: \.self) { method in
                        Label(method.rawValue, systemImage: method.icon)
                            .tag(method)
                    }
                }
                .pickerStyle(.radioGroup)

                Text(deleteMethod.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if deleteMethod == .permanentDelete {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("Permanently deleted files cannot be recovered.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .padding(8)
                    .background(.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                }
            } header: {
                Text("Deletion")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Large file threshold:")
                        Spacer()
                        Text("\(Int(largeFileThreshold)) MB")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $largeFileThreshold, in: 10...2000, step: 10)
                    Text("Files larger than this will appear in Large Files.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Scanning")
            }

            Section {
                Toggle("Show confirmation before cleaning", isOn: $showConfirmation)
                Toggle("Scan automatically on launch", isOn: $scanOnLaunch)
            } header: {
                Text("Behavior")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Exclusions Settings

struct ExclusionsSettingsTab: View {
    @AppStorage("excludedPaths") private var excludedPathsData: Data = Data()

    @State private var excludedPaths: [String] = []
    @State private var selectedPath: String?
    @State private var showFilePicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Excluded Paths")
                    .font(.headline)
                Text("Files and folders in these locations will be skipped during scanning.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            // List
            List(selection: $selectedPath) {
                if excludedPaths.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "folder.badge.minus")
                                .font(.title2)
                                .foregroundStyle(.tertiary)
                            Text("No exclusions")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 20)
                } else {
                    ForEach(excludedPaths, id: \.self) { path in
                        HStack(spacing: 10) {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            Text(path)
                                .font(.subheadline)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .tag(path)
                    }
                }
            }
            .listStyle(.bordered(alternatesRowBackgrounds: true))

            // Toolbar
            HStack(spacing: 8) {
                Button {
                    addExclusion()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add exclusion path")

                Button {
                    removeSelectedExclusion()
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(selectedPath == nil)
                .help("Remove selected exclusion")

                Spacer()

                Text("\(excludedPaths.count) exclusion\(excludedPaths.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
        }
        .onAppear {
            loadExcludedPaths()
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                let path = url.path(percentEncoded: false)
                if !excludedPaths.contains(path) {
                    excludedPaths.append(path)
                    saveExcludedPaths()
                }
            }
        }
    }

    private func addExclusion() {
        showFilePicker = true
    }

    private func removeSelectedExclusion() {
        guard let selected = selectedPath else { return }
        excludedPaths.removeAll { $0 == selected }
        selectedPath = nil
        saveExcludedPaths()
    }

    private func loadExcludedPaths() {
        if let paths = try? JSONDecoder().decode([String].self, from: excludedPathsData) {
            excludedPaths = paths
        }
    }

    private func saveExcludedPaths() {
        if let data = try? JSONEncoder().encode(excludedPaths) {
            excludedPathsData = data
        }
    }
}

// MARK: - About Settings

struct AboutSettingsTab: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: .blue.opacity(0.3), radius: 12, y: 4)

                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                Text("CleanerMac")
                    .font(.title.weight(.bold))

                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 4) {
                Text("A premium macOS cleaning utility")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Built with SwiftUI")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Divider()
                .frame(width: 200)

            VStack(spacing: 8) {
                Link(destination: URL(string: "https://github.com")!) {
                    Label("GitHub", systemImage: "link")
                        .font(.subheadline)
                }

                Link(destination: URL(string: "mailto:support@cleanermac.app")!) {
                    Label("Contact Support", systemImage: "envelope")
                        .font(.subheadline)
                }
            }

            Spacer()

            Text("\u{00A9} 2025 CleanerMac. All rights reserved.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    SettingsView()
}
