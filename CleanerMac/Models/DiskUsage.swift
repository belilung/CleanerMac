import Foundation

struct DiskUsage {
    let totalSpace: Int64
    let usedSpace: Int64
    let freeSpace: Int64
    let purgableSpace: Int64

    var usedPercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace)
    }

    var freePercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(freeSpace) / Double(totalSpace)
    }

    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file)
    }

    var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file)
    }

    var formattedFree: String {
        ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file)
    }

    static func current() -> DiskUsage {
        let fileManager = FileManager.default
        guard let attrs = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let totalSize = attrs[.systemSize] as? Int64,
              let freeSize = attrs[.systemFreeSize] as? Int64 else {
            return DiskUsage(totalSpace: 0, usedSpace: 0, freeSpace: 0, purgableSpace: 0)
        }

        let resourceValues = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        let importantAvailable = resourceValues?.volumeAvailableCapacityForImportantUsage ?? Int64(freeSize)
        let purgable = importantAvailable - freeSize

        return DiskUsage(
            totalSpace: totalSize,
            usedSpace: totalSize - freeSize,
            freeSpace: freeSize,
            purgableSpace: max(0, purgable)
        )
    }
}
