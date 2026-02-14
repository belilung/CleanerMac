import Foundation
import AppKit

enum PermissionStatus {
    case granted
    case denied
    case unknown
}

final class PermissionManager: Sendable {
    static let shared = PermissionManager()

    private init() {}

    /// Check if app has Full Disk Access
    func checkFullDiskAccess() -> Bool {
        let testPaths = [
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Mail").path,
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Messages").path,
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Safari").path,
        ]

        for path in testPaths {
            if FileManager.default.isReadableFile(atPath: path) {
                return true
            }
        }
        return false
    }

    /// Open System Settings to Full Disk Access
    func requestFullDiskAccess() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }

    /// Check if a specific path is accessible
    func canAccess(path: URL) -> Bool {
        FileManager.default.isReadableFile(atPath: path.path)
    }
}
