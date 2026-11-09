import Foundation

@MainActor @Observable
final class CleanerService {
    var isCleaning = false
    var progress: Double = 0
    var cleanedSize: Int64 = 0
    var errors: [CleanError] = []
    var currentFileName: String?
    var processedCount: Int = 0
    var totalCount: Int = 0

    // Completion state for the celebration screen
    var showCompletionScreen = false
    var lastCleanedSize: Int64 = 0
    var lastCleanedCount: Int = 0
    var lastErrors: [CleanError] = []

    private var isCancelled = false

    struct CleanError: Identifiable {
        let id = UUID()
        let path: URL
        let message: String
    }

    func cancelCleaning() {
        isCancelled = true
    }

    /// Permanently delete the given items from disk.
    /// Returns the total bytes freed.
    func clean(items: [ScannedItem]) async -> Int64 {
        isCleaning = true
        isCancelled = false
        progress = 0
        cleanedSize = 0
        errors = []
        processedCount = 0
        totalCount = items.count
        let total = Double(items.count)

        for (index, item) in items.enumerated() {
            guard !isCancelled else { break }

            currentFileName = item.name

            // Yield to main run loop to keep UI responsive
            await Task.yield()

            do {
                try FileManager.default.removeItem(at: item.path)
                cleanedSize += item.size
            } catch {
                errors.append(CleanError(path: item.path, message: error.localizedDescription))
            }
            processedCount = index + 1
            progress = Double(index + 1) / total
        }

        currentFileName = nil
        isCleaning = false

        // Set completion state
        lastCleanedSize = cleanedSize
        lastCleanedCount = processedCount
        lastErrors = errors
        showCompletionScreen = true

        return cleanedSize
    }

    /// Move the given items to the Trash instead of permanently deleting them.
    /// Returns the total bytes freed.
    func moveToTrash(items: [ScannedItem]) async -> Int64 {
        isCleaning = true
        isCancelled = false
        progress = 0
        cleanedSize = 0
        errors = []
        processedCount = 0
        totalCount = items.count
        let total = Double(items.count)

        for (index, item) in items.enumerated() {
            guard !isCancelled else { break }

            currentFileName = item.name

            // Yield to main run loop to keep UI responsive
            await Task.yield()

            do {
                var resultingURL: NSURL?
                try FileManager.default.trashItem(at: item.path, resultingItemURL: &resultingURL)
                cleanedSize += item.size
            } catch {
                errors.append(CleanError(path: item.path, message: error.localizedDescription))
            }
            processedCount = index + 1
            progress = Double(index + 1) / total
        }

        currentFileName = nil
        isCleaning = false

        // Set completion state
        lastCleanedSize = cleanedSize
        lastCleanedCount = processedCount
        lastErrors = errors
        showCompletionScreen = true

        return cleanedSize
    }

    func dismissCompletion() {
        showCompletionScreen = false
    }
}
