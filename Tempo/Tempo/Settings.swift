//  Tempo - A Pomodoro timer app for macOS
//  Settings.swift - Core settings, data models, and helper extensions

import Foundation
import SwiftUI
import Combine

// MARK: - Settings Keys
// Centralized keys for UserDefaults storage to avoid typos
enum SettingsKeys {
    enum Timer: String, CaseIterable {
        case focusDuration, shortBreakDuration, longBreakDuration
        case autoStartBreaks, autoStartFocus
    }
    
    enum Behavior: String, CaseIterable {
        case enableNotifications, enableSounds, enableZenMusic
    }
    
    enum Appearance: String, CaseIterable {
        case themeColor, overrideThemeColor, selectedTab
        case appTheme, appAppearance, animationStyle
    }
    
    enum Session: String, CaseIterable {
        case currentSessionName, customSessions, todos, activeTaskId
    }
    
    enum Stats: String, CaseIterable {
        case totalFocusTime, totalSessions, todaySessions
        case lastSessionDate, weeklyData
        case sessionHistory, bestStreakEver
    }

    enum Achievements: String, CaseIterable {
        case achievements, zenSessionCount, earlyBirdCount, nightOwlCount
    }

    enum Insights: String, CaseIterable {
        case enableInsights, currentLocation, locationTags
        case insightCache, lastInsightCheck, hasSeenAIPrivacyNotice
        case enablePostSessionFeedback
    }

    enum Persistence: String, CaseIterable {
        case savedTimerState
    }
    
    enum Onboarding: String, CaseIterable {
        case hasCompletedOnboarding
        case appLanguage
    }
}

