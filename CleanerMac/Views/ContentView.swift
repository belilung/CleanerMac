import SwiftUI

enum NavigationItem: Hashable {
    case dashboard
    case category(CleaningCategoryType)
    case appUninstaller
    case startupItems
}

struct ContentView: View {
    @Environment(ScannerService.self) private var scannerService
    @Environment(CleanerService.self) private var cleanerService
    @Environment(DiskUsageService.self) private var diskUsageService

    @State private var selectedItem: NavigationItem? = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    @AppStorage("scanOnLaunch") private var scanOnLaunch = false
    @State private var hasAutoScanned = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $selectedItem)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            diskUsageService.refresh()
            if scanOnLaunch && !hasAutoScanned {
                hasAutoScanned = true
                Task {
                    await scannerService.startScan(categories: Set(CleaningCategoryType.allCases))
                }
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .dashboard, .none:
            DashboardView(navigateToCategory: { category in
                selectedItem = .category(category)
            })
            .transition(.opacity.combined(with: .scale(scale: 0.98)))

        case .category(let categoryType):
            categoryDetailView(for: categoryType)
                .transition(.opacity.combined(with: .move(edge: .trailing)))

        case .appUninstaller:
            AppUninstallerView()
                .transition(.opacity.combined(with: .move(edge: .trailing)))

        case .startupItems:
            StartupItemsView()
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    @ViewBuilder
    private func categoryDetailView(for category: CleaningCategoryType) -> some View {
        switch category {
        case .largeFiles:
            LargeFilesView()
        case .duplicates:
            DuplicatesView()
        case .browserData:
            PrivacyView()
        case .systemJunk:
            SystemJunkView()
        default:
            ScanResultsView(category: category)
        }
    }
}

#Preview {
    ContentView()
        .environment(ScannerService())
        .environment(CleanerService())
        .environment(DiskUsageService())
        .environment(AppUninstallerService())
        .environment(StartupItemsService())
}
