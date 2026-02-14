import Foundation

@MainActor @Observable
final class DiskUsageService {
    var diskUsage: DiskUsage = DiskUsage.current()

    /// Re-read disk usage from the system.
    func refresh() {
        diskUsage = DiskUsage.current()
    }

    /// Get usage breakdown by category from scan results, sorted largest first.
    func categoryBreakdown(from scanResult: ScanResult) -> [(CleaningCategoryType, Int64)] {
        CleaningCategoryType.allCases.compactMap { category in
            let size = scanResult.size(for: category)
            guard size > 0 else { return nil }
            return (category, size)
        }.sorted { $0.1 > $1.1 }
    }
}
