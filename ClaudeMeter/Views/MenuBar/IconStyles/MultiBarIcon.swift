//
//  MultiBarIcon.swift
//  ClaudeMeter
//

import SwiftUI

/// One bar in the multi-bar icon, carrying the name so colour stays stable per model.
struct IconBar: Equatable, Sendable {
    let name: String
    let percentage: Double
    let role: Role

    enum Role: Equatable, Sendable {
        case session
        case weekly
        case scoped
    }
}

extension IconBar {
    /// Bars for the multi-bar icon: session and weekly always, then the scoped limits
    /// that pass `isShown`. Capped at `MultiBarIcon.maxBars` because below ~2pt a bar
    /// stops being readable, so the busiest models win the remaining slots; the rest
    /// stay visible in the popover.
    static func bars(
        session: Double,
        weekly: Double,
        scoped: [ScopedUsageLimit],
        isShown: (String) -> Bool
    ) -> [IconBar] {
        var bars = [
            IconBar(name: "Session", percentage: session, role: .session),
            IconBar(name: "Weekly", percentage: weekly, role: .weekly),
        ]

        let visible = scoped
            .filter { isShown($0.name) }
            .sorted { $0.limit.percentage > $1.limit.percentage }
            .prefix(MultiBarIcon.maxBars - bars.count)

        bars.append(contentsOf: visible.map {
            IconBar(name: $0.name, percentage: max(0, min($0.limit.percentage, 100)), role: .scoped)
        })
        return bars
    }
}

/// Stacked bars: session, weekly, then one per model-scoped limit.
///
/// The menu bar is 22pt tall, so bars thin out as they multiply rather than
/// pushing the icon out of bounds. `IconBar.maxBars` caps the count upstream.
struct MultiBarIcon: View {
    let bars: [IconBar]
    let status: UsageStatus
    let isLoading: Bool
    let isStale: Bool
    var overrideText: String?  // Replaces the percentage text (pace-first display)
    var overrideColor: Color?  // Color for the override text

    /// Beyond this the bars stop being readable at menu bar size.
    static let maxBars = 5

    /// Vertical room for the bar stack, inside the 22pt menu bar.
    private static let stackHeight: CGFloat = 16

    private let barWidth: CGFloat = 32

    private var barSpacing: CGFloat {
        bars.count <= 2 ? 2 : 1.5
    }

    /// Bars shrink to fit the stack rather than overflow, never above the 5pt
    /// the two-bar layout uses, so a two-bar Multi Bar matches Dual Bar exactly.
    private var barHeight: CGFloat {
        guard bars.count > 1 else { return 5 }
        let spacingTotal = barSpacing * CGFloat(bars.count - 1)
        let available = (Self.stackHeight - spacingTotal) / CGFloat(bars.count)
        return max(2, min(5, available))
    }

    /// The percentage shown as text: the session bar, matching the other styles.
    private var primaryPercentage: Double {
        bars.first(where: { $0.role == .session })?.percentage ?? bars.first?.percentage ?? 0
    }

    var body: some View {
        HStack(spacing: 4) {
            if isLoading {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isStale ? .gray : status.color)
            } else {
                VStack(spacing: barSpacing) {
                    ForEach(bars, id: \.name) { bar in
                        MultiProgressBar(
                            percentage: bar.percentage,
                            color: color(for: bar),
                            isStale: isStale
                        )
                        .frame(width: barWidth, height: barHeight)
                    }
                }

                Text(overrideText ?? "\(Int(primaryPercentage))%")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(IconPalette.textColor(isStale: isStale, override: overrideColor, status: status))
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

    private func color(for bar: IconBar) -> Color {
        guard !isStale else { return .gray }
        switch bar.role {
        case .session: return status.color
        case .weekly: return .purple
        case .scoped: return Self.scopedColor(for: bar.name)
        }
    }

    /// Scoped bars are coloured by name, not by position, so a model keeps its
    /// colour when another one appears above or below it.
    static func scopedColor(for name: String) -> Color {
        let palette: [Color] = [.teal, .orange, .pink, .indigo, .mint]
        let hash = name.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        return palette[hash % palette.count]
    }
}

/// Individual progress bar component
private struct MultiProgressBar: View {
    let percentage: Double
    let color: Color
    let isStale: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.gray.opacity(0.3))

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(color)
                    .frame(width: geo.size.width * min(percentage / 100, 1.0))
            }
        }
    }
}

#Preview {
    let session = IconBar(name: "Session", percentage: 65, role: .session)
    let weekly = IconBar(name: "Weekly", percentage: 45, role: .weekly)

    return VStack(alignment: .leading, spacing: 20) {
        MultiBarIcon(bars: [session, weekly], status: .warning, isLoading: false, isStale: false)
        MultiBarIcon(
            bars: [session, weekly, IconBar(name: "Fable", percentage: 23, role: .scoped)],
            status: .warning, isLoading: false, isStale: false
        )
        MultiBarIcon(
            bars: [
                session, weekly,
                IconBar(name: "Fable", percentage: 23, role: .scoped),
                IconBar(name: "Opus", percentage: 58, role: .scoped),
                IconBar(name: "Sonnet", percentage: 12, role: .scoped),
            ],
            status: .warning, isLoading: false, isStale: false
        )
    }
    .padding()
}
