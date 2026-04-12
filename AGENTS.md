# AI-Powered Insights Implementation Plan

**Version:** 1.0  
**Created:** 2026-04-07  
**Target Version:** v2.0.0  
**Status:** Planning Phase

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [Phase 1: Data Collection & Foundation](#phase-1-data-collection--foundation)
4. [Phase 2: Local ML Models](#phase-2-local-ml-models)
5. [Phase 3: Insights Engine](#phase-3-insights-engine)
6. [Phase 4: UI/UX Integration](#phase-4-uiux-integration)
7. [Phase 5: Advanced Features](#phase-5-advanced-features)
8. [Privacy & Security](#privacy--security)
9. [Testing Strategy](#testing-strategy)
10. [Future Roadmap](#future-roadmap)

---

## Executive Summary

### Goal
Transform Tempo from a simple Pomodoro timer into an intelligent productivity companion that learns from user behavior and provides actionable insights to optimize focus sessions.

### Core Features (v2.0)
1. **Adaptive Timer Recommendations** - Learn optimal focus duration per user
2. **Productivity Pattern Detection** - Identify when users are most productive
3. **Focus Quality Scoring** - Track not just time, but effectiveness
4. **Smart Session Suggestions** - Recommend session types based on context

### Technical Approach
- **100% On-Device Processing** - No cloud dependencies, privacy-first
- **Core ML Integration** - Leverage Apple's ML framework for efficiency
- **Incremental Training** - Models improve as users complete more sessions
- **Lightweight Models** - <5MB total, minimal performance impact

---

## Architecture Overview

### Component Structure

```
Tempo/
├── AI/
│   ├── Models/
│   │   ├── InsightsEngine.swift          # Main coordinator
│   │   ├── AdaptiveTimerModel.swift      # Optimal duration predictor
│   │   ├── ProductivityPatternModel.swift # Time-of-day analyzer
│   │   ├── FocusQualityModel.swift       # Session quality scorer
│   │   └── SessionRecommender.swift      # Smart suggestions
│   ├── DataPipeline/
│   │   ├── FeatureExtractor.swift        # Raw data → ML features
│   │   ├── DataAggregator.swift          # Historical data processing
│   │   └── TrainingDataBuilder.swift     # Prepare training datasets
│   ├── CoreML/
│   │   ├── AdaptiveTimer.mlmodel         # Compiled Core ML model
│   │   ├── ProductivityPattern.mlmodel   # Time-based predictions
│   │   └── FocusQuality.mlmodel          # Quality assessment
│   └── Insights/
│       ├── InsightGenerator.swift        # Natural language insights
│       ├── InsightType.swift             # Insight categories
│       └── InsightStore.swift            # Persistence layer
├── Views/
│   ├── InsightsView.swift                # Main insights dashboard
│   ├── InsightCardView.swift             # Individual insight cards
│   └── SmartSuggestionBanner.swift       # Inline suggestions
└── Extensions/
    └── SessionRecord+ML.swift            # ML-specific extensions
```

### Data Flow

```
User Session → TimerManager → SessionRecord → FeatureExtractor
                                                     ↓
                                              ML Models (Core ML)
                                                     ↓
                                              InsightsEngine
                                                     ↓
                                    InsightGenerator → InsightStore
                                                     ↓
                                              UI (InsightsView)
```

---

## Phase 1: Data Collection & Foundation

### Objective
Expand data collection to support ML insights without impacting existing functionality.

### 1.1 Enhanced SessionRecord Model

**File:** `Tempo/Tempo/Settings.swift`

**Current Structure:**
```swift
struct SessionRecord: Codable, Identifiable {
    var id: UUID
    var date: Date
    var sessionType: String
    var duration: TimeInterval
    var completed: Bool
    var linkedTaskId: UUID?
}
```

**Enhanced Structure:**
```swift
struct SessionRecord: Codable, Identifiable {
    // Existing fields
    var id: UUID
    var date: Date
    var sessionType: String
    var duration: TimeInterval
    var completed: Bool
    var linkedTaskId: UUID?
    
    // NEW: AI/ML fields
    var plannedDuration: TimeInterval       // Originally intended duration
    var interruptionCount: Int              // Times paused during session
    var zenMusicEnabled: Bool               // Environmental factor
    var location: String?                   // "library", "dorm", "home" (optional)
    var energyLevel: Int?                   // 1-5 self-reported (optional)
    var completionNotes: String?            // Post-session reflection
    var focusQualityScore: Double?          // AI-calculated (0-1)
    var timeOfDay: SessionTimeOfDay         // Morning/Afternoon/Evening/Night
    var deviceContext: DeviceContext        // Battery, DND status, etc.
}

enum SessionTimeOfDay: String, Codable {
    case earlyMorning   // 5am-9am
    case lateMorning    // 9am-12pm
    case earlyAfternoon // 12pm-3pm
    case lateAfternoon  // 3pm-6pm
    case evening        // 6pm-9pm
    case night          // 9pm-12am
    case lateNight      // 12am-5am
}

struct DeviceContext: Codable {
    var batteryLevel: Float?           // 0-1
    var isDNDEnabled: Bool             // Do Not Disturb
    var appCount: Int?                 // Apps open during session
    var notificationCount: Int         // Interruptions
}
```

**Implementation Steps:**
1. Add new fields to SessionRecord with default values for backwards compatibility
2. Create migration helper to upgrade existing records
3. Update TimerManager to capture new data points
4. Add UI for optional user inputs (energy level, location tags)

**Migration Strategy:**
```swift
// Settings.swift
extension SessionRecord {
    static func migrate(from old: SessionRecord) -> SessionRecord {
        var new = old
        new.plannedDuration = old.duration
        new.interruptionCount = 0
        new.zenMusicEnabled = false
        new.timeOfDay = Self.calculateTimeOfDay(from: old.date)
        new.deviceContext = DeviceContext(
            batteryLevel: nil,
            isDNDEnabled: false,
            appCount: nil,
            notificationCount: 0
        )
        return new
    }
    
    private static func calculateTimeOfDay(from date: Date) -> SessionTimeOfDay {
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
```

### 1.2 Real-Time Data Capture

**File:** `Tempo/Tempo/TimerManager.swift`

**Modifications:**
```swift
class TimerManager: ObservableObject {
    // NEW: Track session metadata
    private var sessionStartContext: DeviceContext?
    private var sessionInterruptions: Int = 0
    
    func start() {
        // ... existing code ...
        
        // Capture session start context
        sessionStartContext = captureDeviceContext()
        sessionInterruptions = 0
    }
    
    func pause() {
        // ... existing code ...
        
        // Track interruptions
        sessionInterruptions += 1
    }
    
    private func timerCompleted() {
        // ... existing code ...
        
        let record = SessionRecord(
            id: UUID(),
            date: Date(),
            sessionType: currentSessionName.isEmpty ? mode.rawValue : currentSessionName,
            duration: focusTime,
            completed: true,
            linkedTaskId: activeTaskId,
            plannedDuration: focusTime,
            interruptionCount: sessionInterruptions,
            zenMusicEnabled: settings.enableZenMusic,
            location: settings.currentLocation, // New setting
            energyLevel: nil, // Prompted post-session
            completionNotes: nil,
            focusQualityScore: nil, // Calculated by ML
            timeOfDay: SessionRecord.calculateTimeOfDay(from: Date()),
            deviceContext: captureDeviceContext()
        )
        
        appendSessionRecord(record)
    }
    
    private func captureDeviceContext() -> DeviceContext {
        DeviceContext(
            batteryLevel: getBatteryLevel(),
            isDNDEnabled: isDNDActive(),
            appCount: nil, // Requires accessibility permissions
            notificationCount: 0 // Track via NotificationCenter observer
        )
    }
    
    private func getBatteryLevel() -> Float? {
        // macOS-specific battery info
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(info).takeRetainedValue() as Array
        guard let source = sources.first else { return nil }
        
        if let description = IOPSGetPowerSourceDescription(info, source).takeUnretainedValue() as? [String: Any],
           let level = description[kIOPSCurrentCapacityKey] as? Int {
            return Float(level) / 100.0
        }
        return nil
    }
    
    private func isDNDActive() -> Bool {
        // Check macOS Focus mode status via NSWorkspace
        // Note: Requires Screen Recording permission in macOS 12+
        return false // Placeholder
    }
}
```

### 1.3 Settings Extensions

**File:** `Tempo/Tempo/Settings.swift`

```swift
// Add to SettingsStore
extension SettingsStore {
    // MARK: ML/AI Settings
    var enableInsights: Bool {
        get { defaults.object(forKey: "enableInsights") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "enableInsights") }
    }
    
    var currentLocation: String? {
        get { defaults.string(forKey: "currentLocation") }
        set { defaults.set(newValue, forKey: "currentLocation") }
    }
    
    var locationTags: [String] {
        get { defaults.stringArray(forKey: "locationTags") ?? ["Home", "Library", "Coffee Shop", "Office"] }
        set { defaults.set(newValue, forKey: "locationTags") }
    }
    
    var lastInsightCheck: Date? {
        get { defaults.object(forKey: "lastInsightCheck") as? Date }
        set { defaults.set(newValue, forKey: "lastInsightCheck") }
    }
    
    var insightCache: [CachedInsight] {
        get {
            guard let data = defaults.data(forKey: "insightCache"),
                  let insights = try? JSONDecoder().decode([CachedInsight].self, from: data) else {
                return []
            }
            return insights
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: "insightCache")
            }
        }
    }
}

struct CachedInsight: Codable, Identifiable {
    var id: UUID
    var type: String
    var title: String
    var message: String
    var generatedAt: Date
    var priority: Int // 1-5
    var actionable: Bool
    var dismissed: Bool
}
```

**Timeline:** 1-2 weeks  
**Dependencies:** None  
**Risk:** Low - All changes are additive

---

## Phase 2: Local ML Models

### Objective
Build lightweight Core ML models for on-device inference.

### 2.1 Feature Engineering

**File:** `Tempo/AI/DataPipeline/FeatureExtractor.swift`

```swift
import Foundation
import CoreML

final class FeatureExtractor {
    
    /// Extract ML features from a session record
    static func extractFeatures(from record: SessionRecord) -> SessionFeatures {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .weekday], from: record.date)
        
        return SessionFeatures(
            // Temporal features
            hourOfDay: Double(components.hour ?? 12),
            dayOfWeek: Double(components.weekday ?? 1),
            isWeekend: (components.weekday ?? 1) > 5 ? 1.0 : 0.0,
            
            // Session features
            plannedDuration: record.plannedDuration / 60.0, // minutes
            actualDuration: record.duration / 60.0,
            wasCompleted: record.completed ? 1.0 : 0.0,
            interruptionCount: Double(record.interruptionCount),
            
            // Environmental features
            zenMusicEnabled: record.zenMusicEnabled ? 1.0 : 0.0,
            batteryLevel: Double(record.deviceContext.batteryLevel ?? 0.5),
            isDNDEnabled: record.deviceContext.isDNDEnabled ? 1.0 : 0.0,
            
            // Session type (one-hot encoded)
            isDeepWork: record.sessionType == "Deep Work" ? 1.0 : 0.0,
            isFocus: record.sessionType == "Focus" ? 1.0 : 0.0,
            isQuick: record.sessionType == "Quick" ? 1.0 : 0.0,
            
            // Historical context (requires aggregation)
            recentCompletionRate: 0.0, // Calculated separately
            currentStreak: 0.0
        )
    }
    
    /// Extract features with historical context
    static func extractFeaturesWithContext(
        from record: SessionRecord,
        history: [SessionRecord]
    ) -> SessionFeatures {
        var features = extractFeatures(from: record)
        
        // Calculate recent completion rate (last 10 sessions)
        let recent = history.suffix(10)
        if !recent.isEmpty {
            let completed = recent.filter(\.completed).count
            features.recentCompletionRate = Double(completed) / Double(recent.count)
        }
        
        // Calculate current streak
        features.currentStreak = Double(calculateStreak(from: history))
        
        return features
    }
    
    private static func calculateStreak(from history: [SessionRecord]) -> Int {
        let calendar = Calendar.current
        let completedDates = history
            .filter(\.completed)
            .map { calendar.startOfDay(for: $0.date) }
        
        guard let mostRecent = completedDates.max() else { return 0 }
        
        var streak = 0
        var checkDate = mostRecent
        
        while completedDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        
        return streak
    }
}

struct SessionFeatures: Codable {
    // Temporal
    var hourOfDay: Double
    var dayOfWeek: Double
    var isWeekend: Double
    
    // Session
    var plannedDuration: Double
    var actualDuration: Double
    var wasCompleted: Double
    var interruptionCount: Double
    
    // Environmental
    var zenMusicEnabled: Double
    var batteryLevel: Double
    var isDNDEnabled: Double
    
    // Session type
    var isDeepWork: Double
    var isFocus: Double
    var isQuick: Double
    
    // Historical
    var recentCompletionRate: Double
    var currentStreak: Double
}
```

### 2.2 Adaptive Timer Model

**Purpose:** Predict optimal focus duration based on context

**Training Data:** 
- Input: SessionFeatures (without actualDuration)
- Output: Optimal duration (minutes)
- Minimum data: 30 completed sessions

**Model Architecture:**
- Algorithm: Gradient Boosted Trees (fast inference, small size)
- Framework: Create ML (Apple's model training tool)
- Size: ~500KB

**File:** `Tempo/AI/Models/AdaptiveTimerModel.swift`

```swift
import Foundation
import CoreML

@available(macOS 12.0, *)
final class AdaptiveTimerModel {
    private var model: MLModel?
    private let featureExtractor = FeatureExtractor.self
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        // Load compiled Core ML model
        guard let modelURL = Bundle.main.url(forResource: "AdaptiveTimer", withExtension: "mlmodelc"),
              let loadedModel = try? MLModel(contentsOf: modelURL) else {
            print("⚠️ AdaptiveTimer model not found")
            return
        }
        self.model = loadedModel
    }
    
    /// Predict optimal focus duration in minutes
    func predictOptimalDuration(
        for context: SessionContext,
        history: [SessionRecord]
    ) -> TimeInterval? {
        guard let model = model else { return nil }
        
        // Create dummy record for feature extraction
        let dummyRecord = SessionRecord(
            id: UUID(),
            date: Date(),
            sessionType: context.sessionType,
            duration: 0, // Not used
            completed: true,
            linkedTaskId: nil,
            plannedDuration: 25 * 60,
            interruptionCount: 0,
            zenMusicEnabled: context.zenMusicEnabled,
            location: context.location,
            energyLevel: context.energyLevel,
            completionNotes: nil,
            focusQualityScore: nil,
            timeOfDay: SessionRecord.calculateTimeOfDay(from: Date()),
            deviceContext: context.deviceContext
        )
        
        let features = featureExtractor.extractFeaturesWithContext(
            from: dummyRecord,
            history: history
        )
        
        // Convert to ML input
        guard let prediction = try? model.prediction(from: features.toMLFeatureProvider()) else {
            return nil
        }
        
        // Extract predicted duration
        if let durationMinutes = prediction.featureValue(for: "predictedDuration")?.doubleValue {
            // Clamp to reasonable range (15-90 minutes)
            let clamped = max(15, min(90, durationMinutes))
            return clamped * 60 // Convert to seconds
        }
        
        return nil
    }
    
    /// Check if model has enough data to make predictions
    func hasMinimumData(history: [SessionRecord]) -> Bool {
        let completedSessions = history.filter(\.completed)
        return completedSessions.count >= 30
    }
}

struct SessionContext {
    var sessionType: String
    var zenMusicEnabled: Bool
    var location: String?
    var energyLevel: Int?
    var deviceContext: DeviceContext
}

extension SessionFeatures {
    func toMLFeatureProvider() -> MLFeatureProvider {
        // Convert struct to Core ML input format
        let dict: [String: Any] = [
            "hourOfDay": hourOfDay,
            "dayOfWeek": dayOfWeek,
            "isWeekend": isWeekend,
            "plannedDuration": plannedDuration,
            "interruptionCount": interruptionCount,
            "zenMusicEnabled": zenMusicEnabled,
            "batteryLevel": batteryLevel,
            "isDNDEnabled": isDNDEnabled,
            "isDeepWork": isDeepWork,
            "isFocus": isFocus,
            "isQuick": isQuick,
            "recentCompletionRate": recentCompletionRate,
            "currentStreak": currentStreak
        ]
        return try! MLDictionaryFeatureProvider(dictionary: dict)
    }
}
```

### 2.3 Productivity Pattern Model

**Purpose:** Identify peak productivity hours/days

**File:** `Tempo/AI/Models/ProductivityPatternModel.swift`

```swift
import Foundation

final class ProductivityPatternModel {
    private let settings = SettingsStore.shared
    
    /// Analyze productivity patterns across time periods
    func analyzePatterns(from history: [SessionRecord]) -> ProductivityPatterns {
        let completedSessions = history.filter(\.completed)
        
        guard !completedSessions.isEmpty else {
            return ProductivityPatterns.empty
        }
        
        return ProductivityPatterns(
            bestHourOfDay: findBestHour(in: completedSessions),
            bestDayOfWeek: findBestDay(in: completedSessions),
            avgSessionLength: calculateAvgDuration(in: completedSessions),
            completionRateByHour: completionByHour(in: history),
            completionRateByDay: completionByDay(in: history),
            productivityScore: calculateProductivityScore(in: completedSessions)
        )
    }
    
    private func findBestHour(in sessions: [SessionRecord]) -> Int {
        var hourCounts: [Int: Int] = [:]
        
        for session in sessions {
            let hour = Calendar.current.component(.hour, from: session.date)
            hourCounts[hour, default: 0] += 1
        }
        
        return hourCounts.max(by: { $0.value < $1.value })?.key ?? 14
    }
    
    private func findBestDay(in sessions: [SessionRecord]) -> Int {
        var dayCounts: [Int: Int] = [:]
        
        for session in sessions {
            let weekday = Calendar.current.component(.weekday, from: session.date)
            dayCounts[weekday, default: 0] += 1
        }
        
        return dayCounts.max(by: { $0.value < $1.value })?.key ?? 2
    }
    
    private func calculateAvgDuration(in sessions: [SessionRecord]) -> TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        let total = sessions.reduce(0.0) { $0 + $1.duration }
        return total / Double(sessions.count)
    }
    
    private func completionByHour(in sessions: [SessionRecord]) -> [Int: Double] {
        var hourStats: [Int: (completed: Int, total: Int)] = [:]
        
        for session in sessions {
            let hour = Calendar.current.component(.hour, from: session.date)
            var stats = hourStats[hour] ?? (completed: 0, total: 0)
            stats.total += 1
            if session.completed {
                stats.completed += 1
            }
            hourStats[hour] = stats
        }
        
        return hourStats.mapValues { stats in
            Double(stats.completed) / Double(stats.total)
        }
    }
    
    private func completionByDay(in sessions: [SessionRecord]) -> [Int: Double] {
        var dayStats: [Int: (completed: Int, total: Int)] = [:]
        
        for session in sessions {
            let weekday = Calendar.current.component(.weekday, from: session.date)
            var stats = dayStats[weekday] ?? (completed: 0, total: 0)
            stats.total += 1
            if session.completed {
                stats.completed += 1
            }
            dayStats[weekday] = stats
        }
        
        return dayStats.mapValues { stats in
            Double(stats.completed) / Double(stats.total)
        }
    }
    
    private func calculateProductivityScore(in sessions: [SessionRecord]) -> Double {
        guard !sessions.isEmpty else { return 0 }
        
        // Weighted score based on:
        // - Completion rate (40%)
        // - Session length consistency (30%)
        // - Interruption rate (30%)
        
        let completionRate = Double(sessions.filter(\.completed).count) / Double(sessions.count)
        
        let durations = sessions.map(\.duration)
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let variance = durations.reduce(0) { sum, duration in
            sum + pow(duration - avgDuration, 2)
        } / Double(durations.count)
        let consistency = 1.0 - min(1.0, sqrt(variance) / (30 * 60)) // Normalize
        
        let avgInterruptions = Double(sessions.reduce(0) { $0 + $1.interruptionCount }) / Double(sessions.count)
        let interruptionScore = max(0, 1.0 - (avgInterruptions / 5.0)) // 5+ interruptions = 0 score
        
        return (completionRate * 0.4) + (consistency * 0.3) + (interruptionScore * 0.3)
    }
}

struct ProductivityPatterns {
    var bestHourOfDay: Int          // 0-23
    var bestDayOfWeek: Int          // 1-7 (Sunday = 1)
    var avgSessionLength: TimeInterval
    var completionRateByHour: [Int: Double]
    var completionRateByDay: [Int: Double]
    var productivityScore: Double   // 0-1
    
    static let empty = ProductivityPatterns(
        bestHourOfDay: 14,
        bestDayOfWeek: 2,
        avgSessionLength: 25 * 60,
        completionRateByHour: [:],
        completionRateByDay: [:],
        productivityScore: 0
    )
}
```

### 2.4 Focus Quality Scoring

**Purpose:** Retroactively score session quality based on multiple factors

**File:** `Tempo/AI/Models/FocusQualityModel.swift`

```swift
import Foundation

final class FocusQualityModel {
    
    /// Calculate focus quality score (0-1) for a session
    func calculateQualityScore(for record: SessionRecord, context: QualityContext) -> Double {
        var score = 1.0
        
        // Factor 1: Completion (40% weight)
        if !record.completed {
            score -= 0.4
        }
        
        // Factor 2: Interruptions (25% weight)
        // Each interruption reduces score
        let interruptionPenalty = min(0.25, Double(record.interruptionCount) * 0.05)
        score -= interruptionPenalty
        
        // Factor 3: Duration vs Planned (20% weight)
        if record.completed && record.plannedDuration > 0 {
            let ratio = record.duration / record.plannedDuration
            // Ideal: completed as planned
            if ratio < 0.8 || ratio > 1.2 {
                score -= 0.2 * abs(1.0 - ratio)
            }
        }
        
        // Factor 4: Energy level (10% weight) - if provided
        if let energyLevel = record.energyLevel {
            // Higher energy = better quality
            let energyBonus = (Double(energyLevel) - 3.0) / 10.0 // -0.2 to +0.2
            score += energyBonus
        }
        
        // Factor 5: Consistency with personal bests (5% weight)
        if let avgQuality = context.recentAvgQuality {
            if score > avgQuality {
                score += 0.05 // Bonus for exceeding average
            }
        }
        
        return max(0, min(1, score))
    }
    
    /// Generate quality assessment with explanation
    func assessQuality(score: Double) -> QualityAssessment {
        let rating: QualityRating
        let feedback: String
        
        switch score {
        case 0.9...1.0:
            rating = .excellent
            feedback = "Outstanding focus! You maintained great concentration with minimal interruptions."
        case 0.75..<0.9:
            rating = .good
            feedback = "Solid session! You stayed on track with only minor distractions."
        case 0.6..<0.75:
            rating = .fair
            feedback = "Decent work, but there's room to reduce interruptions."
        case 0.4..<0.6:
            rating = .poor
            feedback = "This session had several interruptions. Try enabling Do Not Disturb next time."
        default:
            rating = .veryPoor
            feedback = "This session was challenging. Consider a shorter duration or changing your environment."
        }
        
        return QualityAssessment(score: score, rating: rating, feedback: feedback)
    }
}

struct QualityContext {
    var recentAvgQuality: Double?
    var userEnergyLevel: Int?
}

struct QualityAssessment {
    var score: Double
    var rating: QualityRating
    var feedback: String
}

enum QualityRating: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case veryPoor = "Needs Improvement"
}
```

**Timeline:** 3-4 weeks  
**Dependencies:** Phase 1 complete  
**Risk:** Medium - Requires Core ML model creation and testing

---

## Phase 3: Insights Engine

### Objective
Coordinate ML models and generate actionable insights.

### 3.1 Main Insights Engine

**File:** `Tempo/AI/Models/InsightsEngine.swift`

```swift
import Foundation
import Combine

final class InsightsEngine: ObservableObject {
    static let shared = InsightsEngine()
    
    @Published var currentInsights: [Insight] = []
    @Published var smartSuggestion: SmartSuggestion?
    
    private let adaptiveTimer = AdaptiveTimerModel()
    private let productivityPattern = ProductivityPatternModel()
    private let focusQuality = FocusQualityModel()
    private let insightGenerator = InsightGenerator()
    
    private let settings = SettingsStore.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Auto-refresh insights daily
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshInsights()
            }
            .store(in: &cancellables)
    }
    
    /// Generate all insights based on session history
    func refreshInsights() {
        guard settings.enableInsights else { return }
        
        let timerManager = TimerManager()
        let history = timerManager.getSessionHistory()
        
        guard !history.isEmpty else {
            currentInsights = []
            return
        }
        
        var insights: [Insight] = []
        
        // 1. Productivity Patterns
        let patterns = productivityPattern.analyzePatterns(from: history)
        insights.append(contentsOf: generatePatternInsights(from: patterns))
        
        // 2. Focus Quality Trends
        insights.append(contentsOf: generateQualityInsights(from: history))
        
        // 3. Adaptive Timer Recommendations
        if adaptiveTimer.hasMinimumData(history: history) {
            insights.append(contentsOf: generateAdaptiveInsights(from: history))
        }
        
        // 4. Streak & Consistency Insights
        insights.append(contentsOf: generateStreakInsights(from: history))
        
        // 5. Environmental Insights
        insights.append(contentsOf: generateEnvironmentalInsights(from: history))
        
        // Sort by priority and freshness
        currentInsights = insights
            .sorted { $0.priority > $1.priority }
            .prefix(5) // Top 5 insights
            .map { $0 }
        
        // Cache for offline access
        cacheInsights(currentInsights)
    }
    
    /// Generate smart suggestion for right now
    func generateSmartSuggestion() -> SmartSuggestion? {
        let timerManager = TimerManager()
        let history = timerManager.getSessionHistory()
        
        guard !history.isEmpty else { return nil }
        
        let patterns = productivityPattern.analyzePatterns(from: history)
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // Check if now is a good time to focus
        if let hourRate = patterns.completionRateByHour[currentHour] {
            if hourRate > 0.75 {
                // Predict optimal duration
                let context = SessionContext(
                    sessionType: "Focus",
                    zenMusicEnabled: settings.enableZenMusic,
                    location: settings.currentLocation,
                    energyLevel: nil,
                    deviceContext: DeviceContext(
                        batteryLevel: nil,
                        isDNDEnabled: false,
                        appCount: nil,
                        notificationCount: 0
                    )
                )
                
                if let optimalDuration = adaptiveTimer.predictOptimalDuration(
                    for: context,
                    history: history
                ) {
                    return SmartSuggestion(
                        title: "Great time to focus!",
                        message: "You're \(Int(hourRate * 100))% more productive at this hour. Try a \(Int(optimalDuration / 60))-minute session.",
                        actionLabel: "Start Session",
                        recommendedDuration: optimalDuration,
                        confidence: hourRate
                    )
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Insight Generators
    
    private func generatePatternInsights(from patterns: ProductivityPatterns) -> [Insight] {
        var insights: [Insight] = []
        
        // Best hour insight
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "ha"
        let bestHourString = hourFormatter.string(from: Calendar.current.date(
            bySettingHour: patterns.bestHourOfDay,
            minute: 0,
            second: 0,
            of: Date()
        )!)
        
        insights.append(Insight(
            id: UUID(),
            type: .productivityPeak,
            title: "Your Peak Hour",
            message: "You're most productive around \(bestHourString). Schedule important work for this time.",
            priority: 5,
            actionable: true,
            generatedAt: Date()
        ))
        
        // Productivity score insight
        let scorePercent = Int(patterns.productivityScore * 100)
        if patterns.productivityScore >= 0.8 {
            insights.append(Insight(
                id: UUID(),
                type: .achievement,
                title: "Productivity Master",
                message: "Your overall productivity score is \(scorePercent)%. You're crushing it!",
                priority: 4,
                actionable: false,
                generatedAt: Date()
            ))
        } else if patterns.productivityScore < 0.5 {
            insights.append(Insight(
                id: UUID(),
                type: .improvement,
                title: "Room for Growth",
                message: "Your productivity score is \(scorePercent)%. Try reducing interruptions and maintaining consistent session lengths.",
                priority: 5,
                actionable: true,
                generatedAt: Date()
            ))
        }
        
        return insights
    }
    
    private func generateQualityInsights(from history: [SessionRecord]) -> [Insight] {
        var insights: [Insight] = []
        
        // Calculate recent quality trend
        let recentSessions = history.suffix(10)
        let qualityScores = recentSessions.compactMap(\.focusQualityScore)
        
        guard qualityScores.count >= 5 else { return insights }
        
        let avgQuality = qualityScores.reduce(0, +) / Double(qualityScores.count)
        let trend = qualityScores.suffix(3).reduce(0, +) / 3.0 - qualityScores.prefix(3).reduce(0, +) / 3.0
        
        if trend > 0.1 {
            insights.append(Insight(
                id: UUID(),
                type: .trend,
                title: "Quality Improving",
                message: "Your focus quality has increased by \(Int(trend * 100))% recently. Keep it up!",
                priority: 4,
                actionable: false,
                generatedAt: Date()
            ))
        } else if trend < -0.1 {
            insights.append(Insight(
                id: UUID(),
                type: .warning,
                title: "Quality Declining",
                message: "Your focus quality has dropped. Consider taking a longer break or changing your environment.",
                priority: 5,
                actionable: true,
                generatedAt: Date()
            ))
        }
        
        return insights
    }
    
    private func generateAdaptiveInsights(from history: [SessionRecord]) -> [Insight] {
        var insights: [Insight] = []
        
        // Analyze completion rates by session length
        let grouped = Dictionary(grouping: history.filter(\.completed)) { record in
            Int(record.duration / 60 / 5) * 5 // Group by 5-minute buckets
        }
        
        if let bestDuration = grouped.max(by: { $0.value.count < $1.value.count })?.key {
            insights.append(Insight(
                id: UUID(),
                type: .recommendation,
                title: "Optimal Session Length",
                message: "You complete \(bestDuration)-minute sessions most consistently. Consider using this as your default.",
                priority: 4,
                actionable: true,
                generatedAt: Date()
            ))
        }
        
        return insights
    }
    
    private func generateStreakInsights(from history: [SessionRecord]) -> [Insight] {
        var insights: [Insight] = []
        
        let currentStreak = calculateCurrentStreak(from: history)
        let bestStreak = settings.bestStreakEver
        
        if currentStreak >= 7 && currentStreak < bestStreak {
            insights.append(Insight(
                id: UUID(),
                type: .motivation,
                title: "Strong Streak!",
                message: "You're at \(currentStreak) days! Just \(bestStreak - currentStreak) more to beat your record.",
                priority: 3,
                actionable: false,
                generatedAt: Date()
            ))
        } else if currentStreak > bestStreak {
            insights.append(Insight(
                id: UUID(),
                type: .achievement,
                title: "New Record!",
                message: "You've set a new personal best streak of \(currentStreak) days!",
                priority: 5,
                actionable: false,
                generatedAt: Date()
            ))
        }
        
        return insights
    }
    
    private func generateEnvironmentalInsights(from history: [SessionRecord]) -> [Insight] {
        var insights: [Insight] = []
        
        // Analyze zen music impact
        let withZen = history.filter { $0.zenMusicEnabled && $0.completed }
        let withoutZen = history.filter { !$0.zenMusicEnabled && $0.completed }
        
        if withZen.count >= 10 && withoutZen.count >= 10 {
            let zenAvgDuration = withZen.map(\.duration).reduce(0, +) / Double(withZen.count)
            let noZenAvgDuration = withoutZen.map(\.duration).reduce(0, +) / Double(withoutZen.count)
            
            let improvement = (zenAvgDuration - noZenAvgDuration) / noZenAvgDuration * 100
            
            if improvement > 15 {
                insights.append(Insight(
                    id: UUID(),
                    type: .recommendation,
                    title: "Zen Music Works!",
                    message: "You focus \(Int(improvement))% longer with zen music enabled.",
                    priority: 4,
                    actionable: true,
                    generatedAt: Date()
                ))
            }
        }
        
        // Analyze location impact (if available)
        let locationsWithData = Dictionary(grouping: history.filter { $0.location != nil }) { $0.location! }
        if locationsWithData.count >= 2 {
            let locationStats = locationsWithData.mapValues { sessions in
                Double(sessions.filter(\.completed).count) / Double(sessions.count)
            }
            
            if let bestLocation = locationStats.max(by: { $0.value < $1.value }) {
                if bestLocation.value > 0.8 {
                    insights.append(Insight(
                        id: UUID(),
                        type: .recommendation,
                        title: "Best Focus Spot",
                        message: "You're \(Int(bestLocation.value * 100))% more productive at \(bestLocation.key).",
                        priority: 4,
                        actionable: true,
                        generatedAt: Date()
                    ))
                }
            }
        }
        
        return insights
    }
    
    // MARK: - Helpers
    
    private func calculateCurrentStreak(from history: [SessionRecord]) -> Int {
        let calendar = Calendar.current
        let completedDates = history
            .filter(\.completed)
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()
        
        guard let mostRecent = completedDates.last else { return 0 }
        
        // Check if streak is current (today or yesterday)
        let today = calendar.startOfDay(for: Date())
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
        
        if mostRecent != today && mostRecent != yesterday {
            return 0 // Streak is broken
        }
        
        var streak = 0
        var checkDate = mostRecent
        
        while completedDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        
        return streak
    }
    
    private func cacheInsights(_ insights: [Insight]) {
        let cached = insights.map { insight in
            CachedInsight(
                id: insight.id,
                type: insight.type.rawValue,
                title: insight.title,
                message: insight.message,
                generatedAt: insight.generatedAt,
                priority: insight.priority,
                actionable: insight.actionable,
                dismissed: false
            )
        }
        settings.insightCache = cached
    }
}

// MARK: - Data Models

struct Insight: Identifiable {
    let id: UUID
    let type: InsightType
    let title: String
    let message: String
    let priority: Int // 1-5
    let actionable: Bool
    let generatedAt: Date
}

enum InsightType: String, Codable {
    case productivityPeak
    case recommendation
    case achievement
    case warning
    case trend
    case motivation
    case improvement
}

struct SmartSuggestion {
    let title: String
    let message: String
    let actionLabel: String
    let recommendedDuration: TimeInterval
    let confidence: Double // 0-1
}
```

**Timeline:** 2-3 weeks  
**Dependencies:** Phase 2 complete  
**Risk:** Low

---

## Phase 4: UI/UX Integration

### Objective
Create intuitive UI for displaying insights and suggestions.

### 4.1 Insights View

**File:** `Tempo/Views/InsightsView.swift`

```swift
import SwiftUI

struct InsightsView: View {
    @StateObject private var insightsEngine = InsightsEngine.shared
    @State private var showingFullInsight: Insight?
    
    private var themeColor: String { SettingsStore.shared.themeColor }
    private var accentColor: Color { themeColor.themeColor }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Insights")
                            .font(.system(size: 28, weight: .bold))
                        Text("Personalized productivity recommendations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { insightsEngine.refreshInsights() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Smart Suggestion Banner (if available)
                if let suggestion = insightsEngine.smartSuggestion {
                    SmartSuggestionBanner(suggestion: suggestion)
                        .padding(.horizontal)
                }
                
                // Insights Grid
                if insightsEngine.currentInsights.isEmpty {
                    EmptyInsightsView()
                        .padding(.top, 60)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(insightsEngine.currentInsights) { insight in
                            InsightCardView(insight: insight)
                                .onTapGesture {
                                    showingFullInsight = insight
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
            }
        }
        .onAppear {
            if insightsEngine.currentInsights.isEmpty {
                insightsEngine.refreshInsights()
            }
            insightsEngine.smartSuggestion = insightsEngine.generateSmartSuggestion()
        }
        .sheet(item: $showingFullInsight) { insight in
            InsightDetailView(insight: insight)
        }
    }
}

struct EmptyInsightsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Not Enough Data Yet")
                .font(.title3.bold())
            Text("Complete at least 10 focus sessions to unlock AI insights")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct InsightDetailView: View {
    @Environment(\.dismiss) var dismiss
    let insight: Insight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: insight.type.icon)
                    .font(.title)
                    .foregroundColor(insight.type.color)
                Text(insight.title)
                    .font(.title2.bold())
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            
            Text(insight.message)
                .font(.body)
            
            // Actionable suggestions
            if insight.actionable {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("What You Can Do")
                        .font(.headline)
                    Text(insight.type.actionSuggestion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 450, height: 300)
    }
}

extension InsightType {
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
        case .productivityPeak:
            return "Schedule your most important tasks during your peak hours for maximum efficiency."
        case .recommendation:
            return "Try implementing this recommendation for 1 week and track the results."
        case .achievement:
            return "Share your achievement with friends to stay motivated!"
        case .warning:
            return "Consider taking a longer break or adjusting your environment."
        case .trend:
            return "Keep doing what you're doing - you're on the right track!"
        case .motivation:
            return "Don't break the chain! Complete one session today to maintain momentum."
        case .improvement:
            return "Focus on reducing one source of distraction at a time."
        }
    }
}
```

### 4.2 Insight Card Component

**File:** `Tempo/Views/InsightCardView.swift`

```swift
import SwiftUI

struct InsightCardView: View {
    let insight: Insight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and priority indicator
            HStack {
                Image(systemName: insight.type.icon)
                    .font(.title2)
                    .foregroundColor(insight.type.color)
                Spacer()
                if insight.priority >= 4 {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                }
            }
            
            // Title
            Text(insight.title)
                .font(.headline)
                .lineLimit(2)
            
            // Message
            Text(insight.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Actionable indicator
            if insight.actionable {
                Label("Action recommended", systemImage: "hand.tap.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(insight.type.color.opacity(0.3), lineWidth: 1)
        )
    }
}
```

### 4.3 Smart Suggestion Banner

**File:** `Tempo/Views/SmartSuggestionBanner.swift`

```swift
import SwiftUI

struct SmartSuggestionBanner: View {
    let suggestion: SmartSuggestion
    @State private var timerManager = TimerManager()
    
    private var themeColor: String { SettingsStore.shared.themeColor }
    private var accentColor: Color { themeColor.themeColor }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundColor(.yellow)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.headline)
                Text(suggestion.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action button
            Button(action: {
                startSuggestedSession()
            }) {
                Text(suggestion.actionLabel)
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.2), accentColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.5), lineWidth: 2)
        )
    }
    
    private func startSuggestedSession() {
        // Set recommended duration
        let minutes = Int(suggestion.recommendedDuration / 60)
        SettingsStore.shared.focusDuration = minutes
        
        // Start timer
        timerManager.reset()
        timerManager.start()
        
        // Show notification
        // TODO: Add haptic feedback and notification
    }
}
```

### 4.4 Integration into Main App

**File:** `Tempo/Tempo/ContentView.swift`

Modifications:
```swift
// Add Insights tab to sidebar
enum Tab: String, CaseIterable {
    case timer = "Timer"
    case insights = "Insights"  // NEW
    case stats = "Stats"
    case help = "Help"
    
    var icon: String {
        switch self {
        case .timer: return "timer"
        case .insights: return "brain.head.profile"  // NEW
        case .stats: return "chart.bar.fill"
        case .help: return "questionmark.circle"
        }
    }
}

// Add to view switcher
switch selectedTab {
case .timer:
    TimerView(timerManager: timerManager)
case .insights:
    InsightsView()  // NEW
case .stats:
    StatsView(timerManager: timerManager)
case .help:
    HelpView()
}
```

**Timeline:** 2-3 weeks  
**Dependencies:** Phase 3 complete  
**Risk:** Low

---

## Phase 5: Advanced Features

### Objective
Add polish, user feedback mechanisms, and advanced analytics.

### 5.1 Post-Session Feedback

**File:** `Tempo/Views/PostSessionFeedbackView.swift`

```swift
import SwiftUI

struct PostSessionFeedbackView: View {
    @Binding var isPresented: Bool
    let sessionRecord: SessionRecord
    @State private var energyLevel: Int = 3
    @State private var notes: String = ""
    
    var onSubmit: (Int, String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("How was your session?")
                .font(.title2.bold())
            
            Text("Your feedback helps improve future recommendations")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Energy level picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Energy Level")
                    .font(.headline)
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { level in
                        Button(action: { energyLevel = level }) {
                            VStack(spacing: 4) {
                                Image(systemName: energyIcon(for: level))
                                    .font(.title2)
                                Text("\(level)")
                                    .font(.caption)
                            }
                            .foregroundColor(energyLevel == level ? .blue : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (Optional)")
                    .font(.headline)
                TextEditor(text: $notes)
                    .frame(height: 80)
                    .border(Color.secondary.opacity(0.2), width: 1)
            }
            
            // Actions
            HStack {
                Button("Skip") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Submit") {
                    onSubmit(energyLevel, notes)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
    
    private func energyIcon(for level: Int) -> String {
        switch level {
        case 1: return "battery.0"
        case 2: return "battery.25"
        case 3: return "battery.50"
        case 4: return "battery.75"
        case 5: return "battery.100"
        default: return "battery.50"
        }
    }
}
```

### 5.2 Settings Integration

**File:** `Tempo/Tempo/SettingsView.swift`

Add AI/Insights settings section:
```swift
// Add to SettingsView
Section {
    Toggle("Enable AI Insights", isOn: $settings.enableInsights)
        .help("Get personalized productivity recommendations")
    
    if settings.enableInsights {
        Toggle("Post-Session Feedback", isOn: $settings.enablePostSessionFeedback)
            .help("Rate your energy level after each session")
        
        Picker("Location", selection: $settings.currentLocation) {
            Text("Not Set").tag(String?.none)
            ForEach(settings.locationTags, id: \.self) { location in
                Text(location).tag(String?.some(location))
            }
        }
        .help("Track productivity by location")
        
        Button("Manage Locations...") {
            showingLocationEditor = true
        }
        
        Button("Clear AI Data") {
            clearAIData()
        }
        .foregroundColor(.red)
    }
} header: {
    Label("AI Insights", systemImage: "brain")
}
```

**Timeline:** 2 weeks  
**Dependencies:** Phase 4 complete  
**Risk:** Low

---

## Privacy & Security

### Principles
1. **100% On-Device Processing** - No data leaves the user's Mac
2. **Transparent Data Usage** - Clear explanations of what's collected
3. **User Control** - Easy opt-out and data deletion
4. **Minimal Collection** - Only collect what's necessary

### Implementation

**Privacy Notice (First Launch):**
```swift
struct AIPrivacyNoticeView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Insights Privacy")
                .font(.title.bold())
            
            Text("Tempo's AI insights are powered by on-device machine learning. Here's what you should know:")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                PrivacyPoint(
                    icon: "lock.shield",
                    title: "100% Private",
                    description: "All analysis happens on your Mac. No data is sent to servers."
                )
                PrivacyPoint(
                    icon: "brain",
                    title: "Learning From You",
                    description: "The AI learns your patterns to provide personalized recommendations."
                )
                PrivacyPoint(
                    icon: "hand.raised",
                    title: "You're In Control",
                    description: "Opt out anytime and delete all AI data from settings."
                )
            }
            
            Button("I Understand") {
                SettingsStore.shared.hasSeenAIPrivacyNotice = true
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .frame(width: 500)
    }
}

struct PrivacyPoint: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

**Data Deletion:**
```swift
extension SettingsStore {
    func clearAllAIData() {
        // Clear session metadata
        var history = sessionHistory
        for i in 0..<history.count {
            history[i].energyLevel = nil
            history[i].completionNotes = nil
            history[i].focusQualityScore = nil
            history[i].location = nil
        }
        sessionHistory = history
        
        // Clear cached insights
        insightCache = []
        lastInsightCheck = nil
        
        // Clear location data
        currentLocation = nil
        
        print("✅ All AI data cleared")
    }
}
```

---

## Testing Strategy

### Unit Tests
```swift
// Tempo/TempoTests/AITests/FeatureExtractorTests.swift
import XCTest
@testable import Tempo

class FeatureExtractorTests: XCTestCase {
    func testBasicFeatureExtraction() {
        let record = SessionRecord(
            id: UUID(),
            date: Date(),
            sessionType: "Focus",
            duration: 25 * 60,
            completed: true,
            linkedTaskId: nil,
            plannedDuration: 25 * 60,
            interruptionCount: 0,
            zenMusicEnabled: true,
            location: nil,
            energyLevel: 4,
            completionNotes: nil,
            focusQualityScore: nil,
            timeOfDay: .lateMorning,
            deviceContext: DeviceContext(
                batteryLevel: 0.8,
                isDNDEnabled: true,
                appCount: nil,
                notificationCount: 0
            )
        )
        
        let features = FeatureExtractor.extractFeatures(from: record)
        
        XCTAssertEqual(features.zenMusicEnabled, 1.0)
        XCTAssertEqual(features.batteryLevel, 0.8)
        XCTAssertEqual(features.isDNDEnabled, 1.0)
        XCTAssertEqual(features.plannedDuration, 25.0)
        XCTAssertEqual(features.wasCompleted, 1.0)
    }
    
    func testContextualFeatures() {
        var history: [SessionRecord] = []
        for i in 0..<10 {
            history.append(createMockSession(completed: i % 2 == 0))
        }
        
        let testRecord = createMockSession(completed: true)
        let features = FeatureExtractor.extractFeaturesWithContext(
            from: testRecord,
            history: history
        )
        
        XCTAssertEqual(features.recentCompletionRate, 0.5)
    }
}
```

### Integration Tests
- Test InsightsEngine with realistic data sets
- Verify ML model predictions are reasonable
- Test privacy: ensure no network calls

### UI Tests
- Test insight card interactions
- Verify post-session feedback flow
- Test settings integration

---

## Future Roadmap

### v2.1 - Enhanced Analytics
- **Weekly AI Reports**: Email summaries with insights
- **Goal Setting**: Set focus time goals, track with AI
- **Burnout Detection**: Warn when working too much

### v2.2 - Social Features
- **Compare with Friends**: Anonymous productivity benchmarks
- **Shared Insights**: "Users like you focus best at 2pm"

### v2.3 - Advanced ML
- **Focus Interruption Prediction**: Warn before likely distractions
- **Task Duration Estimation**: AI estimates how long tasks will take
- **Calendar Integration**: Auto-schedule optimal focus blocks

### v3.0 - Multi-Device Sync
- **iOS Companion App**: iPhone/iPad with iCloud sync
- **Cross-Device Insights**: Unified analytics across devices
- **Apple Watch**: Quick session starts, haptic alerts

---

## Implementation Timeline

| Phase | Duration | Start | End |
|-------|----------|-------|-----|
| Phase 1 | 2 weeks | Week 1 | Week 2 |
| Phase 2 | 4 weeks | Week 3 | Week 6 |
| Phase 3 | 3 weeks | Week 7 | Week 9 |
| Phase 4 | 3 weeks | Week 10 | Week 12 |
| Phase 5 | 2 weeks | Week 13 | Week 14 |
| Testing & Polish | 2 weeks | Week 15 | Week 16 |
| **Total** | **16 weeks** | | |

---

## Success Metrics

### Technical
- [ ] ML models <5MB total size
- [ ] Inference <50ms per prediction
- [ ] Zero network requests
- [ ] <5% memory overhead

### User Experience
- [ ] 80%+ users enable insights
- [ ] 50%+ users rate insights as helpful
- [ ] 30%+ users adjust habits based on insights
- [ ] <2% disable feature after trying

### Product
- [ ] Unique differentiator in App Store
- [ ] Featured in "Productivity" category
- [ ] 4.5+ star rating maintained
- [ ] Positive reviews mentioning AI features

---

## Appendix

### Core ML Model Training

**Tools Required:**
- Create ML (macOS app)
- Python 3.8+ with coremltools
- Jupyter Notebook for experimentation

**Training Pipeline:**
1. Export session history to CSV
2. Feature engineering in Python/Pandas
3. Train model with Create ML
4. Export as .mlmodel file
5. Add to Xcode project
6. Compile and integrate

**Example Training Script:**
```python
import pandas as pd
import coremltools as ct
from sklearn.ensemble import GradientBoostingRegressor

# Load data
df = pd.read_csv('sessions.csv')

# Feature engineering
features = ['hourOfDay', 'dayOfWeek', 'plannedDuration', 'interruptionCount', 
            'zenMusicEnabled', 'batteryLevel', 'recentCompletionRate']
X = df[features]
y = df['actualDuration']

# Train model
model = GradientBoostingRegressor(n_estimators=100, max_depth=3)
model.fit(X, y)

# Convert to Core ML
coreml_model = ct.converters.sklearn.convert(
    model,
    input_features=features,
    output_feature_names='predictedDuration'
)

# Save
coreml_model.save('AdaptiveTimer.mlmodel')
```

### Performance Optimization

**Caching Strategy:**
- Cache insights for 24 hours
- Incremental updates (don't recalculate all insights on each session)
- Background processing using DispatchQueue

**Memory Management:**
- Lazy load ML models (only when insights tab is opened)
- Release models when not in use
- Stream large datasets instead of loading all at once

---

**Document Status:** Draft  
**Last Updated:** 2026-04-07  
**Owner:** Huatao Xue  
**Reviewers:** TBD
