//  Tempo - AI Insights Engine
//  Analyzes session history to generate productivity insights

import Foundation
import SwiftUI
import Combine

// MARK: - Insight Types

enum InsightType: String, Codable {
    case productivityPeak
    case recommendation
    case achievement
    case warning
    case trend
    case motivation
    case improvement

    var icon: String {
        switch self {
        case .productivityPeak: return "chart.line.uptrend.xyaxis"
        case .recommendation: return "lightbulb.fill"
        case .achievement: return "star.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .trend: return "arrow.up.right"
        case .motivation: return "flame.fill"
        case .improvement: return "arrow.triangle.2.circlepath"
        }
    }

    var color: Color {
        switch self {
        case .productivityPeak: return .blue
        case .recommendation: return .orange
        case .achievement: return .yellow
        case .warning: return .red
        case .trend: return .green
        case .motivation: return .purple
        case .improvement: return .cyan
        }
    }

    var actionSuggestion: String {
        switch self {
        case .productivityPeak: return L("insight.action.productivityPeak")
        case .recommendation:  return L("insight.action.recommendation")
        case .achievement:     return L("insight.action.achievement")
        case .warning:         return L("insight.action.warning")
        case .trend:           return L("insight.action.trend")
        case .motivation:      return L("insight.action.motivation")
        case .improvement:     return L("insight.action.improvement")
        }
    }
}

struct Insight: Identifiable {
    let id: UUID
    let type: InsightType
    let title: String
    let message: String
    let priority: Int // 1-5
    let actionable: Bool
    let generatedAt: Date
}

struct SmartSuggestion {
    let title: String
    let message: String
    let actionLabel: String
    let recommendedDuration: Int // minutes
    let confidence: Double // 0-1
}

// MARK: - Focus Quality Model

struct FocusQualityModel {
    /// Calculate focus quality score (0-1) for a session
    static func score(for record: SessionRecord, recentAvgQuality: Double?) -> Double {
        var score = 1.0

        // Factor 1: Completion (40%)
        if !record.completed {
            score -= 0.4
        }

        // Factor 2: Interruptions (25%)
        let interruptionPenalty = min(0.25, Double(record.interruptionCount) * 0.05)
        score -= interruptionPenalty

        // Factor 3: Duration vs Planned (20%)
        if record.completed && record.plannedDuration > 0 {
            let ratio = record.duration / record.plannedDuration
            if ratio < 0.8 || ratio > 1.2 {
                score -= 0.2 * abs(1.0 - ratio)
            }
        }

        // Factor 4: Consistency bonus (15%)
        if let avg = recentAvgQuality, score > avg {
            score += 0.05
        }

        return max(0, min(1, score))
    }

    static func ratingLabel(for score: Double) -> String {
        switch score {
        case 0.9...1.0:    return L("quality.excellent")
        case 0.75..<0.9:   return L("quality.good")
        case 0.6..<0.75:   return L("quality.fair")
        case 0.4..<0.6:    return L("quality.needsWork")
        default:           return L("quality.poor")
        }
    }
}

// MARK: - Productivity Pattern Model

struct ProductivityPatterns {
    var bestHourOfDay: Int
    var bestDayOfWeek: Int
    var avgSessionLength: TimeInterval
    var completionRateByHour: [Int: Double]
    var completionRateByDay: [Int: Double]
    var productivityScore: Double

    static let empty = ProductivityPatterns(
        bestHourOfDay: 14,
        bestDayOfWeek: 2,
        avgSessionLength: 25 * 60,
        completionRateByHour: [:],
        completionRateByDay: [:],
        productivityScore: 0
    )
}

struct ProductivityPatternModel {
    static func analyze(from history: [SessionRecord]) -> ProductivityPatterns {
        let completed = history.filter(\.completed)
        guard !completed.isEmpty else { return .empty }

        return ProductivityPatterns(
            bestHourOfDay: findBestHour(in: completed),
            bestDayOfWeek: findBestDay(in: completed),
            avgSessionLength: avgDuration(in: completed),
            completionRateByHour: completionByHour(in: history),
            completionRateByDay: completionByDay(in: history),
            productivityScore: productivityScore(in: completed)
        )
    }

