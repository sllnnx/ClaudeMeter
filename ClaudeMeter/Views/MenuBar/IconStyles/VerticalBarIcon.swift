//
//  VerticalBarIcon.swift
//  ClaudeMeter
//

import SwiftUI

/// Vertical bars with a letter under each: 5H for the session window, W for
/// weekly, and the model's initial for each scoped limit.
///
/// Where the multi-bar style spends width on one long bar per limit, this spends
/// height, so the icon stays narrow no matter how many models the API reports.
struct VerticalBarIcon: View {
    let bars: [IconBar]
    let status: UsageStatus
    let isLoading: Bool
    let isStale: Bool
    var overrideColor: Color?

    /// Bar column height, leaving room for the label beneath inside 22pt.
    private static let columnHeight: CGFloat = 12
    private static let labelHeight: CGFloat = 8

    private let barWidth: CGFloat = 5
    private let barSpacing: CGFloat = 4

    var body: some View {
        HStack(spacing: 4) {
            if isLoading {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isStale ? .gray : status.color)
            } else {
                HStack(alignment: .bottom, spacing: barSpacing) {
                    ForEach(bars, id: \.name) { bar in
                        VStack(spacing: 1) {
                            VerticalProgressBar(
                                percentage: bar.percentage,
                                color: color(for: bar)
                            )
                            .frame(width: barWidth, height: Self.columnHeight)

                            Text(bar.shortLabel)
                                .font(.system(size: 7, weight: .semibold, design: .rounded))
                                .frame(height: Self.labelHeight)
                                .foregroundColor(labelColor)
                        }
                    }
                }
            }

            if isStale && !isLoading {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
        }
        .frame(height: 22)
        .padding(.horizontal, 4)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(status.accessibilityDescription)
    }

    private var accessibilityLabel: String {
        bars.map { "\($0.name): \(Int($0.percentage)) percent" }.joined(separator: ", ")
    }

    private var labelColor: Color {
        isStale ? .gray : .secondary
    }

    private func color(for bar: IconBar) -> Color {
        guard !isStale else { return .gray }
        if let overrideColor { return overrideColor }
        switch bar.role {
        case .session: return status.color
        case .weekly: return .purple
        case .scoped: return MultiBarIcon.scopedColor(for: bar.name)
        }
    }
}

/// A single upward-filling bar.
private struct VerticalProgressBar: View {
    let percentage: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.gray.opacity(0.3))

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(color)
                    .frame(height: geo.size.height * min(percentage / 100, 1.0))
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        VerticalBarIcon(
            bars: [
                IconBar(name: "Session", percentage: 65, role: .session),
                IconBar(name: "Weekly", percentage: 45, role: .weekly),
                IconBar(name: "Fable", percentage: 23, role: .scoped),
            ],
            status: .warning, isLoading: false, isStale: false
        )
        VerticalBarIcon(
            bars: [
                IconBar(name: "Session", percentage: 92, role: .session),
                IconBar(name: "Weekly", percentage: 78, role: .weekly),
                IconBar(name: "Fable", percentage: 23, role: .scoped),
                IconBar(name: "Opus", percentage: 58, role: .scoped),
                IconBar(name: "Sonnet", percentage: 12, role: .scoped),
            ],
            status: .critical, isLoading: false, isStale: false
        )
    }
    .padding()
}
