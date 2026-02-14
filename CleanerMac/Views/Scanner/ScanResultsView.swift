import SwiftUI

struct ScanResultsView: View {
    let category: CleaningCategoryType

    @Environment(ScannerService.self) private var scannerService
    @Environment(CleanerService.self) private var cleanerService

    @State private var sortOrder: SortOrder = .size
    @State private var sortAscending = false
    @State private var searchText = ""
    @State private var showCleanConfirmation = false
    @State private var showCleanedAlert = false
    @State private var cleanedAmount: Int64 = 0

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case size = "Size"
        case date = "Date"
    }

    private var items: [ScannedItem] {
        scannerService.scanResult.items[category] ?? []
    }

    private var filteredItems: [ScannedItem] {
        let filtered = searchText.isEmpty
            ? items
            : items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        return filtered.sorted { lhs, rhs in
            let result: Bool
            switch sortOrder {
            case .name:
                result = lhs.name.localizedCompare(rhs.name) == .orderedAscending
            case .size:
                result = lhs.size < rhs.size
            case .date:
                result = (lhs.modificationDate ?? .distantPast) < (rhs.modificationDate ?? .distantPast)
            }
            return sortAscending ? result : !result
        }
    }

    private var selectedItems: [ScannedItem] {
        items.filter(\.isSelected)
    }

    private var totalSize: Int64 {
        items.reduce(0) { $0 + $1.size }
    }

    private var selectedSize: Int64 {
        selectedItems.reduce(0) { $0 + $1.size }
    }

    private var allSelected: Bool {
        !items.isEmpty && items.allSatisfy(\.isSelected)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            toolbarSection
            Divider()

            if items.isEmpty && !scannerService.isScanning {
                emptyState
            } else {
                fileList
            }

            Divider()
            bottomBar
        }
        .background(Color(.windowBackgroundColor))
        .confirmationDialog(
            "Clean \(selectedItems.count) items?",
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
            Text("Successfully cleaned \(ByteCountFormatter.string(fromByteCount: cleanedAmount, countStyle: .file))")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 16) {
            Image(systemName: category.icon)
                .font(.system(size: 32))
                .foregroundStyle(category.color)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 48, height: 48)
                .background(category.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(categoryDisplayName)
                    .font(.title2.weight(.semibold))
                HStack(spacing: 12) {
                    Label(
                        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file),
                        systemImage: "internaldrive"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Label("\(items.count) items", systemImage: "doc")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            riskLevelBadge
        }
        .padding(20)
    }

    private var riskLevelBadge: some View {
        let riskLevel = category.riskLevel

        return Label(riskLevel.rawValue, systemImage: riskLevel == .safe ? "checkmark.shield" : "exclamationmark.shield")
            .font(.caption.weight(.medium))
            .foregroundStyle(riskLevel.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(riskLevel.color.opacity(0.12), in: Capsule())
    }

    // MARK: - Toolbar

    private var toolbarSection: some View {
        HStack(spacing: 12) {
            Button {
                toggleSelectAll()
            } label: {
                Label(allSelected ? "Deselect All" : "Select All", systemImage: allSelected ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline)
            }
            .buttonStyle(.borderless)

            Spacer()

            Picker("Sort by", selection: $sortOrder) {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Button {
                sortAscending.toggle()
            } label: {
                Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
            }
            .buttonStyle(.borderless)

            TextField("Search...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - File List

    private var fileList: some View {
        List {
            ForEach(filteredItems, id: \.id) { item in
                FileRowView(item: item) { toggled in
                    toggleItem(toggled)
                }
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No items found")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Run a scan to find \(categoryDisplayName.lowercased()) on your Mac.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Button {
                Task {
                    await scannerService.startScan(categories: Set([category]))
                }
            } label: {
                Label("Scan Now", systemImage: "magnifyingglass")
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
            Text("\(selectedItems.count) of \(items.count) selected")
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
            .disabled(selectedItems.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func toggleSelectAll() {
        let newValue = !allSelected
        for item in items {
            if var mutableItems = scannerService.scanResult.items[category],
               let index = mutableItems.firstIndex(where: { $0.id == item.id }) {
                mutableItems[index].isSelected = newValue
                scannerService.scanResult.items[category] = mutableItems
            }
        }
    }

    private func toggleItem(_ item: ScannedItem) {
        if var mutableItems = scannerService.scanResult.items[category],
           let index = mutableItems.firstIndex(where: { $0.id == item.id }) {
            mutableItems[index].isSelected.toggle()
            scannerService.scanResult.items[category] = mutableItems
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

    private var categoryDisplayName: String {
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

#Preview {
    ScanResultsView(category: .systemJunk)
        .environment(ScannerService())
        .environment(CleanerService())
        .frame(width: 700, height: 500)
}
