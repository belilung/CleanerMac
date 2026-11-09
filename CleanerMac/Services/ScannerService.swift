import Foundation

@MainActor @Observable
final class ScannerService {
    var scanResult = ScanResult()
    var isScanning = false
    var progress: Double = 0
    var currentCategory: CleaningCategoryType?
    var currentPath: String?
    var categoryProgress: Double = 0

    private let fileManager = FileManager.default

    // MARK: - Public API

    func startScan(categories: Set<CleaningCategoryType> = Set(CleaningCategoryType.allCases)) async {
        isScanning = true
        scanResult = ScanResult()
        progress = 0
        categoryProgress = 0
        let startTime = Date()
        let totalCategories = Double(categories.count)
        var completedCategories = 0.0

        for category in categories.sorted(by: { $0.rawValue < $1.rawValue }) {
            currentCategory = category
            categoryProgress = 0
            var items = await scanCategory(category)
            // Auto-deselect risky categories — user must opt-in
            if !category.riskLevel.autoSelect {
                for i in items.indices {
                    items[i].isSelected = false
                }
            }
            scanResult.items[category] = items
            completedCategories += 1
            progress = completedCategories / totalCategories
        }

        scanResult.totalSize = scanResult.items.values.flatMap { $0 }.reduce(0) { $0 + $1.size }
        scanResult.scanDuration = Date().timeIntervalSince(startTime)
        scanResult.isComplete = true
        isScanning = false
        currentCategory = nil
        currentPath = nil
        categoryProgress = 0
    }

    // MARK: - Category Router

    private func scanCategory(_ category: CleaningCategoryType) async -> [ScannedItem] {
        switch category {
        case .systemJunk:
            return await scanSystemJunk()
        case .userCache:
            return await scanUserCache()
        case .developerJunk:
            return await scanDeveloperJunk()
        case .largeFiles:
            return await scanLargeFiles()
        case .duplicates:
            return [] // Handled by DuplicateScanner
        case .browserData:
            return await scanBrowserData()
        case .mailAttachments:
            return await scanMailAttachments()
        case .iOSBackups:
            return await scaniOSBackups()
        case .trash:
            return await scanTrash()
        case .messengerData:
            return await scanMessengerData()
        }
    }

    // MARK: - Safety Check

    private func isSafePath(_ url: URL) -> Bool {
        let protectedPaths = CleaningPaths.neverDelete
        let resolvedPath = url.standardizedFileURL.path

        for protectedSubpath in protectedPaths {
            if resolvedPath.contains(protectedSubpath) {
                return false
            }
        }
        return true
    }

    // MARK: - Helpers

