import Foundation

@Observable
final class LargeFileScanner {
    var isScanning = false
    var progress: Double = 0
    var results: [ScannedItem] = []

    private let fileManager = FileManager.default

    /// Default threshold: 100 MB
    static let defaultThreshold: Int64 = 100 * 1024 * 1024
    /// Maximum results to return
    static let maxResults = 200

    /// Scan the home directory for files exceeding the given size threshold.
    /// Skips ~/Library (except ~/Downloads), hidden directories, and protected paths.
    /// Returns up to `maxResults` files sorted by size descending.
    func scan(threshold: Int64 = LargeFileScanner.defaultThreshold) async -> [ScannedItem] {
        isScanning = true
        progress = 0
        results = []

        let homeURL = CleaningPaths.home
        var items: [ScannedItem] = []

        // Directories to skip entirely
        let skipPrefixes: [String] = [
            homeURL.appendingPathComponent("Library").path,
        ]

        // Specific subdirectories inside Library that we DO want to scan
        let libraryExceptions: [URL] = [
            CleaningPaths.downloads,
        ]

        // First scan the main home directory (excluding Library)
        items.append(contentsOf: await scanDirectory(
            homeURL,
            threshold: threshold,
            skipPrefixes: skipPrefixes
        ))

        // Then scan Library exceptions
        for exceptionDir in libraryExceptions {
            guard fileManager.fileExists(atPath: exceptionDir.path) else { continue }
            items.append(contentsOf: await scanDirectory(
                exceptionDir,
                threshold: threshold,
                skipPrefixes: []
            ))
        }

        // Sort by size descending
        items.sort { $0.size > $1.size }

        // Limit to top results
        results = Array(items.prefix(Self.maxResults))
        progress = 1.0
        isScanning = false

        return results
    }

    // MARK: - Private

    private func scanDirectory(
        _ directory: URL,
        threshold: Int64,
        skipPrefixes: [String]
    ) async -> [ScannedItem] {
        var items: [ScannedItem] = []

        let resourceKeys: Set<URLResourceKey> = [
            .fileSizeKey,
            .totalFileAllocatedSizeKey,
            .isRegularFileKey,
            .isDirectoryKey,
            .contentModificationDateKey,
            .typeIdentifierKey,
        ]

        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: nil
        ) else {
            return items
        }

        var fileCount = 0

        while let fileURL = enumerator.nextObject() as? URL {
            let filePath = fileURL.path

            // Check if this path should be skipped
            var shouldSkip = false
            for prefix in skipPrefixes {
                if filePath.hasPrefix(prefix) {
                    enumerator.skipDescendants()
                    shouldSkip = true
                    break
                }
            }
            if shouldSkip { continue }

            // Only consider regular files
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                  resourceValues.isRegularFile == true else {
                continue
            }

            // Use allocated size if available, otherwise file size
            let size: Int64
            if let allocatedSize = resourceValues.totalFileAllocatedSize {
                size = Int64(allocatedSize)
            } else if let fileSize = resourceValues.fileSize {
                size = Int64(fileSize)
            } else {
                continue
            }

            guard size >= threshold else { continue }

            // Check against neverDelete
            let protectedPaths = CleaningPaths.neverDelete
            let resolvedPath = fileURL.standardizedFileURL.path
            var isProtected = false
            for protectedURL in protectedPaths {
                let protectedPath = protectedURL.standardizedFileURL.path
                if resolvedPath == protectedPath || resolvedPath.hasPrefix(protectedPath + "/") {
                    isProtected = true
                    break
                }
            }
            if isProtected { continue }

            let fileType = fileTypeDescription(for: fileURL, typeIdentifier: resourceValues.typeIdentifier)

            items.append(ScannedItem(
                path: fileURL,
                name: "\(fileURL.lastPathComponent) (\(fileType))",
                size: size,
                category: .largeFiles,
                modificationDate: resourceValues.contentModificationDate
            ))

            fileCount += 1

            // Update progress periodically
            if fileCount % 50 == 0 {
                // Estimate progress based on files found vs expected max
                progress = min(0.95, Double(fileCount) / Double(Self.maxResults * 2))
            }
        }

        return items
    }

    /// Determine a human-readable file type description.
    private func fileTypeDescription(for url: URL, typeIdentifier: String?) -> String {
        let ext = url.pathExtension.lowercased()

        // Common file type mappings
        switch ext {
        // Video
        case "mp4", "m4v", "mov":
            return "Video"
        case "avi":
            return "Video (AVI)"
        case "mkv":
            return "Video (MKV)"
        case "wmv":
            return "Video (WMV)"

        // Audio
        case "mp3", "m4a", "aac":
            return "Audio"
        case "wav":
            return "Audio (WAV)"
        case "flac":
            return "Audio (FLAC)"
        case "aiff", "aif":
            return "Audio (AIFF)"

        // Images
        case "jpg", "jpeg":
            return "Image (JPEG)"
        case "png":
            return "Image (PNG)"
        case "tiff", "tif":
            return "Image (TIFF)"
        case "raw", "cr2", "nef", "arw":
            return "Image (RAW)"
        case "psd":
            return "Photoshop Document"
        case "heic":
            return "Image (HEIC)"

        // Archives
        case "zip":
            return "Archive (ZIP)"
        case "dmg":
            return "Disk Image"
        case "iso":
            return "Disk Image (ISO)"
        case "pkg":
            return "Installer Package"
        case "tar", "gz", "bz2", "xz":
            return "Archive"
        case "rar":
            return "Archive (RAR)"
        case "7z":
            return "Archive (7z)"

        // Documents
        case "pdf":
            return "PDF Document"
        case "docx", "doc":
            return "Word Document"
        case "xlsx", "xls":
            return "Spreadsheet"
        case "pptx", "ppt":
            return "Presentation"
        case "pages":
            return "Pages Document"
        case "numbers":
            return "Numbers Spreadsheet"
        case "keynote":
            return "Keynote Presentation"

        // Developer
        case "ipa":
            return "iOS App Archive"
        case "xcarchive":
            return "Xcode Archive"
        case "jar":
            return "Java Archive"

        // Virtual machines
        case "vmdk", "vdi", "qcow2":
            return "Virtual Disk"

        // Database
        case "sqlite", "db":
            return "Database"

        // Other
        case "app":
            return "Application"
        case "":
            return "Unknown"
        default:
            return ext.uppercased()
        }
    }
}
