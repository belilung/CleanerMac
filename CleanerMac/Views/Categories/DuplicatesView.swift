import SwiftUI

struct DuplicateGroup: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
    var items: [ScannedItem]

    var copyCount: Int { items.count }
    var totalWastedSize: Int64 { Int64(max(0, items.count - 1)) * size }
}

struct DuplicatesView: View {
    @Environment(ScannerService.self) private var scannerService
    @Environment(CleanerService.self) private var cleanerService

    @State private var expandedGroups: Set<UUID> = []
    @State private var searchText = ""
    @State private var showCleanConfirmation = false
    @State private var showCleanedAlert = false
    @State private var cleanedAmount: Int64 = 0
    @State private var previewURL: URL?

    private var items: [ScannedItem] {
        scannerService.scanResult.items[.duplicates] ?? []
    }

    private var duplicateGroups: [DuplicateGroup] {
        let grouped = Dictionary(grouping: items) { $0.name }
        return grouped
            .filter { $0.value.count > 1 }
            .map { DuplicateGroup(name: $0.key, size: $0.value.first?.size ?? 0, items: $0.value) }
            .sorted { $0.totalWastedSize > $1.totalWastedSize }
            .filter { group in
                searchText.isEmpty || group.name.localizedCaseInsensitiveContains(searchText)
            }
    }

    private var totalWastedSpace: Int64 {
        duplicateGroups.reduce(0) { $0 + $1.totalWastedSize }
    }

    private var selectedItems: [ScannedItem] {
        items.filter(\.isSelected)
    }

    private var selectedSize: Int64 {
        selectedItems.reduce(0) { $0 + $1.size }
    }

    private var hasScanned: Bool {
        scannerService.scanResult.items[.duplicates] != nil
    }