    private func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func topLevelContents(of directory: URL) -> [URL] {
        guard directoryExists(at: directory) else { return [] }
        return (try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey, .totalFileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        )) ?? []
    }

    private func modificationDate(of url: URL) -> Date? {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        return values?.contentModificationDate
    }

    private func makeItem(path: URL, category: CleaningCategoryType) -> ScannedItem? {
        guard isSafePath(path) else { return nil }
        let size = FileSize.directorySize(at: path)
        guard size > 0 else { return nil }
        return ScannedItem(
            path: path,
            name: path.lastPathComponent,
            size: size,
            category: category,
            modificationDate: modificationDate(of: path)
        )
    }

    private func updateCurrentPath(_ url: URL) {
        // Truncate home path for display
        let home = CleaningPaths.home.path
        let path = url.path
        if path.hasPrefix(home) {
            currentPath = "~" + path.dropFirst(home.count)
        } else {
            currentPath = path
        }
    }

    // MARK: - System Junk

    private func scanSystemJunk() async -> [ScannedItem] {
        var items: [ScannedItem] = []
        let allPaths = CleaningPaths.systemCaches + CleaningPaths.systemLogs + CleaningPaths.crashReports + CleaningPaths.temporaryFiles
        let totalPaths = Double(allPaths.count)
        var processedPaths = 0.0

        // Scan system caches, logs, crash reports, temp files
        for dir in allPaths {
            updateCurrentPath(dir)
            await Task.yield()

            let contents = topLevelContents(of: dir)
            for entry in contents {
                if let item = makeItem(path: entry, category: .systemJunk) {
                    items.append(item)
                }
            }
            processedPaths += 1
            categoryProgress = processedPaths / (totalPaths + 1)
        }

        // Find .DS_Store files in home directory
        let homeURL = CleaningPaths.home
        if let enumerator = fileManager.enumerator(
            at: homeURL,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) {
            var dsStoreCount = 0
            let maxDSStores = 500

            while let fileURL = enumerator.nextObject() as? URL {
                guard dsStoreCount < maxDSStores else { break }

                // Skip Library to avoid deep recursion into system paths
                if fileURL.path.contains("/Library/") {
                    enumerator.skipDescendants()
                    continue
                }

                if fileURL.lastPathComponent == ".DS_Store" {
                    let size = FileSize.fileSize(at: fileURL)
                    if size > 0 && isSafePath(fileURL) {
                        items.append(ScannedItem(
                            path: fileURL,
                            name: ".DS_Store",
                            size: size,
                            category: .systemJunk,
                            modificationDate: modificationDate(of: fileURL)
                        ))
                        dsStoreCount += 1
                    }
                }
            }
        }
        categoryProgress = 1.0

        return items
    }

    // MARK: - User Cache

    private func scanUserCache() async -> [ScannedItem] {
        var items: [ScannedItem] = []

        let cachesURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Caches")
        guard directoryExists(at: cachesURL) else { return items }
        updateCurrentPath(cachesURL)

        let contents = topLevelContents(of: cachesURL)
        let total = Double(contents.count)

        for (index, entry) in contents.enumerated() {
            await Task.yield()
            updateCurrentPath(entry)

            if let item = makeItem(path: entry, category: .userCache) {
                items.append(item)
            }
            categoryProgress = Double(index + 1) / total
        }

        return items.sorted { $0.size > $1.size }
    }

    // MARK: - Developer Junk

    private func scanDeveloperJunk() async -> [ScannedItem] {
        var items: [ScannedItem] = []

        // Xcode paths - enumerate subdirectories where applicable
        let xcodeDerivedData = CleaningPaths.xcodeDerivedData
        if directoryExists(at: xcodeDerivedData) {
            updateCurrentPath(xcodeDerivedData)
            let contents = topLevelContents(of: xcodeDerivedData)
            for entry in contents {
                if let item = makeItem(path: entry, category: .developerJunk) {
                    items.append(item)
                }
            }
        }

        let xcodeArchives = CleaningPaths.xcodeArchives
        if directoryExists(at: xcodeArchives) {
            updateCurrentPath(xcodeArchives)
            let contents = topLevelContents(of: xcodeArchives)
            for entry in contents {
                if let item = makeItem(path: entry, category: .developerJunk) {
                    items.append(item)
                }
            }
        }

        categoryProgress = 0.3

        // Single-item developer paths (each is one big item if it exists)
        let singleItemPaths: [(URL, String)] = [
            (CleaningPaths.xcodeDeviceSupport, "Xcode Device Support"),
            (CleaningPaths.coreSimulator, "CoreSimulator Devices"),
            (CleaningPaths.xcodeCache, "Xcode Cache"),
            (CleaningPaths.swiftPackageCache, "Swift Package Cache"),
            (CleaningPaths.npmCache, "npm Cache"),
            (CleaningPaths.yarnCache, "Yarn Cache"),
            (CleaningPaths.pipCache, "pip Cache"),
            (CleaningPaths.homebrewCache, "Homebrew Cache"),
            (CleaningPaths.cocoapodsCache, "CocoaPods Cache"),
            (CleaningPaths.gradleCache, "Gradle Cache"),
            (CleaningPaths.cargoCache, "Cargo Cache"),
            (CleaningPaths.coreSimulatorSystem, "iOS Simulators (System)"),
        ]

        let total = Double(singleItemPaths.count)
        for (index, (path, displayName)) in singleItemPaths.enumerated() {
            await Task.yield()
            updateCurrentPath(path)

            guard directoryExists(at: path), isSafePath(path) else {
                categoryProgress = 0.3 + (Double(index + 1) / total) * 0.7
                continue
            }
            let size = FileSize.directorySize(at: path)
            guard size > 0 else {
                categoryProgress = 0.3 + (Double(index + 1) / total) * 0.7
                continue
            }
            items.append(ScannedItem(
                path: path,
                name: displayName,
                size: size,
                category: .developerJunk,
                modificationDate: modificationDate(of: path)
            ))
            categoryProgress = 0.3 + (Double(index + 1) / total) * 0.7
        }

        return items.sorted { $0.size > $1.size }
    }

    // MARK: - Large Files

    private func scanLargeFiles() async -> [ScannedItem] {
        var items: [ScannedItem] = []
        let homeURL = CleaningPaths.home
        let thresholdBytes: Int64 = 50 * 1024 * 1024 // 50 MB

        guard let enumerator = fileManager.enumerator(
            at: homeURL,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else {
            return items
        }

        var fileCount = 0
        let maxResults = 100

        while let fileURL = enumerator.nextObject() as? URL {
            // Skip Library folder entirely to avoid system files
            let relativePath = fileURL.path.replacingOccurrences(of: homeURL.path, with: "")
            if relativePath.hasPrefix("/Library") {
                enumerator.skipDescendants()
                continue
            }

            if fileCount % 100 == 0 {
                await Task.yield()
                updateCurrentPath(fileURL)
            }

            // Only consider regular files
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]),
                  resourceValues.isRegularFile == true else {
                continue
            }

            let size = Int64(resourceValues.fileSize ?? 0)
            guard size >= thresholdBytes, isSafePath(fileURL) else { continue }

            items.append(ScannedItem(
                path: fileURL,
                name: fileURL.lastPathComponent,
                size: size,
                category: .largeFiles,
                modificationDate: resourceValues.contentModificationDate
            ))

            fileCount += 1
            categoryProgress = min(0.95, Double(fileCount) / Double(maxResults))
        }

        // Sort by size descending and limit to top 100
        items.sort { $0.size > $1.size }
        categoryProgress = 1.0
        return Array(items.prefix(maxResults))
    }

    // MARK: - Browser Data

    private func scanBrowserData() async -> [ScannedItem] {
        var items: [ScannedItem] = []

        let browserPaths: [(URL, String)] = [
            (CleaningPaths.safariCache, "Safari Cache"),
            (CleaningPaths.chromeCache, "Chrome Cache"),
            (CleaningPaths.chromeProfile, "Chrome Profile Data"),
            (CleaningPaths.firefoxCache, "Firefox Cache"),
            (CleaningPaths.edgeCache, "Edge Cache"),
            (CleaningPaths.braveCache, "Brave Cache"),
            (CleaningPaths.arcCache, "Arc Cache"),
        ]

        // Firefox profiles need special handling
        let firefoxProfilesDir = CleaningPaths.firefoxProfiles
        if directoryExists(at: firefoxProfilesDir) {
            let profiles = topLevelContents(of: firefoxProfilesDir)
            for profile in profiles {
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: profile.path, isDirectory: &isDir), isDir.boolValue {
                    let cacheDir = profile.appendingPathComponent("cache2")
                    if directoryExists(at: cacheDir), isSafePath(cacheDir) {
                        let size = FileSize.directorySize(at: cacheDir)
                        if size > 0 {
                            items.append(ScannedItem(
                                path: cacheDir,
                                name: "Firefox Cache (\(profile.lastPathComponent))",
                                size: size,
                                category: .browserData,
                                modificationDate: modificationDate(of: cacheDir)
                            ))
                        }
                    }
                }
            }
        }

        let total = Double(browserPaths.count)
        for (index, (path, displayName)) in browserPaths.enumerated() {
            await Task.yield()
            updateCurrentPath(path)

            guard directoryExists(at: path) || FileSize.exists(at: path),
                  isSafePath(path) else {
                categoryProgress = Double(index + 1) / total
                continue
            }
            let size = FileSize.directorySize(at: path)
            guard size > 0 else {
                categoryProgress = Double(index + 1) / total
                continue
            }
            items.append(ScannedItem(
                path: path,
                name: displayName,
                size: size,
                category: .browserData,
                modificationDate: modificationDate(of: path)
            ))
            categoryProgress = Double(index + 1) / total
        }

        return items.sorted { $0.size > $1.size }
    }

    // MARK: - Mail Attachments

    private func scanMailAttachments() async -> [ScannedItem] {
        var items: [ScannedItem] = []
        let mailDir = CleaningPaths.mailAttachments
        guard directoryExists(at: mailDir) else { return items }
        updateCurrentPath(mailDir)

        guard let enumerator = fileManager.enumerator(
            at: mailDir,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else {
            return items
        }

        var fileCount = 0
        while let fileURL = enumerator.nextObject() as? URL {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]),
                  resourceValues.isRegularFile == true else {
                continue
            }

            let size = Int64(resourceValues.fileSize ?? 0)
            guard size > 0, isSafePath(fileURL) else { continue }

            items.append(ScannedItem(
                path: fileURL,
                name: fileURL.lastPathComponent,
                size: size,
                category: .mailAttachments,
                modificationDate: resourceValues.contentModificationDate
            ))
            fileCount += 1

            if fileCount % 50 == 0 {
                await Task.yield()
                updateCurrentPath(fileURL)
            }
        }

        return items.sorted { $0.size > $1.size }
    }

    // MARK: - iOS Backups

    private func scaniOSBackups() async -> [ScannedItem] {
        var items: [ScannedItem] = []
        let backupsDir = CleaningPaths.iOSBackups
        guard directoryExists(at: backupsDir) else { return items }
        updateCurrentPath(backupsDir)

        let contents = topLevelContents(of: backupsDir)
        for entry in contents {
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: entry.path, isDirectory: &isDir),
                  isDir.boolValue else { continue }

            if let item = makeItem(path: entry, category: .iOSBackups) {
                items.append(item)
            }
        }

        return items.sorted { $0.size > $1.size }
    }

    // MARK: - Trash

    private func scanTrash() async -> [ScannedItem] {
        var items: [ScannedItem] = []
        let trashDir = CleaningPaths.userTrash
        guard directoryExists(at: trashDir) else { return items }
        updateCurrentPath(trashDir)

        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(
                at: trashDir,
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey, .totalFileAllocatedSizeKey],
                options: []
            )
        } catch {
            return items
        }

        for entry in contents {
            guard isSafePath(entry) else { continue }

            var isDir: ObjCBool = false
            fileManager.fileExists(atPath: entry.path, isDirectory: &isDir)

            let size: Int64
            if isDir.boolValue {
                size = FileSize.directorySize(at: entry)
            } else {
                size = FileSize.fileSize(at: entry)
            }

            guard size > 0 else { continue }

            items.append(ScannedItem(
                path: entry,
                name: entry.lastPathComponent,
                size: size,
                category: .trash,
                modificationDate: modificationDate(of: entry)
            ))
        }

        return items.sorted { $0.size > $1.size }
    }

    // MARK: - Messenger Data

    private func scanMessengerData() async -> [ScannedItem] {
        var items: [ScannedItem] = []

        let messengerPaths: [(URL, String)] = [
            (CleaningPaths.telegramCache, "Telegram Cache"),
            (CleaningPaths.whatsappCache, "WhatsApp Cache"),
            (CleaningPaths.discordCache, "Discord Cache"),
            (CleaningPaths.slackCache, "Slack Cache"),
        ]

        let total = Double(messengerPaths.count)
        for (index, (path, displayName)) in messengerPaths.enumerated() {
            await Task.yield()
            updateCurrentPath(path)

            guard directoryExists(at: path), isSafePath(path) else {
                categoryProgress = Double(index + 1) / total
                continue
            }
            let size = FileSize.directorySize(at: path)
            guard size > 0 else {
                categoryProgress = Double(index + 1) / total
                continue
            }
            items.append(ScannedItem(
                path: path,
                name: displayName,
                size: size,
                category: .messengerData,
                modificationDate: modificationDate(of: path)
            ))
            categoryProgress = Double(index + 1) / total
        }

        return items.sorted { $0.size > $1.size }
    }
}
