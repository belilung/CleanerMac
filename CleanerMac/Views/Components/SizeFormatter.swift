import SwiftUI

struct SizeText: View {
    let bytes: Int64
    var style: Font = .body

    var body: some View {
        Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
            .font(style)
            .monospacedDigit()
    }
}

// MARK: - Animated Size Text

struct AnimatedSizeText: View {
    let bytes: Int64
    var style: Font = .body
    var color: Color = .primary

    var body: some View {
        SizeText(bytes: bytes, style: style)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .animation(.spring(duration: 0.4), value: bytes)
    }
}

// MARK: - Size Badge

struct SizeBadge: View {
    let bytes: Int64
    var color: Color = .blue

    var body: some View {
        Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
            .font(.caption.weight(.medium))
            .monospacedDigit()
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: Capsule())
    }
}

#Preview {
    VStack(spacing: 16) {
        SizeText(bytes: 1_500_000_000, style: .title)
        SizeText(bytes: 256_000_000, style: .body)
        AnimatedSizeText(bytes: 42_000_000, style: .headline, color: .blue)
        SizeBadge(bytes: 800_000_000, color: .orange)
        SizeBadge(bytes: 12_000_000, color: .green)
    }
    .padding()
}
