import Foundation
import ServiceManagement

struct StartupItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: URL
    let type: ItemType
    var isEnabled: Bool
    let bundleIdentifier: String?

    enum ItemType: String {
        case launchAgent = "Launch Agent"
        case loginItem = "Login Item"
    }

    static func == (lhs: StartupItem, rhs: StartupItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@MainActor @Observable
final class StartupItemsService {
    var startupItems: [StartupItem] = []
    var isScanning = false

    private let fileManager = FileManager.default

    func scan() async {
        isScanning = true
        startupItems = []

        // Scan user LaunchAgents
        let userLaunchAgentsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")

        if fileManager.fileExists(atPath: userLaunchAgentsDir.path) {
            if let contents = try? fileManager.contentsOfDirectory(
                at: userLaunchAgentsDir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) {
                for plistURL in contents where plistURL.pathExtension == "plist" {
                    await Task.yield()

                    if let plistData = try? Data(contentsOf: plistURL),
                       let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {

                        let label = plist["Label"] as? String ?? plistURL.deletingPathExtension().lastPathComponent
                        let isDisabled = plist["Disabled"] as? Bool ?? false

                        let item = StartupItem(
                            name: prettifyName(label),
                            path: plistURL,
                            type: .launchAgent,
                            isEnabled: !isDisabled,
                            bundleIdentifier: label
                        )
                        startupItems.append(item)
                    }
                }
            }
        }

        // Sort: enabled first, then by name
        startupItems.sort { lhs, rhs in
            if lhs.isEnabled != rhs.isEnabled {
                return lhs.isEnabled
            }
            return lhs.name.localizedCompare(rhs.name) == .orderedAscending
        }

        isScanning = false
    }

    func toggleItem(_ item: StartupItem) {
        guard let index = startupItems.firstIndex(where: { $0.id == item.id }) else { return }

        // Toggle in plist file
        if let plistData = try? Data(contentsOf: item.path),
           var plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {

            let newDisabledState = item.isEnabled // currently enabled -> set disabled to true
            plist["Disabled"] = newDisabledState

            if let updatedData = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) {
                try? updatedData.write(to: item.path)
                startupItems[index].isEnabled = !newDisabledState
            }
        }
    }

    private func prettifyName(_ label: String) -> String {
        // Convert com.company.AppName to just "AppName"
        let parts = label.split(separator: ".")
        if parts.count >= 3 {
            return String(parts.last ?? Substring(label))
        }
        return label
    }
}
