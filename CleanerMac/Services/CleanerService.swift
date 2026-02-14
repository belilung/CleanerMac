import Foundation

@Observable
final class CleanerService {
    var isCleaning = false
    var progress: Double = 0
    var cleanedSize: Int64 = 0
    var errors: [CleanError] = []

    struct CleanError: Identifiable {
        let id = UUID()
        let path: URL
        let message: String
    }

    /// Permanently delete the given items from disk.
    /// Returns the total bytes freed.
    func clean(items: [ScannedItem]) async -> Int64 {
        isCleaning = true
        progress = 0
        cleanedSize = 0
        errors = []
        let total = Double(items.count)

        for (index, item) in items.enumerated() {
            do {
                try FileManager.default.removeItem(at: item.path)
                cleanedSize += item.size
            } catch {
                errors.append(CleanError(path: item.path, message: error.localizedDescription))
            }
            progress = Double(index + 1) / total
        }

        isCleaning = false
        return cleanedSize
    }

    /// Move the given items to the Trash instead of permanently deleting them.
    /// Returns the total bytes freed.
    func moveToTrash(items: [ScannedItem]) async -> Int64 {
        isCleaning = true
        progress = 0
        cleanedSize = 0
        errors = []
        let total = Double(items.count)

        for (index, item) in items.enumerated() {
            do {
                var resultingURL: NSURL?
                try FileManager.default.trashItem(at: item.path, resultingItemURL: &resultingURL)
                cleanedSize += item.size
            } catch {
                errors.append(CleanError(path: item.path, message: error.localizedDescription))
            }
            progress = Double(index + 1) / total
        }

        isCleaning = false
        return cleanedSize
    }
}
