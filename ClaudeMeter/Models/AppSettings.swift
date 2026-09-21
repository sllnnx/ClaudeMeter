//
//  AppSettings.swift
//  ClaudeMeter
//
//  Created by Edd on 2025-11-14.
//

import Foundation

/// User preferences and app configuration
struct AppSettings: Codable, Equatable, Sendable {
    /// Refresh interval in seconds (60-600)
    var refreshInterval: TimeInterval

    /// Whether notifications are enabled
    var hasNotificationsEnabled: Bool

    /// Notification thresholds
    var notificationThresholds: NotificationThresholds

    /// Whether this is first launch
    var isFirstLaunch: Bool

    /// Last known organization ID (cached)
    var cachedOrganizationId: UUID?

    /// Model-scoped limits the user has hidden, by API display name.
    /// Empty by default: every limit the API reports appears in the popover, so a
    /// model released after this build needs no code change to be tracked.
    var hiddenScopedModels: Set<String>

    /// Whether to show the exact reset time alongside the relative description
    var isResetTimeShown: Bool

    /// Menu bar icon display style
    var iconStyle: IconStyle

    /// Whether menu bar icons are shown in color instead of monochrome.
    var isColoredIcon: Bool

    static let `default` = AppSettings(
        refreshInterval: 60,
        hasNotificationsEnabled: true,
        notificationThresholds: .default,
        isFirstLaunch: true,
        cachedOrganizationId: nil,
        hiddenScopedModels: [],
        isResetTimeShown: true,
        iconStyle: .battery,
        isColoredIcon: true
    )

    enum CodingKeys: String, CodingKey {
        case refreshInterval = "refresh_interval"
        case hasNotificationsEnabled = "notifications_enabled"
        case notificationThresholds = "notification_thresholds"
        case isFirstLaunch = "is_first_launch"
        case cachedOrganizationId = "cached_organization_id"
        case hiddenScopedModels = "hidden_scoped_models"
        case isResetTimeShown = "show_reset_time"
        case iconStyle = "icon_style"
        case isColoredIcon = "is_colored_icon"
    }

}

extension AppSettings {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings.default

        refreshInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .refreshInterval) ?? defaults.refreshInterval
        hasNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hasNotificationsEnabled) ?? defaults.hasNotificationsEnabled
        notificationThresholds = try container.decodeIfPresent(NotificationThresholds.self, forKey: .notificationThresholds) ?? defaults.notificationThresholds
        isFirstLaunch = try container.decodeIfPresent(Bool.self, forKey: .isFirstLaunch) ?? defaults.isFirstLaunch
        cachedOrganizationId = try container.decodeIfPresent(UUID.self, forKey: .cachedOrganizationId)
        isResetTimeShown = try container.decodeIfPresent(Bool.self, forKey: .isResetTimeShown) ?? defaults.isResetTimeShown
        iconStyle = try container.decodeIfPresent(IconStyle.self, forKey: .iconStyle) ?? defaults.iconStyle
        isColoredIcon = try container.decodeIfPresent(Bool.self, forKey: .isColoredIcon) ?? defaults.isColoredIcon

        // The pre-1.5 `show_sonnet_usage` key is deliberately not migrated. It shipped
        // defaulting to false, so almost every saved copy holds false by default rather
        // than by choice; honouring it would hide Sonnet from users who never asked.
        // Only `true` was ever deliberate, and showing is now the default anyway.
        hiddenScopedModels = try container.decodeIfPresent(
            Set<String>.self, forKey: .hiddenScopedModels
        ) ?? defaults.hiddenScopedModels
    }
}

extension AppSettings {
    /// Validate refresh interval is within bounds
    mutating func setRefreshInterval(_ interval: TimeInterval) {
        refreshInterval = max(60, min(600, interval))
    }

    /// Whether a model-scoped limit should appear in the popover.
    /// Shown unless explicitly hidden, so a newly reported model is tracked on arrival.
    func isScopedModelShown(_ name: String) -> Bool {
        !hiddenScopedModels.contains(name)
    }

    mutating func setScopedModel(_ name: String, isShown: Bool) {
        if isShown {
            hiddenScopedModels.remove(name)
        } else {
            hiddenScopedModels.insert(name)
        }
    }
}
