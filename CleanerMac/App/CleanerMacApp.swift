import SwiftUI

@main
struct CleanerMacApp: App {
    @State private var scannerService = ScannerService()
    @State private var cleanerService = CleanerService()
    @State private var diskUsageService = DiskUsageService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(scannerService)
                .environment(cleanerService)
                .environment(diskUsageService)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1100, height: 750)

        Settings {
            SettingsView()
        }
    }
}
