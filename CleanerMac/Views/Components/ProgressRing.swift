import SwiftUI

struct ProgressRing<CenterContent: View>: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var size: CGFloat = 80
    var gradientColors: [Color] = [.blue, .cyan]
    var trackColor: Color = .gray.opacity(0.15)
    @ViewBuilder var centerContent: () -> CenterContent

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Progress arc
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors + [gradientColors.first ?? .blue]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: gradientColors.last?.opacity(0.4) ?? .clear, radius: 4)

            // End dot
            if animatedProgress > 0.02 {
                Circle()
                    .fill(gradientColors.last ?? .blue)
                    .frame(width: lineWidth, height: lineWidth)
                    .offset(y: -size / 2)
                    .rotationEffect(.degrees(animatedProgress * 360))
                    .shadow(color: gradientColors.last?.opacity(0.6) ?? .clear, radius: 3)
            }

            // Center content
            centerContent()
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(duration: 0.6, bounce: 0.15)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Convenience initializer without center content

extension ProgressRing where CenterContent == EmptyView {
    init(
        progress: Double,
        lineWidth: CGFloat = 8,
        size: CGFloat = 80,
        gradientColors: [Color] = [.blue, .cyan],
        trackColor: Color = .gray.opacity(0.15)
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.gradientColors = gradientColors
        self.trackColor = trackColor
        self.centerContent = { EmptyView() }
    }
}

// MARK: - Indeterminate Spinner Variant

struct SpinnerRing: View {
    var lineWidth: CGFloat = 4
    var size: CGFloat = 24
    var color: Color = .blue

    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [color.opacity(0), color]),
                    center: .center
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

#Preview {
    VStack(spacing: 32) {
        ProgressRing(
            progress: 0.72,
            lineWidth: 10,
            size: 120,
            gradientColors: [.blue, .purple]
        ) {
            VStack(spacing: 2) {
                Text("72%")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("Complete")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }

        HStack(spacing: 24) {
            ProgressRing(
                progress: 0.3,
                lineWidth: 6,
                size: 60,
                gradientColors: [.green, .mint]
            )

            ProgressRing(
                progress: 0.6,
                lineWidth: 6,
                size: 60,
                gradientColors: [.orange, .yellow]
            )

            ProgressRing(
                progress: 0.9,
                lineWidth: 6,
                size: 60,
                gradientColors: [.red, .pink]
            )
        }

        SpinnerRing(lineWidth: 3, size: 24, color: .blue)
    }
    .padding(40)
}
