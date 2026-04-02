//  Tempo - Achievement Manager
//  Tracks and evaluates achievements/milestones

import Foundation
import SwiftUI
import Combine

final class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

    @Published var achievements: [Achievement] = []
    @Published var recentUnlock: Achievement? = nil

    private let settings = SettingsStore.shared

    private init() {
        loadAchievements()
    }

    // MARK: - Achievement Definitions

    static let templates: [Achievement] = [
        Achievement(id: "first_focus", title: "First Focus", description: "Complete your first focus session", icon: "target", isUnlocked: false, progress: 0, goal: 1),
        Achievement(id: "getting_started", title: "Getting Started", description: "Complete 5 focus sessions", icon: "flame", isUnlocked: false, progress: 0, goal: 5),
        Achievement(id: "dedicated", title: "Dedicated", description: "Complete 25 focus sessions", icon: "star.fill", isUnlocked: false, progress: 0, goal: 25),
        Achievement(id: "century", title: "Century", description: "Complete 100 focus sessions", icon: "medal.fill", isUnlocked: false, progress: 0, goal: 100),
        Achievement(id: "marathon", title: "Marathon", description: "Complete 500 focus sessions", icon: "figure.run", isUnlocked: false, progress: 0, goal: 500),
        Achievement(id: "early_bird", title: "Early Bird", description: "Complete 5 sessions before 9am", icon: "sunrise.fill", isUnlocked: false, progress: 0, goal: 5),
        Achievement(id: "night_owl", title: "Night Owl", description: "Complete 5 sessions after 8pm", icon: "moon.stars.fill", isUnlocked: false, progress: 0, goal: 5),
        Achievement(id: "streak_7", title: "Week Warrior", description: "Maintain a 7-day streak", icon: "bolt.fill", isUnlocked: false, progress: 0, goal: 7),
        Achievement(id: "streak_30", title: "Streak Master", description: "Maintain a 30-day streak", icon: "flame.fill", isUnlocked: false, progress: 0, goal: 30),
        Achievement(id: "deep_diver", title: "Deep Diver", description: "Complete 5 Deep Work sessions", icon: "brain.head.profile.fill", isUnlocked: false, progress: 0, goal: 5),
        Achievement(id: "focus_hour", title: "Focus Hour", description: "Accumulate 60 min of focus in a single day", icon: "clock.fill", isUnlocked: false, progress: 0, goal: 60),
        Achievement(id: "zen_master", title: "Zen Master", description: "Complete 10 sessions with zen music", icon: "leaf.fill", isUnlocked: false, progress: 0, goal: 10),
    ]

    // MARK: - Persistence

    func loadAchievements() {
        let stored = settings.achievements
        if stored.isEmpty {
            achievements = Self.templates
            saveAchievements()
        } else {
            // Merge: keep stored progress but add any new template achievements
            var merged = stored
            for template in Self.templates {
                if !merged.contains(where: { $0.id == template.id }) {
                    merged.append(template)
                }
            }
            achievements = merged
        }
    }

    func saveAchievements() {
        settings.achievements = achievements
    }

    func resetAchievements() {
        achievements = Self.templates
        settings.zenSessionCount = 0
        settings.earlyBirdCount = 0
        settings.nightOwlCount = 0
        saveAchievements()
        recentUnlock = nil
    }

    // MARK: - Achievement Checking

    func checkAchievements(
        totalSessions: Int,
        todayMinutes: Double,
        currentStreak: Int,
        sessionType: String,
        zenMusicEnabled: Bool,
        completionHour: Int
    ) {
        // Session count achievements
        updateProgress(id: "first_focus", value: totalSessions)
        updateProgress(id: "getting_started", value: totalSessions)
        updateProgress(id: "dedicated", value: totalSessions)
        updateProgress(id: "century", value: totalSessions)
        updateProgress(id: "marathon", value: totalSessions)

        // Time-of-day achievements
        if completionHour < 9 {
            settings.earlyBirdCount += 1
            updateProgress(id: "early_bird", value: settings.earlyBirdCount)
        }
        if completionHour >= 20 {
            settings.nightOwlCount += 1
            updateProgress(id: "night_owl", value: settings.nightOwlCount)
        }

        // Streak achievements
        updateProgress(id: "streak_7", value: currentStreak)
        updateProgress(id: "streak_30", value: currentStreak)

        // Session type achievement
        if sessionType == "Deep Work" {
            let idx = achievements.firstIndex(where: { $0.id == "deep_diver" })
            if let idx, !achievements[idx].isUnlocked {
                achievements[idx].progress += 1
                checkUnlock(at: idx)
            }
        }

        // Focus hour (daily minutes)
        updateProgress(id: "focus_hour", value: Int(todayMinutes))

        // Zen music achievement
        if zenMusicEnabled {
            settings.zenSessionCount += 1
            updateProgress(id: "zen_master", value: settings.zenSessionCount)
        }

        saveAchievements()
    }

    // MARK: - Helpers

    private func updateProgress(id: String, value: Int) {
        guard let idx = achievements.firstIndex(where: { $0.id == id }) else { return }
        if achievements[idx].isUnlocked { return }
        achievements[idx].progress = value
        checkUnlock(at: idx)
    }

    private func checkUnlock(at index: Int) {
        if achievements[index].progress >= achievements[index].goal && !achievements[index].isUnlocked {
            achievements[index].isUnlocked = true
            achievements[index].unlockedDate = Date()
            recentUnlock = achievements[index]
        }
    }

    var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }
}
