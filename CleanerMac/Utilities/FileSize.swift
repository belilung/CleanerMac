import Foundation

enum FileSize {
    static func formattedSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    static func directorySize(at url: URL) -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey]),
                  resourceValues.isRegularFile == true,
                  let size = resourceValues.totalFileAllocatedSize else {
                continue
            }
            totalSize += Int64(size)
        }

        return totalSize
    }

    static func fileSize(at url: URL) -> Int64 {
        guard let resourceValues = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey]),
              let size = resourceValues.totalFileAllocatedSize else {
            return 0
        }
        return Int64(size)
    }

    static func exists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}