// MARK: - Settings Store
// Singleton class for managing all app settings via UserDefaults
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    private let defaults = UserDefaults.standard
    
    // MARK: Timer Settings
    var focusDuration: Int {
        get { defaults.integer(forKey: SettingsKeys.Timer.focusDuration.rawValue).nonZeroOrDefault(25) }
        set { defaults.set(newValue, forKey: SettingsKeys.Timer.focusDuration.rawValue) }
    }

    var shortBreakDuration: Int {
        get { defaults.integer(forKey: SettingsKeys.Timer.shortBreakDuration.rawValue).nonZeroOrDefault(5) }
        set { defaults.set(newValue, forKey: SettingsKeys.Timer.shortBreakDuration.rawValue) }
    }

    var longBreakDuration: Int {
        get { defaults.integer(forKey: SettingsKeys.Timer.longBreakDuration.rawValue).nonZeroOrDefault(15) }
        set { defaults.set(newValue, forKey: SettingsKeys.Timer.longBreakDuration.rawValue) }
    }

    var autoStartBreaks: Bool {
        get { defaults.object(forKey: SettingsKeys.Timer.autoStartBreaks.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: SettingsKeys.Timer.autoStartBreaks.rawValue) }
    }

    var autoStartFocus: Bool {
        get { defaults.object(forKey: SettingsKeys.Timer.autoStartFocus.rawValue) as? Bool ?? false }
        set { defaults.set(newValue, forKey: SettingsKeys.Timer.autoStartFocus.rawValue) }
    }

    // MARK: Behavior Settings
    var enableNotifications: Bool {
        get { defaults.object(forKey: SettingsKeys.Behavior.enableNotifications.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: SettingsKeys.Behavior.enableNotifications.rawValue) }
    }

    var enableSounds: Bool {
        get { defaults.object(forKey: SettingsKeys.Behavior.enableSounds.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: SettingsKeys.Behavior.enableSounds.rawValue) }
    }

    var enableZenMusic: Bool {
        get { defaults.object(forKey: SettingsKeys.Behavior.enableZenMusic.rawValue) as? Bool ?? false }
        set { defaults.set(newValue, forKey: SettingsKeys.Behavior.enableZenMusic.rawValue) }
    }

    // MARK: Appearance Settings
    var themeColor: String {
        get { defaults.string(forKey: SettingsKeys.Appearance.themeColor.rawValue) ?? "red" }
        set { defaults.set(newValue, forKey: SettingsKeys.Appearance.themeColor.rawValue) }
    }

    var overrideThemeColor: Bool {
        get { defaults.object(forKey: SettingsKeys.Appearance.overrideThemeColor.rawValue) as? Bool ?? false }
        set { defaults.set(newValue, forKey: SettingsKeys.Appearance.overrideThemeColor.rawValue) }
    }

    var selectedTab: Int {
        get { defaults.integer(forKey: SettingsKeys.Appearance.selectedTab.rawValue) }
        set { defaults.set(newValue, forKey: SettingsKeys.Appearance.selectedTab.rawValue) }
    }

    var appTheme: String {
        get { defaults.string(forKey: SettingsKeys.Appearance.appTheme.rawValue) ?? "default" }
        set { defaults.set(newValue, forKey: SettingsKeys.Appearance.appTheme.rawValue) }
    }

    var appAppearance: String {
        get { defaults.string(forKey: SettingsKeys.Appearance.appAppearance.rawValue) ?? "system" }
        set { defaults.set(newValue, forKey: SettingsKeys.Appearance.appAppearance.rawValue) }
    }

    var animationStyle: String {
        get { defaults.string(forKey: SettingsKeys.Appearance.animationStyle.rawValue) ?? "smooth" }
        set { defaults.set(newValue, forKey: SettingsKeys.Appearance.animationStyle.rawValue) }
    }

    // MARK: Session Settings
    var currentSessionName: String {
        get { defaults.string(forKey: SettingsKeys.Session.currentSessionName.rawValue) ?? "" }
        set { defaults.set(newValue, forKey: SettingsKeys.Session.currentSessionName.rawValue) }
    }

    var activeTaskId: String? {
        get { defaults.string(forKey: SettingsKeys.Session.activeTaskId.rawValue) }
        set { defaults.set(newValue, forKey: SettingsKeys.Session.activeTaskId.rawValue) }
    }

    var customSessions: [SessionType] {
        get {
            guard let data = defaults.data(forKey: SettingsKeys.Session.customSessions.rawValue),
                  let sessions = try? JSONDecoder().decode([SessionType].self, from: data) else {
                return SessionType.defaultSessions
            }
            return sessions
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: SettingsKeys.Session.customSessions.rawValue)
            }
        }
    }

    // MARK: Statistics Settings
    var totalFocusTime: Double {
        get { defaults.double(forKey: SettingsKeys.Stats.totalFocusTime.rawValue) }
        set { defaults.set(newValue, forKey: SettingsKeys.Stats.totalFocusTime.rawValue) }
    }

    var totalSessions: Int {
        get { defaults.integer(forKey: SettingsKeys.Stats.totalSessions.rawValue) }
        set { defaults.set(newValue, forKey: SettingsKeys.Stats.totalSessions.rawValue) }
    }

    var todaySessions: Int {
        get { defaults.integer(forKey: SettingsKeys.Stats.todaySessions.rawValue) }
        set { defaults.set(newValue, forKey: SettingsKeys.Stats.todaySessions.rawValue) }
    }

    var lastSessionDate: String {
        get { defaults.string(forKey: SettingsKeys.Stats.lastSessionDate.rawValue) ?? "" }
        set { defaults.set(newValue, forKey: SettingsKeys.Stats.lastSessionDate.rawValue) }
    }

    var weeklyDataJSON: String {
        get { defaults.string(forKey: SettingsKeys.Stats.weeklyData.rawValue) ?? "[]" }
        set { defaults.set(newValue, forKey: SettingsKeys.Stats.weeklyData.rawValue) }
    }

    var todos: [TodoItem] {
        get {
            guard let data = defaults.data(forKey: SettingsKeys.Session.todos.rawValue),
                  let todos = try? JSONDecoder().decode([TodoItem].self, from: data) else {
                return []
            }
            return todos
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: SettingsKeys.Session.todos.rawValue)
            }
        }
    }

    // MARK: Session History
    var sessionHistory: [SessionRecord] {
        get {
            guard let data = defaults.data(forKey: SettingsKeys.Stats.sessionHistory.rawValue),
                  let records = try? JSONDecoder().decode([SessionRecord].self, from: data) else {
                return []
            }
            return records
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: SettingsKeys.Stats.sessionHistory.rawValue)
            }
        }
    }

    var bestStreakEver: Int {
        get { defaults.integer(forKey: SettingsKeys.Stats.bestStreakEver.rawValue) }
        set { defaults.set(newValue, forKey: SettingsKeys.Stats.bestStreakEver.rawValue) }
    }

    // MARK: Achievement Stats
    var achievements: [Achievement] {
        get {
            guard let data = defaults.data(forKey: SettingsKeys.Achievements.achievements.rawValue),
                  let items = try? JSONDecoder().decode([Achievement].self, from: data) else {
                return []
            }
            return items
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: SettingsKeys.Achievements.achievements.rawValue)
            }
        }
    }

    var zenSessionCount: Int {
        get { defaults.integer(forKey: SettingsKeys.Achievements.zenSessionCount.rawValue) }
        set { defaults.set(newValue, forKey: SettingsKeys.Achievements.zenSessionCount.rawValue) }
    }

    var earlyBirdCount: Int {
        get { defaults.integer(forKey: SettingsKeys.Achievements.earlyBirdCount.rawValue) }
        set { defaults.set(newValue, forKey: SettingsKeys.Achievements.earlyBirdCount.rawValue) }
    }

    var nightOwlCount: Int {
        get { defaults.integer(forKey: SettingsKeys.Achievements.nightOwlCount.rawValue) }
        set { defaults.set(newValue, forKey: SettingsKeys.Achievements.nightOwlCount.rawValue) }
    }

    // MARK: AI Insights Settings
    var enableInsights: Bool {
        get { defaults.object(forKey: SettingsKeys.Insights.enableInsights.rawValue) as? Bool ?? true }
        set { defaults.set(newValue, forKey: SettingsKeys.Insights.enableInsights.rawValue) }
    }

    var enablePostSessionFeedback: Bool {
        get { defaults.object(forKey: SettingsKeys.Insights.enablePostSessionFeedback.rawValue) as? Bool ?? false }
        set { defaults.set(newValue, forKey: SettingsKeys.Insights.enablePostSessionFeedback.rawValue) }
    }

    var hasSeenAIPrivacyNotice: Bool {
        get { defaults.object(forKey: SettingsKeys.Insights.hasSeenAIPrivacyNotice.rawValue) as? Bool ?? false }
        set { defaults.set(newValue, forKey: SettingsKeys.Insights.hasSeenAIPrivacyNotice.rawValue) }
    }

    var currentLocation: String? {
        get { defaults.string(forKey: SettingsKeys.Insights.currentLocation.rawValue) }
        set { defaults.set(newValue, forKey: SettingsKeys.Insights.currentLocation.rawValue) }
    }

    var locationTags: [String] {
        get { defaults.stringArray(forKey: SettingsKeys.Insights.locationTags.rawValue) ?? ["Home", "Library", "Coffee Shop", "Office"] }
        set { defaults.set(newValue, forKey: SettingsKeys.Insights.locationTags.rawValue) }
    }

    var lastInsightCheck: Date? {
        get { defaults.object(forKey: SettingsKeys.Insights.lastInsightCheck.rawValue) as? Date }
        set { defaults.set(newValue, forKey: SettingsKeys.Insights.lastInsightCheck.rawValue) }
    }

    var insightCache: [CachedInsight] {
        get {
            guard let data = defaults.data(forKey: SettingsKeys.Insights.insightCache.rawValue),
                  let insights = try? JSONDecoder().decode([CachedInsight].self, from: data) else {
                return []
            }
            return insights
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: SettingsKeys.Insights.insightCache.rawValue)
            }
        }
    }

    private init() {}
}

