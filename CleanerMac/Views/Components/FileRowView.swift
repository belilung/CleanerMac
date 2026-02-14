import SwiftUI

struct FileRowView: View {
    let item: ScannedItem
    var onToggle: ((ScannedItem) -> Void)?

    @State private var isHovered = false

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                onToggle?(item)
            } label: {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(item.isSelected ? .blue : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.borderless)

            // File type icon
            fileTypeIcon
                .frame(width: 28, height: 28)
                .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 6))

            // File name
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(item.path.deletingLastPathComponent().path(percentEncoded: false))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }

            Spacer()

            // Modification date
            if let date = item.modificationDate {
                Text(Self.dateFormatter.string(from: date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 90, alignment: .trailing)
            } else {
                Text("--")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(width: 90, alignment: .trailing)
            }

            // File size
            Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.accentColor.opacity(0.06) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    @ViewBuilder
    private var fileTypeIcon: some View {
        let ext = item.path.pathExtension.lowercased()
        let (iconName, iconColor) = fileIconInfo(for: ext)

        Image(systemName: iconName)
            .font(.system(size: 14))
            .foregroundStyle(iconColor)
    }

    private func fileIconInfo(for ext: String) -> (String, Color) {
        switch ext {
        // Images
        case "jpg", "jpeg", "png", "heic", "gif", "tiff", "bmp", "svg", "webp":
            return ("photo", .pink)
        // Videos
        case "mp4", "mov", "avi", "mkv", "wmv", "flv", "m4v":
            return ("film", .purple)
        // Audio
        case "mp3", "wav", "aac", "flac", "m4a", "ogg", "wma":
            return ("music.note", .red)
        // Documents
        case "pdf":
            return ("doc.richtext", .red)
        case "doc", "docx", "pages":
            return ("doc.text", .blue)
        case "xls", "xlsx", "numbers":
            return ("tablecells", .green)
        case "ppt", "pptx", "key":
            return ("rectangle.on.rectangle", .orange)
        case "txt", "rtf":
            return ("doc.plaintext", .gray)
        // Code
        case "swift", "py", "js", "ts", "html", "css", "json", "xml", "yml", "yaml":
            return ("chevron.left.forwardslash.chevron.right", .teal)
        // Archives
        case "zip", "rar", "7z", "tar", "gz", "bz2", "xz":
            return ("doc.zipper", .brown)
        // System / apps
        case "dmg", "iso":
            return ("opticaldiscsymbol", .yellow)
        case "pkg", "app":
            return ("shippingbox", .indigo)
        // Cache / Temp
        case "cache", "tmp", "log":
            return ("gear", .gray)
        default:
            return ("doc", .secondary)
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        FileRowView(
            item: ScannedItem(
                path: URL(fileURLWithPath: "/Users/demo/Documents/large-video.mp4"),
                name: "large-video.mp4",
                size: 1_500_000_000,
                category: .largeFiles,
                modificationDate: Date().addingTimeInterval(-86400 * 3),
                isSelected: true
            )
        )

        Divider()

        FileRowView(
            item: ScannedItem(
                path: URL(fileURLWithPath: "/Users/demo/Library/Caches/com.apple.Safari/data.cache"),
                name: "data.cache",
                size: 250_000_000,
                category: .systemJunk,
                modificationDate: Date().addingTimeInterval(-86400),
                isSelected: false
            )
        )
    }
    .frame(width: 600)
    .padding()
}
