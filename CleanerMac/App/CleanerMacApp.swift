import SwiftUI

@main
struct CleanerMacApp: App {
    @State private var scannerService = ScannerService()
    @State private var cleanerService = CleanerService()
    @State private var diskUsageService = DiskUsageService()
    @State private var appUninstallerService = AppUninstallerService()
    @State private var startupItemsService = StartupItemsService()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }

                // Global cleaning progress overlay
                CleaningProgressOverlay()

                // Cleaning complete celebration
                if cleanerService.showCompletionScreen {
                    CleaningCompleteView(
                        freedSpace: cleanerService.lastCleanedSize,
                        itemCount: cleanerService.lastCleanedCount,
                        errors: cleanerService.lastErrors,
                        onDismiss: {
                            cleanerService.dismissCompletion()
                            diskUsageService.refresh()
                        }
                    )
                }
            }
            .environment(scannerService)
            .environment(cleanerService)
            .environment(diskUsageService)
            .environment(appUninstallerService)
            .environment(startupItemsService)
            .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1100, height: 750)

        Settings {
            SettingsView()
        }
    }
}