// MARK: - Helper Extensions

extension Int {
    /// Returns the value if non-zero, otherwise returns the default
    func nonZeroOrDefault(_ defaultValue: Int) -> Int {
        self != 0 ? self : defaultValue
    }
}

extension String {
    /// Converts theme color string to SwiftUI Color
    var themeColor: Color {
        switch self {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        case "yellow": return .yellow
        case "mint": return .mint
        case "cyan": return .cyan
        case "brown": return .brown
        default: return .red
        }
    }
}

// MARK: - Session Type
/// Defines a custom pomodoro session with its own durations
struct SessionType: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var focusDuration: Int
    var shortBreakDuration: Int
    var longBreakDuration: Int
    var colorHex: String
    
    init(
        id: UUID = UUID(),
        name: String,
        focusDuration: Int = 25,
        shortBreakDuration: Int = 5,
        longBreakDuration: Int = 15,
        colorHex: String = "red"
    ) {
        self.id = id
        self.name = name
        self.focusDuration = focusDuration
        self.shortBreakDuration = shortBreakDuration
        self.longBreakDuration = longBreakDuration
        self.colorHex = colorHex
    }
    
    /// Pre-defined session presets
    static let defaultSessions: [SessionType] = [
        SessionType(name: "Focus", focusDuration: 25, shortBreakDuration: 5, longBreakDuration: 15, colorHex: "red"),
        SessionType(name: "Deep Work", focusDuration: 50, shortBreakDuration: 10, longBreakDuration: 30, colorHex: "blue"),
        SessionType(name: "Quick", focusDuration: 15, shortBreakDuration: 3, longBreakDuration: 10, colorHex: "green"),
    ]
}

