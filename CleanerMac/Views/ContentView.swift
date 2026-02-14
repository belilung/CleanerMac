import SwiftUI

enum NavigationItem: Hashable {
    case dashboard
    case category(CleaningCategoryType)
}

struct ContentView: View {
    @Environment(ScannerService.self) private var scannerService
    @Environment(CleanerService.self) private var cleanerService
    @Environment(DiskUsageService.self) private var diskUsageService

    @State private var selectedItem: NavigationItem? = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

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
}
