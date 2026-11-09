import Foundation
import AppKit

struct InstalledApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let path: URL
    let size: Int64
    let icon: NSImage?
    let lastUsedDate: Date?
    var leftovers: [AppLeftover]
    var isSelected: Bool = false

    var totalLeftoverSize: Int64 {
        leftovers.reduce(0) { $0 + $1.size }
    }

    var totalSize: Int64 {
        size + totalLeftoverSize
    }

    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct AppLeftover: Identifiable, Hashable {
    let id = UUID()
    let path: URL
    let name: String
    let size: Int64
    let type: LeftoverType

    enum LeftoverType: String {
        case cache = "Cache"
        case preferences = "Preferences"
        case applicationSupport = "App Support"
        case containers = "Container"
        case savedState = "Saved State"
        case cookies = "Cookies"
        case logs = "Logs"
        case other = "Other"
    }

    static func == (lhs: AppLeftover, rhs: AppLeftover) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@MainActor @Observable
final class AppUninstallerService {
    var installedApps: [InstalledApp] = []
    var isScanning = false
    var progress: Double = 0
    var currentAppName: String?

    private let fileManager = FileManager.default

    func scanInstalledApps() async {
        isScanning = true
        progress = 0
        installedApps = []
        currentAppName = nil

        let applicationsDir = URL(fileURLWithPath: "/Applications")
        let userApplicationsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications")

        var appURLs: [URL] = []

        // Collect .app bundles
        for dir in [applicationsDir, userApplicationsDir] {
            guard fileManager.fileExists(atPath: dir.path) else { continue }
            if let contents = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) {
                appURLs.append(contentsOf: contents.filter { $0.pathExtension == "app" })
            }
        }

        let totalApps = Double(appURLs.count)

        for (index, appURL) in appURLs.enumerated() {
            await Task.yield()

            let appName = appURL.deletingPathExtension().lastPathComponent
            currentAppName = appName

            let bundle = Bundle(url: appURL)
            let bundleId = bundle?.bundleIdentifier ?? ""

            let appSize = FileSize.directorySize(at: appURL)
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            icon.size = NSSize(width: 32, height: 32)

            // Find last used date
            let lastUsed = (try? appURL.resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate

            // Find leftovers
            let leftovers = findLeftovers(bundleId: bundleId, appName: appName)

            let app = InstalledApp(
                name: appName,
                bundleIdentifier: bundleId,
                path: appURL,
                size: appSize,
                icon: icon,
                lastUsedDate: lastUsed,
                leftovers: leftovers
            )

            installedApps.append(app)
            progress = Double(index + 1) / totalApps
        }

        // Sort by total size descending
        installedApps.sort { $0.totalSize > $1.totalSize }

        currentAppName = nil
        isScanning = false
    }

    private func findLeftovers(bundleId: String, appName: String) -> [AppLeftover] {
        var leftovers: [AppLeftover] = []
        let home = FileManager.default.homeDirectoryForCurrentUser

        guard !bundleId.isEmpty else { return leftovers }

        let searchLocations: [(URL, AppLeftover.LeftoverType)] = [
            (home.appendingPathComponent("Library/Caches/\(bundleId)"), .cache),
            (home.appendingPathComponent("Library/Application Support/\(appName)"), .applicationSupport),
            (home.appendingPathComponent("Library/Application Support/\(bundleId)"), .applicationSupport),
            (home.appendingPathComponent("Library/Preferences/\(bundleId).plist"), .preferences),
            (home.appendingPathComponent("Library/Containers/\(bundleId)"), .containers),
            (home.appendingPathComponent("Library/Group Containers"), .containers),
            (home.appendingPathComponent("Library/Saved Application State/\(bundleId).savedState"), .savedState),
            (home.appendingPathComponent("Library/Cookies/\(bundleId).binarycookies"), .cookies),
            (home.appendingPathComponent("Library/HTTPStorages/\(bundleId)"), .cookies),
            (home.appendingPathComponent("Library/Logs/\(bundleId)"), .logs),
            (home.appendingPathComponent("Library/WebKit/\(bundleId)"), .other),
        ]

        for (path, type) in searchLocations {
            guard fileManager.fileExists(atPath: path.path) else { continue }

            var isDir: ObjCBool = false
            fileManager.fileExists(atPath: path.path, isDirectory: &isDir)

            let size: Int64
            if isDir.boolValue {
                size = FileSize.directorySize(at: path)
            } else {
                size = FileSize.fileSize(at: path)
            }

            guard size > 0 else { continue }

            leftovers.append(AppLeftover(
                path: path,
                name: path.lastPathComponent,
                size: size,
                type: type
            ))
        }

        // Search Group Containers for matching bundle prefix
        let groupContainersDir = home.appendingPathComponent("Library/Group Containers")
        if fileManager.fileExists(atPath: groupContainersDir.path) {
            if let contents = try? fileManager.contentsOfDirectory(
                at: groupContainersDir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) {
                // Match group containers that contain parts of the bundle ID
                let bundleParts = bundleId.split(separator: ".").map(String.init)
                let significantParts = bundleParts.filter { $0.count > 3 }

                for container in contents {
                    let containerName = container.lastPathComponent
                    if significantParts.contains(where: { containerName.localizedCaseInsensitiveContains($0) }) {
                        let size = FileSize.directorySize(at: container)
                        if size > 0 {
                            leftovers.append(AppLeftover(
                                path: container,
                                name: containerName,
                                size: size,
                                type: .containers
                            ))
                        }
                    }
                }
            }
        }

        return leftovers
    }
}
