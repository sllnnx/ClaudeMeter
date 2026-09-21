//
//  UsageCardView.swift
//  ClaudeMeter
//
//  Created by Edd on 2025-11-14.
//

import SwiftUI

/// Reusable usage card component
struct UsageCardView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    /// Critically damped, ~0.4s: the system's default feel for a value settling into
    /// place. No bounce, because a usage bar overshooting its real value would lie.
    private var fillAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 1.0)
    }

    let title: String
    let usageLimit: UsageLimit
    let icon: String
    let windowDuration: TimeInterval?
    var pacingDuration: TimeInterval?  // Optional shorter span the quota is expected to be consumed over
    var showsUnderuse: Bool = false  // Whether underuse is a meaningful signal for this window (weekly, not session)
    var isPaceFirst: Bool = false  // Pace as primary display, quota as secondary

    private var paceRatio: Double? {
        guard let windowDuration else { return nil }
        return usageLimit.paceRatio(windowDuration: windowDuration, pacingDuration: pacingDuration)
    }

    private var expectedPercent: Double? {
        guard let windowDuration else { return nil }
        return usageLimit.expectedUsagePercent(windowDuration: windowDuration, pacingDuration: pacingDuration)
    }

    /// Bar fill color: pace scale in pace-first mode, quota status otherwise
    private var barColor: Color {
        if isPaceFirst, let paceRatio {
            return PacePalette.color(for: paceRatio)
        }
        return usageLimit.status.color
    }

    /// Whether to append the exact reset time in parentheses.
    var showsExactResetTime: Bool = true

    /// When true, the exact reset time shows the time of day only (no date).
    var usesTimeOnlyResetTimestamp: Bool = false

    /// Exact reset time string, time-only or date+time depending on the card.
    private var exactResetTime: String {
        usesTimeOnlyResetTimestamp ? usageLimit.resetTimeOnlyFormatted : usageLimit.resetTimeFormatted
    }

    /// Reset label, optionally with the exact time appended in parentheses.
    private var resetLabel: String {
        showsExactResetTime
            ? "Resets \(usageLimit.resetDescription) (\(exactResetTime))"
            : "Resets \(usageLimit.resetDescription)"
    }

    /// Collapsed by default so several limits fit in one popover without scrolling.
    /// Expanding reveals the numbers behind the headline: what was expected by now,
    /// the burn ratio, and where the current rate lands.
    @State private var isExpanded = false

    private var disclosureAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.9)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(disclosureAnimation) { isExpanded.toggle() }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    headerRow
                    progressBar
                    resetRow
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title): \(Int(usageLimit.percentage))% used, \(usageLimit.status.accessibilityDescription)")
            .accessibilityValue(resetLabel)
            .accessibilityHint(isExpanded ? "Hide details" : "Show details")
            .accessibilityAddTraits(.isButton)

            if isExpanded {
                detailSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(reduceTransparency ? 0.25 : 0.08), lineWidth: 1)
        )
        .animation(fillAnimation, value: usageLimit.percentage)
    }

    // MARK: - Compact row

    /// Title and headline number share one row: the number carried its own row at
    /// 36pt before, which cost more height than a third card needed to fit.
    private var headerRow: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(usageLimit.status.color)

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 4)

            headlineValue

            Image(systemName: "chevron.right")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
    }

    /// Pace ratio in pace-first mode, quota percentage otherwise.
    @ViewBuilder
    private var headlineValue: some View {
        if isPaceFirst, let paceRatio {
            Text(String(format: "%.1f×", paceRatio))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .tracking(-0.4)
                .contentTransition(.numericText())
                .foregroundColor(Self.paceVerdict(for: paceRatio).color)
        } else {
            Text("\(Int(usageLimit.percentage))%")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .tracking(-0.4)
                .contentTransition(.numericText())
                .foregroundColor(usageLimit.status.color)
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))

                RoundedRectangle(cornerRadius: 3)
                    .fill(barColor)
                    .frame(width: geometry.size.width * min(usageLimit.percentage / 100, 1.0))
                    .animation(fillAnimation, value: usageLimit.percentage)
                    .animation(fillAnimation, value: barColor)

                // Expected-by-now tick
                if let expectedPercent {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.primary.opacity(0.55))
                        .frame(width: 2, height: 12)
                        .offset(x: geometry.size.width * min(expectedPercent / 100, 1.0) - 1)
                        .animation(fillAnimation, value: expectedPercent)
                }
            }
        }
        .frame(height: 6)
    }

    private var resetRow: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption2)
            Text(resetLabel)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)

            // The off-pace signal earns its place in the compact row: it is the one
            // detail that changes what you would do next.
            if let paceRatio, isOffPace(paceRatio) {
                compactPaceBadge(paceRatio)
            }
        }
        .help(usageLimit.resetTimeFormatted)
        .foregroundColor(.secondary)
    }

    private func isOffPace(_ ratio: Double) -> Bool {
        ratio > Constants.Pacing.riskThreshold
            || (showsUnderuse && ratio < Constants.Pacing.underuseThreshold)
    }

    private func compactPaceBadge(_ ratio: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: ratio > Constants.Pacing.riskThreshold ? "flame.fill" : "snowflake")
            Text(String(format: "%.1f×", ratio))
        }
        .font(.caption2)
        .foregroundColor(PacePalette.color(for: ratio))
        .accessibilityLabel(String(format: "%.1f times sustainable pace", ratio))
    }

    // MARK: - Expanded detail

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            HStack {
                statusBadge
                Spacer()
                if let expectedPercent {
                    Text("\(Int(expectedPercent.rounded()))% expected by now")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if isPaceFirst {
                Text("\(Int(usageLimit.percentage))% of quota used")
                    .font(.caption)
                    .foregroundColor(usageLimit.status.color)
            }

            paceLine
            projectionLine
        }
    }

    /// Pace verdict in pace-first mode, quota status otherwise.
    @ViewBuilder
    private var statusBadge: some View {
        if isPaceFirst, let paceRatio {
            let verdict = Self.paceVerdict(for: paceRatio)
            badge(icon: verdict.icon, label: verdict.label, color: verdict.color)
        } else {
            badge(
                icon: usageLimit.status.iconName,
                label: usageLimit.status.rawValue.capitalized,
                color: usageLimit.status.color
            )
        }
    }

    private func badge(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }

    // MARK: - Pace

    @ViewBuilder
    private var paceLine: some View {
        if let paceRatio {
            let formatted = String(format: "%.1f×", paceRatio)
            HStack(spacing: 3) {
                if paceRatio > Constants.Pacing.riskThreshold {
                    Image(systemName: "flame.fill")
                } else if paceRatio < Constants.Pacing.underuseThreshold {
                    Image(systemName: "snowflake")
                }
                Text("\(formatted) pace")
            }
            .font(.caption)
            .foregroundColor(PacePalette.color(for: paceRatio))
            .accessibilityLabel("\(formatted) sustainable pace")
        }
    }

    @ViewBuilder
    private var projectionLine: some View {
        if usageLimit.isExceeded {
            Text("Limit reached")
                .font(.caption)
                .foregroundColor(.red)
        } else if let windowDuration {
            if let hitDate = usageLimit.projectedLimitDate(windowDuration: windowDuration, pacingDuration: pacingDuration) {
                Text("Hits limit ~\(Self.hitDateDescription(hitDate)), \(Self.remainingDescription(usageLimit.resetAt.timeIntervalSince(hitDate))) before reset")
                    .font(.caption)
                    .foregroundColor(paceRatio.map(PacePalette.color(for:)) ?? .orange)
            } else if let endPercent = usageLimit.projectedEndPercent(windowDuration: windowDuration, pacingDuration: pacingDuration) {
                let end = Int(min(endPercent, 100).rounded())
                if showsUnderuse, let paceRatio, paceRatio < Constants.Pacing.underuseThreshold {
                    Text("On pace to end at ~\(end)% (\(100 - end)% unused)")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Text("On pace to end at ~\(end)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    /// Pace verdict presentation for pace-first mode
    static func paceVerdict(for ratio: Double) -> (label: String, icon: String, color: Color) {
        let color = PacePalette.color(for: ratio)
        if ratio > Constants.Pacing.riskThreshold {
            return ("Overusing", "flame.fill", color)
        }
        if ratio < Constants.Pacing.underuseThreshold {
            return ("Underusing", "snowflake", color)
        }
        return ("On Pace", "checkmark.circle.fill", color)
    }

    /// Time-of-day for a same-day hit; weekday/date + time when the projected hit
    /// is days out (weekly window), so a multi-day projection isn't shown as a bare
    /// clock time that reads like today.
    static func hitDateDescription(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = Calendar.current.isDateInToday(date) ? .none : .short
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }

    /// "in 50 minutes" -> "50 minutes"
    private static func remainingDescription(_ interval: TimeInterval) -> String {
        let description = UsageLimit.resetDescription(for: interval)
        return description.hasPrefix("in ") ? String(description.dropFirst(3)) : description
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        UsageCardView(
            title: "5-Hour Session",
            usageLimit: UsageLimit(
                utilization: 35.0,
                resetAt: Date().addingTimeInterval(7200)
            ),
            icon: "gauge.with.dots.needle.67percent",
            windowDuration: Constants.Pacing.sessionWindow
        )

        UsageCardView(
            title: "Weekly Usage",
            usageLimit: UsageLimit(
                utilization: 75.0,
                resetAt: Date().addingTimeInterval(86400 * 3)
            ),
            icon: "calendar",
            windowDuration: Constants.Pacing.weeklyWindow
        )
    }
    .padding()
    .frame(width: 320)
}
