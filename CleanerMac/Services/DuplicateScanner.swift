import Foundation
import CryptoKit

@Observable
final class DuplicateScanner {
    var isScanning = false
    var progress: Double = 0
    var currentPhase: Phase = .idle
    var duplicateGroups: [[ScannedItem]] = []

    enum Phase: String {
        case idle = "Idle"
        case collectingFiles = "Collecting files"
        case groupingBySize = "Grouping by size"
        case partialHashing = "Computing partial hashes"
        case fullHashing = "Computing full hashes"
        case complete = "Complete"
    }

    private let fileManager = FileManager.default
    private let minimumFileSize: Int64 = 1024 // Skip files < 1 KB
    private let partialHashSize = 4096 // First 4 KB for partial hash

    /// Scan common user directories for duplicate files.
    /// Returns groups of duplicate `ScannedItem` arrays (each group has 2+ identical files).
    func scan() async -> [[ScannedItem]] {
        isScanning = true
        progress = 0
        duplicateGroups = []
        currentPhase = .collectingFiles

        // 1. Collect all regular files from common locations
        let scanDirectories: [URL] = [
            CleaningPaths.home.appendingPathComponent("Downloads"),
            CleaningPaths.home.appendingPathComponent("Documents"),
            CleaningPaths.home.appendingPathComponent("Desktop"),
            CleaningPaths.home.appendingPathComponent("Pictures"),
        ]

        var allFiles: [(url: URL, size: Int64)] = []

        for directory in scanDirectories {
            guard fileManager.fileExists(atPath: directory.path) else { continue }

            guard let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey, .isDirectoryKey],
                options: [.skipsHiddenFiles],
                errorHandler: nil
            ) else { continue }

            while let fileURL = enumerator.nextObject() as? URL {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                      resourceValues.isRegularFile == true else {
                    continue
                }

                let size = Int64(resourceValues.fileSize ?? 0)
                guard size >= minimumFileSize else { continue }

                allFiles.append((url: fileURL, size: size))
            }
        }

        guard !allFiles.isEmpty else {
            isScanning = false
            currentPhase = .complete
            progress = 1.0
            return []
        }

        // 2. Group files by size - only keep sizes with more than one file
        currentPhase = .groupingBySize
        progress = 0.2

        var sizeGroups: [Int64: [(url: URL, size: Int64)]] = [:]
        for file in allFiles {
            sizeGroups[file.size, default: []].append(file)
        }

        // Keep only groups with duplicates (2+ files of same size)
        let candidateGroups = sizeGroups.filter { $0.value.count > 1 }

        guard !candidateGroups.isEmpty else {
            isScanning = false
            currentPhase = .complete
            progress = 1.0
            return []
        }

        // Flatten candidates for hashing
        let candidates = candidateGroups.values.flatMap { $0 }
        let totalCandidates = Double(candidates.count)
        var processedCandidates = 0.0

        // 3. Compute partial hash (first 4 KB) for size-matched files
        currentPhase = .partialHashing
        progress = 0.3

        var partialHashGroups: [String: [(url: URL, size: Int64)]] = [:]

        for file in candidates {
            let partialHash = computePartialHash(of: file.url)
            let key = "\(file.size)_\(partialHash)"
            partialHashGroups[key, default: []].append(file)

            processedCandidates += 1
            progress = 0.3 + (processedCandidates / totalCandidates) * 0.3
        }

        // Keep only groups with 2+ matching partial hashes
        let partialCandidates = partialHashGroups.filter { $0.value.count > 1 }

        guard !partialCandidates.isEmpty else {
            isScanning = false
            currentPhase = .complete
            progress = 1.0
            return []
        }

        // 4. Compute full SHA-256 hash for partial-hash-matched files
        currentPhase = .fullHashing
        progress = 0.6

        let fullHashCandidates = partialCandidates.values.flatMap { $0 }
        let totalFullHash = Double(fullHashCandidates.count)
        var processedFullHash = 0.0

        var fullHashGroups: [String: [(url: URL, size: Int64)]] = [:]

        for file in fullHashCandidates {
            let fullHash = computeFullHash(of: file.url)
            fullHashGroups[fullHash, default: []].append(file)

            processedFullHash += 1
            progress = 0.6 + (processedFullHash / totalFullHash) * 0.35
        }

        // Keep only groups where 2+ files share the same full hash
        let confirmedDuplicates = fullHashGroups.filter { $0.value.count > 1 }

        // 5. Convert to ScannedItem groups
        var result: [[ScannedItem]] = []

        for (_, files) in confirmedDuplicates {
            var group: [ScannedItem] = []
            for file in files {
                let modDate = try? file.url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                let item = ScannedItem(
                    path: file.url,
                    name: file.url.lastPathComponent,
                    size: file.size,
                    category: .duplicates,
                    modificationDate: modDate,
                    isSelected: false // Don't auto-select duplicates; user should choose
                )
                group.append(item)
            }
            // Sort within group: oldest first (keep the newest, user selects older ones)
            group.sort { ($0.modificationDate ?? .distantPast) < ($1.modificationDate ?? .distantPast) }
            result.append(group)
        }

        // Sort groups by total wasted size (group size * (count - 1)) descending
        result.sort { groupA, groupB in
            let wasteA = (groupA.first?.size ?? 0) * Int64(groupA.count - 1)
            let wasteB = (groupB.first?.size ?? 0) * Int64(groupB.count - 1)
            return wasteA > wasteB
        }

        duplicateGroups = result
        currentPhase = .complete
        progress = 1.0
        isScanning = false

        return result
    }

    // MARK: - Hashing Helpers

    /// Compute a SHA-256 hash of the first `partialHashSize` bytes of a file.
    private func computePartialHash(of url: URL) -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return UUID().uuidString // Unique fallback so it won't falsely match
        }
        defer { try? handle.close() }

        let data = handle.readData(ofLength: partialHashSize)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Compute a full SHA-256 hash of the entire file, reading in chunks to keep memory low.
    private func computeFullHash(of url: URL) -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return UUID().uuidString
        }
        defer { try? handle.close() }

        var hasher = SHA256()
        let chunkSize = 1024 * 1024 // 1 MB chunks

        while autoreleasepool(invoking: {
            let chunk = handle.readData(ofLength: chunkSize)
            guard !chunk.isEmpty else { return false }
            hasher.update(data: chunk)
            return true
        }) {}

        let digest = hasher.finalize()
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