// MARK: - Priority

enum Priority: String, Codable, CaseIterable, Comparable {
    case low, medium, high

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        let order: [Priority] = [.low, .medium, .high]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }

    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Todo Item
struct TodoItem: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var priority: Priority
    var linkedSessionCount: Int
    var dueDate: Date?

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, priority: Priority = .medium, dueDate: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.priority = priority
        self.linkedSessionCount = 0
        self.dueDate = dueDate
    }

    // Migration-safe decoding for existing data without new fields
    enum CodingKeys: String, CodingKey {
        case id, title, isCompleted, createdAt, priority, linkedSessionCount, dueDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        priority = try container.decodeIfPresent(Priority.self, forKey: .priority) ?? .medium
        linkedSessionCount = try container.decodeIfPresent(Int.self, forKey: .linkedSessionCount) ?? 0
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
    }
}

// MARK: - Session Time of Day

enum SessionTimeOfDay: String, Codable {
    case earlyMorning   // 5am-9am
    case lateMorning    // 9am-12pm
    case earlyAfternoon // 12pm-3pm
    case lateAfternoon  // 3pm-6pm
    case evening        // 6pm-9pm
    case night          // 9pm-12am
    case lateNight      // 12am-5am

    static func from(date: Date) -> SessionTimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<9: return .earlyMorning
        case 9..<12: return .lateMorning
        case 12..<15: return .earlyAfternoon
        case 15..<18: return .lateAfternoon
        case 18..<21: return .evening
        case 21..<24: return .night
        default: return .lateNight
        }
    }
}

// MARK: - Session Record
struct SessionRecord: Codable, Identifiable {
    var id: UUID
    var date: Date
    var sessionType: String
    var duration: TimeInterval
    var completed: Bool
    var linkedTaskId: UUID?

