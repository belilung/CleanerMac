import SwiftUI

struct CategoryCard: View {
    let category: CleaningCategoryType
    let size: Int64?
    let itemCount: Int
    let isScanning: Bool
    let isHovered: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Category icon
                Image(systemName: category.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(category.color)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 40, height: 40)
                    .background(category.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                Spacer()

                // Scanning indicator or item count + risk badge
                if isScanning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    HStack(spacing: 6) {
                        if category.riskLevel != .safe {
                            Image(systemName: category.riskLevel == .moderate ? "shield.fill" : "exclamationmark.shield.fill")
                                .font(.caption2)
                                .foregroundStyle(category.riskLevel.color)
                        }
                        if itemCount > 0 {
                            Text("\(itemCount)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.fill.tertiary, in: Capsule())
                        }
                    }
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(categoryName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let size = size {
                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(category.color)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                } else if isScanning {
                    Text("Scanning...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("--")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .background(cardBackground)
        .overlay(cardBorder)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .shadow(
            color: isHovered ? category.color.opacity(0.15) : .black.opacity(0.05),
            radius: isHovered ? 12 : 6,
            y: isHovered ? 4 : 2
        )
        .animation(.spring(duration: 0.3, bounce: 0.4), value: isHovered)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(categoryName), \(sizeLabel)")
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        category.color.opacity(isHovered ? 0.06 : 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 14)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        category.color.opacity(isHovered ? 0.3 : 0.1),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    private var categoryName: String {
        switch category {
        case .systemJunk: return "System Junk"
        case .userCache: return "User Cache"
        case .developerJunk: return "Developer Junk"
        case .largeFiles: return "Large Files"
        case .duplicates: return "Duplicates"
        case .browserData: return "Browser Data"
        case .mailAttachments: return "Mail Attachments"
        case .iOSBackups: return "iOS Backups"
        case .trash: return "Trash"
        }
    }

    private var sizeLabel: String {
        if let size = size {
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
        return "Not scanned"
    }
}

#Preview {
    HStack(spacing: 16) {
        CategoryCard(
            category: .systemJunk,
            size: 2_500_000_000,
            itemCount: 142,
            isScanning: false,
            isHovered: false
        )

        CategoryCard(
            category: .largeFiles,
            size: nil,
            itemCount: 0,
            isScanning: true,
            isHovered: false
        )

        CategoryCard(
            category: .duplicates,
            size: 800_000_000,
            itemCount: 34,
            isScanning: false,
            isHovered: true
        )
    }
    .padding()
    .frame(width: 700)
}
