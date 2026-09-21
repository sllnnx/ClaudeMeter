//
//  MultiBarIconTests.swift
//  ClaudeMeterTests
//

import XCTest
@testable import ClaudeMeter

final class MultiBarIconTests: XCTestCase {

    // MARK: - Bar selection

    func test_bars_withNoScopedLimits_areSessionAndWeeklyOnly() {
        let bars = IconBar.bars(session: 65, weekly: 45, scoped: [], isShown: { _ in true })

        XCTAssertEqual(bars.map(\.name), ["Session", "Weekly"])
        XCTAssertEqual(bars.map(\.role), [.session, .weekly])
    }

    func test_bars_includeAVisibleScopedModel() {
        let bars = IconBar.bars(
            session: 65, weekly: 45,
            scoped: [scoped("Fable", 23)],
            isShown: { _ in true }
        )

        XCTAssertEqual(bars.map(\.name), ["Session", "Weekly", "Fable"])
        XCTAssertEqual(bars.last?.percentage, 23)
        XCTAssertEqual(bars.last?.role, .scoped)
    }

    func test_bars_omitAHiddenScopedModel() {
        let bars = IconBar.bars(
            session: 65, weekly: 45,
            scoped: [scoped("Fable", 23), scoped("Opus", 58)],
            isShown: { $0 != "Opus" }
        )

        XCTAssertEqual(bars.map(\.name), ["Session", "Weekly", "Fable"])
    }

    /// Below roughly 2pt a bar stops being readable in a 22pt menu bar.
    func test_bars_areCappedAtFive() {
        let many = [
            scoped("A", 10), scoped("B", 20), scoped("C", 30),
            scoped("D", 40), scoped("E", 50),
        ]

        let bars = IconBar.bars(session: 65, weekly: 45, scoped: many, isShown: { _ in true })

        XCTAssertEqual(bars.count, MultiBarIcon.maxBars)
    }

    /// When the cap bites, the models closest to their limit are the ones worth seeing.
    func test_bars_whenCapped_keepTheBusiestModels() {
        // Four scoped models against three free slots, so the cap actually bites.
        let many = [
            scoped("Quiet", 5), scoped("Busy", 90),
            scoped("Middling", 50), scoped("Idle", 1),
        ]

        let bars = IconBar.bars(session: 65, weekly: 45, scoped: many, isShown: { _ in true })

        XCTAssertEqual(bars.map(\.name), ["Session", "Weekly", "Busy", "Middling", "Quiet"])
        XCTAssertFalse(bars.contains { $0.name == "Idle" })
    }

    func test_bars_clampAnOutOfRangeScopedPercentage() {
        let bars = IconBar.bars(
            session: 65, weekly: 45,
            scoped: [scoped("Overflowing", 140)],
            isShown: { _ in true }
        )

        XCTAssertEqual(bars.last?.percentage, 100)
    }

    // MARK: - Colour stability

    /// A model keeps its colour when another appears above or below it, so the bar
    /// you learned to read doesn't change meaning between refreshes.
    func test_scopedColour_isStablePerName() {
        XCTAssertEqual(
            MultiBarIcon.scopedColor(for: "Fable"),
            MultiBarIcon.scopedColor(for: "Fable")
        )
    }

    func test_scopedColour_differsBetweenModels() {
        XCTAssertNotEqual(
            MultiBarIcon.scopedColor(for: "Fable"),
            MultiBarIcon.scopedColor(for: "Opus")
        )
    }

    // MARK: - Helpers

    private func scoped(_ name: String, _ percentage: Double) -> ScopedUsageLimit {
        ScopedUsageLimit(
            name: name,
            limit: UsageLimit(utilization: percentage, resetAt: Date().addingTimeInterval(3600)),
            isActive: true
        )
    }
}