    // AI/ML fields
    var plannedDuration: TimeInterval
    var interruptionCount: Int
    var zenMusicEnabled: Bool
    var focusQualityScore: Double?
    var timeOfDay: SessionTimeOfDay

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        sessionType: String,
        duration: TimeInterval,
        completed: Bool,
        linkedTaskId: UUID? = nil,
        plannedDuration: TimeInterval? = nil,
        interruptionCount: Int = 0,
        zenMusicEnabled: Bool = false,
        focusQualityScore: Double? = nil,
        timeOfDay: SessionTimeOfDay? = nil
    ) {
        self.id = id
        self.date = date
        self.sessionType = sessionType
        self.duration = duration
        self.completed = completed
        self.linkedTaskId = linkedTaskId
        self.plannedDuration = plannedDuration ?? duration
        self.interruptionCount = interruptionCount
        self.zenMusicEnabled = zenMusicEnabled
        self.focusQualityScore = focusQualityScore
        self.timeOfDay = timeOfDay ?? SessionTimeOfDay.from(date: date)
    }

    // Migration-safe decoding for existing data without new fields
    enum CodingKeys: String, CodingKey {
        case id, date, sessionType, duration, completed, linkedTaskId
        case plannedDuration, interruptionCount, zenMusicEnabled
        case focusQualityScore, timeOfDay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        sessionType = try container.decode(String.self, forKey: .sessionType)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        completed = try container.decode(Bool.self, forKey: .completed)
        linkedTaskId = try container.decodeIfPresent(UUID.self, forKey: .linkedTaskId)
        plannedDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .plannedDuration) ?? duration
        interruptionCount = try container.decodeIfPresent(Int.self, forKey: .interruptionCount) ?? 0
        zenMusicEnabled = try container.decodeIfPresent(Bool.self, forKey: .zenMusicEnabled) ?? false
        focusQualityScore = try container.decodeIfPresent(Double.self, forKey: .focusQualityScore)
        timeOfDay = try container.decodeIfPresent(SessionTimeOfDay.self, forKey: .timeOfDay) ?? SessionTimeOfDay.from(date: date)
    }
}

// MARK: - Achievement
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    var isUnlocked: Bool
    var unlockedDate: Date?
    var progress: Int
    let goal: Int
}

// MARK: - Cached Insight
struct CachedInsight: Codable, Identifiable {
    var id: UUID
    var type: String
    var title: String
    var message: String
    var generatedAt: Date
    var priority: Int
    var actionable: Bool
    var dismissed: Bool
}

// MARK: - Timer State Data
/// Codable struct for persisting timer state across app launches
struct TimerStateData: Codable {
    var mode: String
    var timeRemaining: TimeInterval
    var completedSessions: Int
    var startTimeInterval: TimeInterval?
    var isRunning: Bool

    init(
        mode: String = "focus",
        timeRemaining: TimeInterval = 25 * 60,
        completedSessions: Int = 0,
        startTimeInterval: TimeInterval? = nil,
        isRunning: Bool = false
    ) {
        self.mode = mode
        self.timeRemaining = timeRemaining
        self.completedSessions = completedSessions
        self.startTimeInterval = startTimeInterval
        self.isRunning = isRunning
    }
}

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case `default` = "default"
    case darkNoir = "darkNoir"
    case pastel = "pastel"
    case neon = "neon"
    case nature = "nature"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: return L("theme.default")
        case .darkNoir: return L("theme.darkNoir")
        case .pastel: return L("theme.pastel")
        case .neon: return L("theme.neon")
        case .nature: return L("theme.nature")
        }
    }

    var icon: String {
        switch self {
        case .default: return "circle.lefthalf.filled"
        case .darkNoir: return "moon.stars.fill"
        case .pastel: return "paintpalette.fill"
        case .neon: return "bolt.fill"
        case .nature: return "leaf.fill"
        }
    }

    var forcesDarkMode: Bool {
        self == .darkNoir || self == .neon
    }

    var forcesLightMode: Bool {
        self == .pastel || self == .nature
    }

    var locksAppearance: Bool {
        forcesDarkMode || forcesLightMode
    }

    func colors(accent: Color) -> ThemeColors {
        switch self {
        case .default:
            return ThemeColors(
                background: Color(.windowBackgroundColor),
                cardBackground: Color(.windowBackgroundColor),
                cardShadow: Color.black.opacity(0.05),
                textPrimary: .primary,
                textSecondary: .secondary,
                glowIntensity: 1.0,
                shadowRadius: 10
            )
        case .darkNoir:
            return ThemeColors(
                background: Color(red: 0.10, green: 0.10, blue: 0.10),
                cardBackground: Color(red: 0.14, green: 0.14, blue: 0.14),
                cardShadow: Color.black.opacity(0.15),
                textPrimary: Color(white: 0.91),
                textSecondary: Color(white: 0.53),
                glowIntensity: 0.7,
                shadowRadius: 6
            )
        case .pastel:
            return ThemeColors(
                background: Color(red: 0.96, green: 0.94, blue: 0.92),
                cardBackground: Color(red: 1.0, green: 0.99, blue: 0.98),
                cardShadow: Color.black.opacity(0.03),
                textPrimary: Color(red: 0.29, green: 0.29, blue: 0.29),
                textSecondary: Color(red: 0.60, green: 0.60, blue: 0.60),
                glowIntensity: 0.5,
                shadowRadius: 12
            )
        case .neon:
            return ThemeColors(
                background: Color(red: 0.07, green: 0.07, blue: 0.09),
                cardBackground: Color(red: 0.11, green: 0.11, blue: 0.15),
                cardShadow: accent.opacity(0.2),
                textPrimary: Color(red: 0.94, green: 0.94, blue: 0.94),
                textSecondary: Color(red: 0.48, green: 0.48, blue: 0.54),
                glowIntensity: 1.8,
                shadowRadius: 15
            )
        case .nature:
            return ThemeColors(
                background: Color(red: 0.95, green: 0.93, blue: 0.89),
                cardBackground: Color(red: 0.97, green: 0.96, blue: 0.93),
                cardShadow: Color(red: 0.55, green: 0.45, blue: 0.33).opacity(0.08),
                textPrimary: Color(red: 0.24, green: 0.20, blue: 0.15),
                textSecondary: Color(red: 0.55, green: 0.45, blue: 0.33),
                glowIntensity: 0.8,
                shadowRadius: 10
            )
        }
    }
}