    private static func findBestHour(in sessions: [SessionRecord]) -> Int {
        var counts: [Int: Int] = [:]
        for s in sessions {
            let hour = Calendar.current.component(.hour, from: s.date)
            counts[hour, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? 14
    }

    private static func findBestDay(in sessions: [SessionRecord]) -> Int {
        var counts: [Int: Int] = [:]
        for s in sessions {
            let wd = Calendar.current.component(.weekday, from: s.date)
            counts[wd, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? 2
    }

    private static func avgDuration(in sessions: [SessionRecord]) -> TimeInterval {
        sessions.reduce(0.0) { $0 + $1.duration } / Double(sessions.count)
    }

    private static func completionByHour(in sessions: [SessionRecord]) -> [Int: Double] {
        var stats: [Int: (completed: Int, total: Int)] = [:]
        for s in sessions {
            let hour = Calendar.current.component(.hour, from: s.date)
            var v = stats[hour] ?? (0, 0)
            v.total += 1
            if s.completed { v.completed += 1 }
            stats[hour] = v
        }
        return stats.mapValues { Double($0.completed) / Double($0.total) }
    }

    private static func completionByDay(in sessions: [SessionRecord]) -> [Int: Double] {
        var stats: [Int: (completed: Int, total: Int)] = [:]
        for s in sessions {
            let wd = Calendar.current.component(.weekday, from: s.date)
            var v = stats[wd] ?? (0, 0)
            v.total += 1
            if s.completed { v.completed += 1 }
            stats[wd] = v
        }
        return stats.mapValues { Double($0.completed) / Double($0.total) }
    }

    private static func productivityScore(in sessions: [SessionRecord]) -> Double {
        guard !sessions.isEmpty else { return 0 }

        let completionRate = Double(sessions.filter(\.completed).count) / Double(sessions.count)

        let durations = sessions.map(\.duration)
        let avg = durations.reduce(0, +) / Double(durations.count)
        let variance = durations.reduce(0) { $0 + pow($1 - avg, 2) } / Double(durations.count)
        let consistency = 1.0 - min(1.0, sqrt(variance) / (30 * 60))

        let avgInterruptions = Double(sessions.reduce(0) { $0 + $1.interruptionCount }) / Double(sessions.count)
        let interruptionScore = max(0, 1.0 - (avgInterruptions / 5.0))

        return (completionRate * 0.4) + (consistency * 0.3) + (interruptionScore * 0.3)
    }
}

// MARK: - Insights Engine

final class InsightsEngine: ObservableObject {
    static let shared = InsightsEngine()

    @Published var currentInsights: [Insight] = []
    @Published var smartSuggestion: SmartSuggestion?

    private let settings = SettingsStore.shared

    private init() {}

    // MARK: - Public API

    /// Refresh all insights from session history
    func refreshInsights(history: [SessionRecord]) {
        guard settings.enableInsights, !history.isEmpty else {
            currentInsights = []
            smartSuggestion = nil
            return
        }

        var insights: [Insight] = []

        let patterns = ProductivityPatternModel.analyze(from: history)
        insights.append(contentsOf: patternInsights(from: patterns))
        insights.append(contentsOf: qualityInsights(from: history))
        insights.append(contentsOf: adaptiveInsights(from: history))
        insights.append(contentsOf: streakInsights(from: history))
        insights.append(contentsOf: environmentalInsights(from: history))

        currentInsights = Array(insights.sorted { $0.priority > $1.priority }.prefix(6))

        smartSuggestion = generateSmartSuggestion(history: history, patterns: patterns)

        cacheInsights(currentInsights)
        settings.lastInsightCheck = Date()
    }

    /// Load cached insights (for when history isn't available yet)
    func loadCachedInsights() {
        let cached = settings.insightCache
        currentInsights = cached.map { c in
            Insight(
                id: c.id,
                type: InsightType(rawValue: c.type) ?? .recommendation,
                title: c.title,
                message: c.message,
                priority: c.priority,
                actionable: c.actionable,
                generatedAt: c.generatedAt
            )
        }
    }

    // MARK: - Smart Suggestion

    private func generateSmartSuggestion(history: [SessionRecord], patterns: ProductivityPatterns) -> SmartSuggestion? {
        let currentHour = Calendar.current.component(.hour, from: Date())
        guard let hourRate = patterns.completionRateByHour[currentHour], hourRate > 0.7 else {
            return nil
        }

        // Find the most successful duration bucket
        let completedDurations = history.filter(\.completed).map { Int($0.duration / 60) }
        guard !completedDurations.isEmpty else { return nil }

        let buckets = Dictionary(grouping: completedDurations) { ($0 / 5) * 5 }
        let bestBucket = buckets.max(by: { $0.value.count < $1.value.count })?.key ?? 25

        return SmartSuggestion(
            title: L("suggestion.title"),
            message: LF("suggestion.message", Int(hourRate * 100), bestBucket),
            actionLabel: LF("suggestion.actionLabel", bestBucket),
            recommendedDuration: bestBucket,
            confidence: hourRate
        )
    }

    // MARK: - Insight Generators

    private func patternInsights(from patterns: ProductivityPatterns) -> [Insight] {
        var insights: [Insight] = []

        // Best hour
        let calendar = Calendar.current
        if let bestHourDate = calendar.date(bySettingHour: patterns.bestHourOfDay, minute: 0, second: 0, of: Date()) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h a"
            let hourStr = formatter.string(from: bestHourDate)

            insights.append(Insight(
                id: UUID(),
                type: .productivityPeak,
                title: L("insight.peakHour.title"),
                message: LF("insight.peakHour.message", hourStr),
                priority: 5,
                actionable: true,
                generatedAt: Date()
            ))
        }

        // Productivity score
        let scorePercent = Int(patterns.productivityScore * 100)
        if patterns.productivityScore >= 0.8 {
            insights.append(Insight(
                id: UUID(),
                type: .achievement,
                title: L("insight.productivityMaster.title"),
                message: LF("insight.productivityMaster.message", scorePercent),
                priority: 4,
                actionable: false,
                generatedAt: Date()
            ))
        } else if patterns.productivityScore < 0.5 {
            insights.append(Insight(
                id: UUID(),
                type: .improvement,
                title: L("insight.roomForGrowth.title"),
                message: LF("insight.roomForGrowth.message", scorePercent),
                priority: 5,
                actionable: true,
                generatedAt: Date()
            ))
        }

        return insights
    }

    private func qualityInsights(from history: [SessionRecord]) -> [Insight] {
        let scores = history.suffix(10).compactMap(\.focusQualityScore)
        guard scores.count >= 5 else { return [] }

        let recentAvg = scores.suffix(3).reduce(0, +) / 3.0
        let olderAvg = scores.prefix(3).reduce(0, +) / 3.0
        let trend = recentAvg - olderAvg

        if trend > 0.1 {
            return [Insight(
                id: UUID(),
                type: .trend,
                title: L("insight.qualityImproving.title"),
                message: LF("insight.qualityImproving.message", Int(trend * 100)),
                priority: 4,
                actionable: false,
                generatedAt: Date()
            )]
        } else if trend < -0.1 {
            return [Insight(
                id: UUID(),
                type: .warning,
                title: L("insight.qualityDeclining.title"),
                message: L("insight.qualityDeclining.message"),
                priority: 5,
                actionable: true,
                generatedAt: Date()
            )]
        }
        return []
    }

    private func adaptiveInsights(from history: [SessionRecord]) -> [Insight] {
        let completed = history.filter(\.completed)
        guard completed.count >= 10 else { return [] }

        let grouped = Dictionary(grouping: completed) { Int($0.duration / 60 / 5) * 5 }
        guard let bestDuration = grouped.max(by: { $0.value.count < $1.value.count })?.key,
              bestDuration > 0 else { return [] }

        return [Insight(
            id: UUID(),
            type: .recommendation,
            title: L("insight.optimalLength.title"),
            message: LF("insight.optimalLength.message", bestDuration),
            priority: 4,
            actionable: true,
            generatedAt: Date()
        )]
    }

    private func streakInsights(from history: [SessionRecord]) -> [Insight] {
        let currentStreak = calculateStreak(from: history)
        let bestStreak = settings.bestStreakEver

        if currentStreak >= 7 && currentStreak < bestStreak {
            return [Insight(
                id: UUID(),
                type: .motivation,
                title: L("insight.strongStreak.title"),
                message: LF("insight.strongStreak.message", currentStreak, bestStreak - currentStreak),
                priority: 3,
                actionable: false,
                generatedAt: Date()
            )]
        } else if currentStreak > 0 && currentStreak >= bestStreak && bestStreak >= 7 {
            return [Insight(
                id: UUID(),
                type: .achievement,
                title: L("insight.newRecord.title"),
                message: LF("insight.newRecord.message", currentStreak),
                priority: 5,
                actionable: false,
                generatedAt: Date()
            )]
        }
        return []
    }

    private func environmentalInsights(from history: [SessionRecord]) -> [Insight] {
        var insights: [Insight] = []

        // Zen music impact
        let withZen = history.filter { $0.zenMusicEnabled && $0.completed }
        let withoutZen = history.filter { !$0.zenMusicEnabled && $0.completed }

        if withZen.count >= 5 && withoutZen.count >= 5 {
            let zenAvg = withZen.map(\.duration).reduce(0, +) / Double(withZen.count)
            let noZenAvg = withoutZen.map(\.duration).reduce(0, +) / Double(withoutZen.count)
            let improvement = (zenAvg - noZenAvg) / noZenAvg * 100

            if improvement > 15 {
                insights.append(Insight(
                    id: UUID(),
                    type: .recommendation,
                    title: L("insight.zenHelps.title"),
                    message: LF("insight.zenHelps.message", Int(improvement)),
                    priority: 4,
                    actionable: true,
                    generatedAt: Date()
                ))
            } else if improvement < -15 {
                insights.append(Insight(
                    id: UUID(),
                    type: .recommendation,
                    title: L("insight.tryWithoutZen.title"),
                    message: LF("insight.tryWithoutZen.message", Int(-improvement)),
                    priority: 4,
                    actionable: true,
                    generatedAt: Date()
                ))
            }
        }

        // Time-of-day pattern for interruptions
        let morningInterruptions = history.filter {
            let h = Calendar.current.component(.hour, from: $0.date)
            return h >= 5 && h < 12
        }
        let afternoonInterruptions = history.filter {
            let h = Calendar.current.component(.hour, from: $0.date)
            return h >= 12 && h < 18
        }

        if morningInterruptions.count >= 5 && afternoonInterruptions.count >= 5 {
            let morningAvg = Double(morningInterruptions.reduce(0) { $0 + $1.interruptionCount }) / Double(morningInterruptions.count)
            let afternoonAvg = Double(afternoonInterruptions.reduce(0) { $0 + $1.interruptionCount }) / Double(afternoonInterruptions.count)

            if morningAvg < afternoonAvg - 1 {
                insights.append(Insight(
                    id: UUID(),
                    type: .recommendation,
                    title: L("insight.morningsCalmer.title"),
                    message: L("insight.morningsCalmer.message"),
                    priority: 3,
                    actionable: true,
                    generatedAt: Date()
                ))
            }
        }

        return insights
    }

    // MARK: - Helpers

    private func calculateStreak(from history: [SessionRecord]) -> Int {
        let calendar = Calendar.current
        let completedDates = Set(history.filter(\.completed).map { calendar.startOfDay(for: $0.date) })
        guard let mostRecent = completedDates.max() else { return 0 }

        let today = calendar.startOfDay(for: Date())
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
        guard mostRecent == today || mostRecent == yesterday else { return 0 }

        var streak = 0
        var check = mostRecent
        while completedDates.contains(check) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: check) else { break }
            check = prev
        }
        return streak
    }

    private func cacheInsights(_ insights: [Insight]) {
        settings.insightCache = insights.map { i in
            CachedInsight(
                id: i.id,
                type: i.type.rawValue,
                title: i.title,
                message: i.message,
                generatedAt: i.generatedAt,
                priority: i.priority,
                actionable: i.actionable,
                dismissed: false
            )
        }
    }

    /// Clear all AI-related data
    func clearAllAIData() {
        settings.insightCache = []
        settings.lastInsightCheck = nil
        currentInsights = []
        smartSuggestion = nil
    }
}