    var body: some View {
        Group {
            if !hasScanned && !scannerService.isScanning {
                promptToScan
            } else {
                mainContent
            }
        }
        .confirmationDialog(
            "Delete \(selectedItems.count) duplicate files?",
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
            Text("This will free up \(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)).")
        }
        .alert("Cleaning Complete", isPresented: $showCleanedAlert) {
            Button("OK") { }
        } message: {
            Text("Successfully removed \(ByteCountFormatter.string(fromByteCount: cleanedAmount, countStyle: .file)) of duplicates.")
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                Image(systemName: CleaningCategoryType.duplicates.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(CleaningCategoryType.duplicates.color)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 44, height: 44)
                    .background(CleaningCategoryType.duplicates.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Duplicate Files")
                        .font(.title2.weight(.semibold))
                    HStack(spacing: 12) {
                        Text("\(duplicateGroups.count) groups")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Wasted: \(ByteCountFormatter.string(fromByteCount: totalWastedSpace, countStyle: .file))")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()
            }
            .padding(20)

            Divider()

            // Toolbar
            HStack(spacing: 12) {
                Button {
                    selectAllDuplicates()
                } label: {
                    Label("Select All Duplicates", systemImage: "checkmark.circle")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .help("Selects all copies except the first in each group")

                Button {
                    keepOnePerGroup()
                } label: {
                    Label("Keep One Each", systemImage: "1.circle")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .help("Keeps the first copy and selects the rest for deletion")

                Spacer()

                TextField("Search duplicates...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            Divider()

            // Groups list
            if duplicateGroups.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                    Text("No Duplicates Found")
                        .font(.title3.weight(.medium))
                    Text("Your files are clean.")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(duplicateGroups) { group in
                            DuplicateGroupCard(
                                group: group,
                                isExpanded: expandedGroups.contains(group.id),
                                previewURL: $previewURL,
                                onToggleExpand: {
                                    withAnimation(.spring(duration: 0.3)) {
                                        if expandedGroups.contains(group.id) {
                                            expandedGroups.remove(group.id)
                                        } else {
                                            expandedGroups.insert(group.id)
                                        }
                                    }
                                },
                                onKeepOne: {
                                    keepOne(in: group)
                                },
                                onToggleItem: { item in
                                    toggleItem(item)
                                }
                            )
                        }
                    }
                    .padding(20)
                }
            }

            Divider()

            // Bottom bar
            HStack {
                Text("\(selectedItems.count) files selected for removal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                SizeText(bytes: selectedSize, style: .subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Button {
                    showCleanConfirmation = true
                } label: {
                    Label("Remove Duplicates", systemImage: "trash")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(selectedItems.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .background(Color(.windowBackgroundColor))
        .quickLookPreview($previewURL)
    }

    // MARK: - Prompt

    private var promptToScan: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                CleaningCategoryType.duplicates.color.opacity(0.15),
                                CleaningCategoryType.duplicates.color.opacity(0.03)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: CleaningCategoryType.duplicates.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(CleaningCategoryType.duplicates.color)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 8) {
                Text("Duplicate Files")
                    .font(.title.weight(.semibold))
                Text("Find and remove duplicate files to free up space.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    await scannerService.startScan(categories: Set([.duplicates]))
                }
            } label: {
                Label("Find Duplicates", systemImage: "magnifyingglass")
                    .font(.headline)
                    .frame(width: 220, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Actions

    private func selectAllDuplicates() {
        guard var mutableItems = scannerService.scanResult.items[.duplicates] else { return }
        let grouped = Dictionary(grouping: mutableItems) { $0.name }
        for (_, groupItems) in grouped where groupItems.count > 1 {
            for (offset, item) in groupItems.enumerated() {
                if let index = mutableItems.firstIndex(where: { $0.id == item.id }) {
                    mutableItems[index].isSelected = offset > 0
                }
            }
        }
        scannerService.scanResult.items[.duplicates] = mutableItems
    }

    private func keepOnePerGroup() {
        selectAllDuplicates()
    }

    private func keepOne(in group: DuplicateGroup) {
        guard var mutableItems = scannerService.scanResult.items[.duplicates] else { return }
        for (offset, item) in group.items.enumerated() {
            if let index = mutableItems.firstIndex(where: { $0.id == item.id }) {
                mutableItems[index].isSelected = offset > 0
            }
        }
        scannerService.scanResult.items[.duplicates] = mutableItems
    }

    private func toggleItem(_ item: ScannedItem) {
        guard var mutableItems = scannerService.scanResult.items[.duplicates] else { return }
        if let index = mutableItems.firstIndex(where: { $0.id == item.id }) {
            mutableItems[index].isSelected.toggle()
            scannerService.scanResult.items[.duplicates] = mutableItems
        }
    }

    private func performClean(permanent: Bool) {
        Task {
            let cleaned: Int64
            if permanent {
                cleaned = await cleanerService.clean(items: selectedItems)
            } else {
                cleaned = await cleanerService.moveToTrash(items: selectedItems)
            }
            cleanedAmount = cleaned
            showCleanedAlert = true
        }
    }
}

// MARK: - Duplicate Group Card

struct DuplicateGroupCard: View {
    let group: DuplicateGroup
    let isExpanded: Bool
    @Binding var previewURL: URL?
    let onToggleExpand: () -> Void
    let onKeepOne: () -> Void
    let onToggleItem: (ScannedItem) -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            // Group header
            HStack(spacing: 12) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                Image(systemName: "doc.on.doc")
                    .font(.title3)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text("\(group.copyCount) copies")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(ByteCountFormatter.string(fromByteCount: group.size, countStyle: .file) + " each")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text("Wasted: \(ByteCountFormatter.string(fromByteCount: group.totalWastedSize, countStyle: .file))")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.1), in: Capsule())

                Button("Keep One") {
                    onKeepOne()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(12)
            .contentShape(Rectangle())
            .onTapGesture {
                onToggleExpand()
            }

            // Expanded items
            if isExpanded {
                Divider()
                    .padding(.leading, 44)

                VStack(spacing: 0) {
                    ForEach(Array(group.items.enumerated()), id: \.element.id) { offset, item in
                        HStack(spacing: 10) {
                            Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isSelected ? .blue : .secondary)
                                .onTapGesture {
                                    onToggleItem(item)
                                }

                            if offset == 0 {
                                Text("ORIGINAL")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.green.opacity(0.12), in: Capsule())
                            } else {
                                Text("COPY \(offset)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.orange.opacity(0.12), in: Capsule())
                            }

                            Text(item.path.path(percentEncoded: false))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.head)

                            Spacer()

                            Button {
                                previewURL = item.path
                            } label: {
                                Image(systemName: "eye")
                            }
                            .buttonStyle(.borderless)
                            .help("Quick Look")

                            Button {
                                NSWorkspace.shared.activateFileViewerSelecting([item.path])
                            } label: {
                                Image(systemName: "folder")
                            }
                            .buttonStyle(.borderless)
                            .help("Reveal in Finder")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .padding(.leading, 32)

                        if offset < group.items.count - 1 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
                .shadow(color: .black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 8 : 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
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
    DuplicatesView()
        .environment(ScannerService())
        .environment(CleanerService())
        .frame(width: 800, height: 600)
}