// MARK: - App Appearance

enum AppAppearance: String, CaseIterable {
    case system, light, dark

    var displayName: String {
        switch self {
        case .system: return L("appearance.system")
        case .light: return L("appearance.light")
        case .dark: return L("appearance.dark")
        }
    }
}

// MARK: - Theme Colors

struct ThemeColors {
    let background: Color
    let cardBackground: Color
    let cardShadow: Color
    let textPrimary: Color
    let textSecondary: Color
    let glowIntensity: CGFloat
    let shadowRadius: CGFloat

    static let `default` = AppTheme.default.colors(accent: .red)
}

// MARK: - Theme Manager

enum ThemeManager {
    static func colors(for themeRawValue: String, accent: Color) -> ThemeColors {
        let theme = AppTheme(rawValue: themeRawValue) ?? .default
        return theme.colors(accent: accent)
    }
}

// MARK: - Animation Style

enum AnimationStyle: String, CaseIterable {
    case smooth, snappy, gentle

    var displayName: String {
        switch self {
        case .smooth: return L("animation.smooth")
        case .snappy: return L("animation.snappy")
        case .gentle: return L("animation.gentle")
        }
    }
}

// MARK: - Animation Provider

enum AnimationProvider {
    /// Standard interaction spring (button taps, selections, toggles)
    static func spring(for styleRaw: String) -> Animation {
        let style = AnimationStyle(rawValue: styleRaw) ?? .smooth
        switch style {
        case .smooth: return .spring(response: 0.5, dampingFraction: 0.7)
        case .snappy: return .spring(response: 0.25, dampingFraction: 0.8)
        case .gentle: return .spring(response: 0.8, dampingFraction: 0.6)
        }
    }

    /// Quick feedback (button press, scale bounce)
    static func springFast(for styleRaw: String) -> Animation {
        let style = AnimationStyle(rawValue: styleRaw) ?? .smooth
        switch style {
        case .smooth: return .spring(response: 0.3, dampingFraction: 0.7)
        case .snappy: return .spring(response: 0.15, dampingFraction: 0.85)
        case .gentle: return .spring(response: 0.5, dampingFraction: 0.65)
        }
    }

    /// Larger transitions (card entrance, mode change, page transitions)
    static func springSlow(for styleRaw: String) -> Animation {
        let style = AnimationStyle(rawValue: styleRaw) ?? .smooth
        switch style {
        case .smooth: return .spring(response: 0.6, dampingFraction: 0.8)
        case .snappy: return .spring(response: 0.35, dampingFraction: 0.85)
        case .gentle: return .spring(response: 1.0, dampingFraction: 0.65)
        }
    }
}
