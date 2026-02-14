import Foundation

struct ScannedItem: Identifiable, Hashable {
    let id = UUID()
    let path: URL
    let name: String
    let size: Int64
    let category: CleaningCategoryType
    let modificationDate: Date?
    var isSelected: Bool = true

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var fileExtension: String {
        path.pathExtension.lowercased()
    }

    static func == (lhs: ScannedItem, rhs: ScannedItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
