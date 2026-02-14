import SwiftUI
import QuickLookUI

struct LargeFilesView: View {
    @Environment(ScannerService.self) private var scannerService
    @Environment(CleanerService.self) private var cleanerService

    @State private var sortOrder = [KeyPathComparator(\ScannedItem.size, order: .reverse)]
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var sizeThreshold: Double = 50
    @State private var searchText = ""
    @State private var showCleanConfirmation = false
    @State private var showCleanedAlert = false
    @State private var cleanedAmount: Int64 = 0
    @State private var quickLookURL: URL?

    private var items: [ScannedItem] {
        scannerService.scanResult.items[.largeFiles] ?? []
    }

    private var filteredItems: [ScannedItem] {
        let thresholdBytes = Int64(sizeThreshold * 1_000_000)
        var result = items.filter { $0.size >= thresholdBytes }

        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return result.sorted(using: sortOrder)
    }

    private var selectedItems: [ScannedItem] {
        items.filter { selectedItemIDs.contains($0.id) }
    }

    private var selectedSize: Int64 {
        selectedItems.reduce(0) { $0 + $1.size }
    }

    private var hasScanned: Bool {
        scannerService.scanResult.items[.largeFiles] != nil
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
            "Delete \(selectedItems.count) large files?",
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

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                Image(systemName: CleaningCategoryType.largeFiles.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(CleaningCategoryType.largeFiles.color)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 44, height: 44)
                    .background(CleaningCategoryType.largeFiles.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Large Files")
                        .font(.title2.weight(.semibold))
                    Text("\(filteredItems.count) files above \(Int(sizeThreshold)) MB")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(20)

            Divider()

            // Filter bar
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Text("Min size:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Slider(value: $sizeThreshold, in: 10...1000, step: 10)
                        .frame(width: 160)
                    Text("\(Int(sizeThreshold)) MB")
                        .font(.subheadline)
                        .monospacedDigit()
                        .frame(width: 60)
                }

                Spacer()

                TextField("Search files...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            Divider()

            // Table
            Table(filteredItems, selection: $selectedItemIDs, sortOrder: $sortOrder) {
                TableColumn("Name", value: \.name) { item in
                    HStack(spacing: 8) {
                        fileIcon(for: item)
                        Text(item.name)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .width(min: 200, ideal: 300)

                TableColumn("Size", value: \.size) { item in
                    Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .width(min: 80, ideal: 100)

                TableColumn("Location") { item in
                    Text(item.path.deletingLastPathComponent().path(percentEncoded: false))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
                .width(min: 150, ideal: 250)

                TableColumn("Date Modified") { item in
                    if let date = item.modificationDate {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("--")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .width(min: 100, ideal: 120)

                TableColumn("Type") { item in
                    Text(item.path.pathExtension.uppercased())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.fill.tertiary, in: Capsule())
                }
                .width(min: 60, ideal: 80)
            }
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .contextMenu(forSelectionType: UUID.self) { ids in
                if !ids.isEmpty {
                    Button {
                        revealInFinder(ids: ids)
                    } label: {
                        Label("Reveal in Finder", systemImage: "folder")
                    }
                    Button {
                        if let firstID = ids.first,
                           let item = items.first(where: { $0.id == firstID }) {
                            quickLookURL = item.path
                        }
                    } label: {
                        Label("Quick Look", systemImage: "eye")
                    }
                    Divider()
                    Button(role: .destructive) {
                        selectedItemIDs = ids
                        showCleanConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            Divider()

            // Bottom bar
            HStack {
                Text("\(selectedItemIDs.count) of \(filteredItems.count) selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if !selectedItemIDs.isEmpty {
                    Button {
                        revealInFinder(ids: selectedItemIDs)
                    } label: {
                        Label("Reveal in Finder", systemImage: "folder")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }

                SizeText(bytes: selectedSize, style: .subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Button {
                    showCleanConfirmation = true
                } label: {
                    Label("Delete Selected", systemImage: "trash")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(selectedItemIDs.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .background(Color(.windowBackgroundColor))
        .quickLookPreview($quickLookURL)
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
                                CleaningCategoryType.largeFiles.color.opacity(0.15),
                                CleaningCategoryType.largeFiles.color.opacity(0.03)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: CleaningCategoryType.largeFiles.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(CleaningCategoryType.largeFiles.color)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 8) {
                Text("Large Files")
                    .font(.title.weight(.semibold))
                Text("Find large files taking up space on your disk.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    await scannerService.startScan(categories: Set([.largeFiles]))
                }
            } label: {
                Label("Scan for Large Files", systemImage: "magnifyingglass")
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

    // MARK: - Helpers

    @ViewBuilder
    private func fileIcon(for item: ScannedItem) -> some View {
        let ext = item.path.pathExtension.lowercased()
        let iconName: String = {
            switch ext {
            case "mp4", "mov", "avi", "mkv": return "film"
            case "dmg", "iso", "pkg": return "shippingbox"
            case "zip", "rar", "7z", "tar", "gz": return "doc.zipper"
            case "app": return "app.gift"
            case "jpg", "jpeg", "png", "heic", "gif", "tiff": return "photo"
            case "mp3", "wav", "aac", "flac": return "music.note"
            case "pdf": return "doc.richtext"
            default: return "doc"
            }
        }()

        Image(systemName: iconName)
            .foregroundStyle(.secondary)
            .frame(width: 20)
    }

    private func revealInFinder(ids: Set<UUID>) {
        let urls = items.filter { ids.contains($0.id) }.map(\.path)
        if let firstURL = urls.first {
            NSWorkspace.shared.activateFileViewerSelecting(urls)
        }
    }

    private func performClean(permanent: Bool) {
        Task {
            let toClean = selectedItems
            let cleaned: Int64
            if permanent {
                cleaned = await cleanerService.clean(items: toClean)
            } else {
                cleaned = await cleanerService.moveToTrash(items: toClean)
            }
            cleanedAmount = cleaned
            selectedItemIDs.removeAll()
            showCleanedAlert = true
        }
    }
}

#Preview {
    LargeFilesView()
        .environment(ScannerService())
        .environment(CleanerService())
        .frame(width: 900, height: 600)
}
