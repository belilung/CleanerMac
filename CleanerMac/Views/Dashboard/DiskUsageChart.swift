import SwiftUI

struct DiskUsageChart: View {
    let diskUsage: DiskUsage

    @State private var animatedPercentage: Double = 0
    @State private var appeared = false

    private let lineWidth: CGFloat = 20

    private var usageColor: Color {
        let percentage = diskUsage.usedPercentage
        if percentage < 0.6 {
            return .green
        } else if percentage < 0.8 {
            return .yellow
        } else {
            return .red
        }
    }

    private var gradientColors: [Color] {
        let percentage = diskUsage.usedPercentage
        if percentage < 0.6 {
            return [.green, .mint]
        } else if percentage < 0.8 {
            return [.yellow, .orange]
        } else {
            return [.orange, .red]
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Background track
                Circle()
                    .stroke(
                        Color.gray.opacity(0.15),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )

                // Used space arc
                Circle()
                    .trim(from: 0, to: animatedPercentage)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: gradientColors + [gradientColors.first ?? .green]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: usageColor.opacity(0.3), radius: 8)

                // Tick marks
                ForEach(0..<12, id: \.self) { tick in
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 1, height: 6)
                        .offset(y: -(size / 2 - lineWidth / 2))
                        .rotationEffect(.degrees(Double(tick) * 30))
                }

                // Center content
                VStack(spacing: 4) {
                    Text(diskUsage.formattedFree)
                        .font(.system(size: size * 0.14, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Free")
                        .font(.system(size: size * 0.06, weight: .medium))
                        .foregroundStyle(.secondary)

                    Divider()
                        .frame(width: size * 0.3)
                        .padding(.vertical, 2)

                    Text("\(diskUsage.formattedUsed) / \(diskUsage.formattedTotal)")
                        .font(.system(size: size * 0.05, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }

                // Percentage label on the arc
                if appeared {
                    Text("\(Int(diskUsage.usedPercentage * 100))%")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(usageColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial, in: Capsule())
                        .offset(arcLabelOffset(for: animatedPercentage, radius: size / 2 - lineWidth / 2))
                        .transition(.opacity)
                }
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .onAppear {
            withAnimation(.spring(duration: 1.2, bounce: 0.2).delay(0.2)) {
                animatedPercentage = diskUsage.usedPercentage
                appeared = true
            }
        }
        .onChange(of: diskUsage.usedPercentage) { _, newValue in
            withAnimation(.spring(duration: 0.8, bounce: 0.2)) {
                animatedPercentage = newValue
            }
        }
    }

    private func arcLabelOffset(for percentage: Double, radius: CGFloat) -> CGSize {
        let angle = (percentage * 360 - 90) * .pi / 180
        return CGSize(
            width: cos(angle) * (radius + 20),
            height: sin(angle) * (radius + 20)
        )
    }
}

// MARK: - Ring Shape

struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var lineWidth: CGFloat

    var animatableData: Double {
        get { endAngle.degrees }
        set { endAngle = .degrees(newValue) }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return path
    }
}

#Preview {
    DiskUsageChart(diskUsage: DiskUsage.current())
        .frame(width: 220, height: 220)
        .padding()
}
