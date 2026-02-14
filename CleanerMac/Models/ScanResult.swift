import Foundation

struct ScanResult {
    var items: [CleaningCategoryType: [ScannedItem]] = [:]
    var totalSize: Int64 = 0
    var scanDuration: TimeInterval = 0
    var isComplete: Bool = false

    var selectedSize: Int64 {
        items.values.flatMap { $0 }.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }

    var selectedCount: Int {
        items.values.flatMap { $0 }.filter { $0.isSelected }.count
    }

    var totalCount: Int {
        items.values.flatMap { $0 }.count
    }

    func size(for category: CleaningCategoryType) -> Int64 {
        items[category]?.reduce(0) { $0 + $1.size } ?? 0
    }

    func count(for category: CleaningCategoryType) -> Int {
        items[category]?.count ?? 0
    }

    mutating func toggleAll(for category: CleaningCategoryType, selected: Bool) {
        guard var categoryItems = items[category] else { return }
        for i in categoryItems.indices {
            categoryItems[i].isSelected = selected
        }
        items[category] = categoryItems
    }
}
