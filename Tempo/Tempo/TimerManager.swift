//  Tempo - Timer Manager
//  Main controller for the pomodoro timer functionality

import Foundation
import SwiftUI
import Combine
import AudioToolbox
import UserNotifications

class TimerManager: ObservableObject {

    // MARK: - Types
    enum TimerState: String, Codable {
        case stopped, running, paused
    }

    enum TimerMode: String, Codable, CaseIterable {
        case focus = "Focus"
        case shortBreak = "Short Break"
        case longBreak = "Long Break"
    }

    struct DailyStat: Codable, Identifiable {
        var id: String { date }
        let date: String
        var sessions: Int
        var minutes: Double

        /// Returns day of week abbreviation (e.g., "Mon")
        var dayOfWeek: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let dateObj = formatter.date(from: date) else { return "" }
            formatter.dateFormat = "EEE"
            return formatter.string(from: dateObj)
        }
    }

    // MARK: - Published Properties
    @Published var timeRemaining: TimeInterval
    @Published var state: TimerState = .stopped
    @Published var mode: TimerMode = .focus
    @Published var completedSessions: Int = 0
    @Published var currentSessionName: String = ""
    @Published var availableSessions: [SessionType] = SessionType.defaultSessions
    @Published var activeTaskId: UUID? = nil
    @Published var todos: [TodoItem] = []

    // MARK: - Private Properties
    private let settings = SettingsStore.shared
    private var timer: Timer?
    private var startTime: Date?
    private var sessionInterruptions: Int = 0

    /// Persist activeTaskId to UserDefaults without using didSet
    /// (didSet on @Published can trigger re-entrancy during SwiftUI render cycles)
    func setActiveTask(_ id: UUID?) {
        activeTaskId = id
        settings.activeTaskId = id?.uuidString
    }

    // MARK: - Computed Properties
    private var focusTime: TimeInterval { TimeInterval(settings.focusDuration * 60) }
    private var shortBreakTime: TimeInterval { TimeInterval(settings.shortBreakDuration * 60) }
    private var longBreakTime: TimeInterval { TimeInterval(settings.longBreakDuration * 60) }

    var totalFocusTime: Double { settings.totalFocusTime }
    var totalSessionsCount: Int { settings.totalSessions }
    var todaySessionsCount: Int { settings.todaySessions }

    // MARK: - Initialization
    init() {
        let defaults = UserDefaults.standard
        let focusDurationDefault = defaults.integer(forKey: SettingsKeys.Timer.focusDuration.rawValue).nonZeroOrDefault(25)
        let focusTimeDefault = TimeInterval(focusDurationDefault * 60)

        // Restore saved timer state if available
        if let savedState = TimerManager.loadTimerState() {
            timeRemaining = savedState.timeRemaining
            mode = TimerMode(rawValue: savedState.mode) ?? .focus
            completedSessions = savedState.completedSessions

            // Resume timer if it was running
            if savedState.isRunning, let startInterval = savedState.startTimeInterval {
                let expectedElapsed = Date().timeIntervalSince1970 - startInterval
                let adjustedRemaining = savedState.timeRemaining - expectedElapsed

                if adjustedRemaining > 0 {
                    timeRemaining = adjustedRemaining
                    self.startTime = Date(timeIntervalSince1970: startInterval)
                    start()
                } else {
                    timeRemaining = focusTimeDefault
                    resetTimerState()
                }
            }
        } else {
            timeRemaining = focusTimeDefault
        }

        // Restore persisted sessions and session name
        availableSessions = settings.customSessions
        let savedSessionName = settings.currentSessionName
        if !savedSessionName.isEmpty {
            currentSessionName = savedSessionName
        }

        // Restore persisted active task
        if let savedTaskIdString = settings.activeTaskId,
           let savedTaskId = UUID(uuidString: savedTaskIdString) {
            activeTaskId = savedTaskId
        }

        checkAndResetDailyCounter()
        loadWeeklyData()
        reloadTodos()

        // Clear active task if the linked todo no longer exists or is completed
        if let taskId = activeTaskId,
           !todos.contains(where: { $0.id == taskId && !$0.isCompleted }) {
            activeTaskId = nil
            settings.activeTaskId = nil
        }
    }

    // MARK: - Public Methods
    func start() {
        guard state != .running else { return }

        if state == .stopped {
            sessionInterruptions = 0
        }
        startTime = Date()
        let newTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
                self.saveTimerState()
            } else {
                self.timerCompleted()
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
        state = .running
        saveTimerState()
    }

    func pause() {
        timer?.invalidate()
        state = .paused
        sessionInterruptions += 1
        saveTimerState()
    }

    func stop() {
        // Record incomplete session if stopping mid-focus
        if mode == .focus, let startTime = startTime {
            let record = SessionRecord(
                sessionType: currentSessionName.isEmpty ? "Focus" : currentSessionName,
                duration: Date().timeIntervalSince(startTime),
                completed: false,
                linkedTaskId: activeTaskId,
                plannedDuration: focusTime,
                interruptionCount: sessionInterruptions,
                zenMusicEnabled: settings.enableZenMusic
            )
            appendSessionRecord(record)
        }
        timer?.invalidate()
        startTime = nil
        state = .stopped
        sessionInterruptions = 0
        setActiveTask(nil)
        resetTimer()
        resetTimerState()
    }

    func skip() {
        let previousMode = mode
        switchMode()
        sendNotification(forCompletedMode: previousMode)
    }

    func togglePlayPause() {
        if state == .running {
            pause()
        } else {
            start()
        }
    }

    func updateTimerDuration() {
        if state == .stopped {
            resetTimer()
        }
        saveTimerState()
    }

    func setSession(_ session: SessionType) {
        currentSessionName = session.name
        settings.currentSessionName = session.name
        settings.focusDuration = session.focusDuration
        settings.shortBreakDuration = session.shortBreakDuration
        settings.longBreakDuration = session.longBreakDuration

        if !settings.overrideThemeColor {
            settings.themeColor = session.colorHex
        }

        // Record incomplete session and reset timer, but preserve active task
        if state != .stopped {
            if mode == .focus, let startTime = startTime {
                let record = SessionRecord(
                    sessionType: currentSessionName.isEmpty ? "Focus" : currentSessionName,
                    duration: Date().timeIntervalSince(startTime),
                    completed: false,
                    linkedTaskId: activeTaskId,
                    plannedDuration: focusTime,
                    interruptionCount: sessionInterruptions,
                    zenMusicEnabled: settings.enableZenMusic
                )
                appendSessionRecord(record)
            }
            timer?.invalidate()
            startTime = nil
            state = .stopped
            resetTimerState()
        }

        resetTimer()
    }

    func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    func getWeeklyData() -> [DailyStat] {
        guard let data = settings.weeklyDataJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([DailyStat].self, from: data) else {
            return []
        }
        return decoded
    }

    func getSessionHistory() -> [SessionRecord] {
        settings.sessionHistory
    }

    func updateSessions(_ sessions: [SessionType]) {
        availableSessions = sessions
        settings.customSessions = sessions
    }

    func reloadTodos() {
        todos = settings.todos
    }

    func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = Date()
        let allData = getWeeklyData()

        let dates = allData
            .compactMap { dateString -> Date? in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.date(from: dateString.date)
            }
            .sorted(by: >)

        var streak = 0
        var currentDate = today

        for date in dates {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            if calendar.isDate(date, inSameDayAs: currentDate) ||
               calendar.isDate(date, inSameDayAs: previousDay) {
                streak += 1
                currentDate = date
            } else {
                break
            }
        }
        return streak
    }

    func resetAllData() {
        stop()
        completedSessions = 0
        mode = .focus
        settings.totalFocusTime = 0
        settings.totalSessions = 0
        settings.todaySessions = 0
        settings.lastSessionDate = ""
        settings.weeklyDataJSON = "[]"
        settings.sessionHistory = []
        settings.bestStreakEver = 0
        AchievementManager.shared.resetAchievements()
        setActiveTask(nil)
        resetTimer()
        startTime = nil
        resetTimerState()
        objectWillChange.send()
    }

    func seedSampleData() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let calendar = Calendar.current
        let today = Date()

        var sampleWeeklyData: [DailyStat] = []
        let sampleData: [(daysAgo: Int, sessions: Int, minutes: Double)] = [
            (6, 4, 120),
            (5, 6, 180),
            (4, 3, 90),
            (3, 5, 150),
            (2, 7, 210),
            (1, 4, 120),
            (0, 2, 60)
        ]

        for data in sampleData {
            if let date = calendar.date(byAdding: .day, value: -data.daysAgo, to: today) {
                let dateString = dateFormatter.string(from: date)
                sampleWeeklyData.append(DailyStat(date: dateString, sessions: data.sessions, minutes: data.minutes))
            }
        }

        if let encoded = try? JSONEncoder().encode(sampleWeeklyData),
           let jsonString = String(data: encoded, encoding: .utf8) {
            settings.weeklyDataJSON = jsonString
        }

        settings.totalFocusTime = 930 * 60
        settings.totalSessions = 31
        settings.todaySessions = 2

        objectWillChange.send()
    }

    func seedFocusTestData() {
        let calendar = Calendar.current
        let today = Date()
        var testRecords: [SessionRecord] = []

        // Generate realistic session data over the past 14 days
        let sessionTypes = ["Focus", "Deep Work", "Quick"]
        let durations = [15, 25, 50] // minutes

        for daysAgo in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }

            // 3-6 sessions per day
            let sessionCount = Int.random(in: 3...6)

            for sessionIndex in 0..<sessionCount {
                // Spread sessions throughout the day
                let hour = [9, 11, 14, 16, 19, 21].randomElement() ?? 14
                guard let sessionDate = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date) else { continue }

                let sessionType = sessionTypes.randomElement() ?? "Focus"
                let plannedMinutes = durations.randomElement() ?? 25
                let plannedDuration = TimeInterval(plannedMinutes * 60)

                // 80% completion rate
                let completed = Double.random(in: 0...1) < 0.8
                let actualDuration = completed ? plannedDuration : plannedDuration * Double.random(in: 0.4...0.9)

                // Random interruptions (0-3)
                let interruptions = Int.random(in: 0...3)

                // Zen music ~40% of the time
                let zenMusic = Double.random(in: 0...1) < 0.4

                // Calculate quality score
                let avgQuality = testRecords.suffix(5).compactMap(\.focusQualityScore).reduce(0, +) / Double(max(1, testRecords.suffix(5).count))
                let qualityScore = FocusQualityModel.score(
                    for: SessionRecord(
                        date: sessionDate,
                        sessionType: sessionType,
                        duration: actualDuration,
                        completed: completed,
                        plannedDuration: plannedDuration,
                        interruptionCount: interruptions,
                        zenMusicEnabled: zenMusic
                    ),
                    recentAvgQuality: avgQuality
                )

                let record = SessionRecord(
                    date: sessionDate,
                    sessionType: sessionType,
                    duration: actualDuration,
                    completed: completed,
                    linkedTaskId: nil,
                    plannedDuration: plannedDuration,
                    interruptionCount: interruptions,
                    zenMusicEnabled: zenMusic,
                    focusQualityScore: qualityScore
                )

                testRecords.append(record)
            }
        }

        // Save to settings
        settings.sessionHistory = testRecords.sorted { $0.date < $1.date }

        // Update stats to match
        let totalMinutes = testRecords.filter(\.completed).reduce(0.0) { $0 + $1.duration }
        settings.totalFocusTime = totalMinutes
        settings.totalSessions = testRecords.filter(\.completed).count

        let todayRecords = testRecords.filter { calendar.isDateInToday($0.date) && $0.completed }
        settings.todaySessions = todayRecords.count

        // Update weekly data
        var weeklyData: [String: (sessions: Int, minutes: Double)] = [:]
        for record in testRecords.filter(\.completed) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: record.date)

            var stat = weeklyData[dateString] ?? (0, 0.0)
            stat.sessions += 1
            stat.minutes += record.duration / 60.0
            weeklyData[dateString] = stat
        }

        let dailyStats = weeklyData.map { DailyStat(date: $0.key, sessions: $0.value.sessions, minutes: $0.value.minutes) }
        if let encoded = try? JSONEncoder().encode(dailyStats),
           let jsonString = String(data: encoded, encoding: .utf8) {
            settings.weeklyDataJSON = jsonString
        }

        objectWillChange.send()
    }

    // MARK: - Private Methods
    private func timerCompleted() {
        timer?.invalidate()
        let completedMode = mode
        switchMode()
        sendNotification(forCompletedMode: completedMode)
    }

    private func switchMode() {
        timer?.invalidate()

        // Track statistics when completing a focus session
        if mode == .focus {
            completedSessions += 1
            settings.totalSessions += 1
            settings.todaySessions += 1

            // Record focus time
            if let startTime = startTime {
                let elapsedTime = Date().timeIntervalSince(startTime)
                settings.totalFocusTime += elapsedTime
                addToWeeklyData(time: elapsedTime)

                // Record session
                let record = SessionRecord(
                    sessionType: currentSessionName.isEmpty ? "Focus" : currentSessionName,
                    duration: elapsedTime,
                    completed: true,
                    linkedTaskId: activeTaskId,
                    plannedDuration: focusTime,
                    interruptionCount: sessionInterruptions,
                    zenMusicEnabled: settings.enableZenMusic
                )
                appendSessionRecord(record)

                // Increment linked todo
                if let taskId = activeTaskId {
                    incrementTodoSessionCount(taskId)
                }
            }

            updateLastSessionDate()

            // Check achievements
            let hour = Calendar.current.component(.hour, from: Date())
            let todayMinutes = getTodayFocusMinutes()
            let streak = calculateCurrentStreak()
            if streak > settings.bestStreakEver {
                settings.bestStreakEver = streak
            }
            AchievementManager.shared.checkAchievements(
                totalSessions: settings.totalSessions,
                todayMinutes: todayMinutes,
                currentStreak: streak,
                sessionType: currentSessionName.isEmpty ? "Focus" : currentSessionName,
                zenMusicEnabled: settings.enableZenMusic,
                completionHour: hour
            )

            // Determine break type (long break every 4 sessions)
            if completedSessions % 4 == 0 {
                mode = .longBreak
                timeRemaining = longBreakTime
            } else {
                mode = .shortBreak
                timeRemaining = shortBreakTime
            }

            if settings.autoStartBreaks {
                scheduleAutoStart()
            }
        } else {
            // Switch back to focus
            mode = .focus
            timeRemaining = focusTime

            if settings.autoStartFocus {
                scheduleAutoStart()
            }
        }

        state = .stopped
        startTime = nil
        saveTimerState()
        playNotificationSound()
    }

    /// Schedule auto-start using a RunLoop timer instead of DispatchQueue.main.asyncAfter
    /// to avoid firing during a SwiftUI render pass
    private func scheduleAutoStart() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            self?.start()
        }
    }

    private func resetTimer() {
        switch mode {
        case .focus: timeRemaining = focusTime
        case .shortBreak: timeRemaining = shortBreakTime
        case .longBreak: timeRemaining = longBreakTime
        }
    }

    private func checkAndResetDailyCounter() {
        let today = getTodayString()
        if settings.lastSessionDate != today {
            settings.todaySessions = 0
        }
    }

    private func updateLastSessionDate() {
        settings.lastSessionDate = getTodayString()
    }

    private func loadWeeklyData() {
        guard let data = settings.weeklyDataJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([DailyStat].self, from: data) else {
            settings.weeklyDataJSON = "[]"
            return
        }

        let last90Days = getLastNDays(90)
        let filtered = decoded.filter { last90Days.contains($0.date) }

        if let encoded = try? JSONEncoder().encode(filtered),
           let jsonString = String(data: encoded, encoding: .utf8) {
            settings.weeklyDataJSON = jsonString
            objectWillChange.send()
        }
    }

    private func getLast7Days() -> [String] {
        getLastNDays(7)
    }

    private func getLastNDays(_ n: Int) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return (0..<n).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            return formatter.string(from: date)
        }.reversed()
    }

    private func addToWeeklyData(time: TimeInterval) {
        let today = getTodayString()
        let minutes = time / 60

        var weeklyData: [DailyStat] = []

        if let data = settings.weeklyDataJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([DailyStat].self, from: data) {
            weeklyData = decoded
        }

        // Update or add today's stats
        if let index = weeklyData.firstIndex(where: { $0.date == today }) {
            weeklyData[index].sessions += 1
            weeklyData[index].minutes += minutes
        } else {
            weeklyData.append(DailyStat(date: today, sessions: 1, minutes: minutes))
        }

        // Keep last 90 days
        let last90Days = getLastNDays(90)
        weeklyData = weeklyData.filter { last90Days.contains($0.date) }

        if let encoded = try? JSONEncoder().encode(weeklyData),
           let jsonString = String(data: encoded, encoding: .utf8) {
            settings.weeklyDataJSON = jsonString
            objectWillChange.send()
        }
    }

    private func appendSessionRecord(_ record: SessionRecord) {
        var history = settings.sessionHistory
        history.append(record)
        // Trim to last 90 days
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        history = history.filter { $0.date >= cutoff }
        settings.sessionHistory = history
    }

    private func incrementTodoSessionCount(_ taskId: UUID) {
        var todos = settings.todos
        if let index = todos.firstIndex(where: { $0.id == taskId }) {
            todos[index].linkedSessionCount += 1
            settings.todos = todos
            self.todos = todos
        }
    }

    private func getTodayFocusMinutes() -> Double {
        let calendar = Calendar.current
        let todayRecords = settings.sessionHistory.filter {
            calendar.isDateInToday($0.date) && $0.completed
        }
        return todayRecords.reduce(0) { $0 + $1.duration } / 60.0
    }

    private func playNotificationSound() {
        guard settings.enableSounds else { return }
        AudioServicesPlaySystemSound(1036)
    }

    private func sendNotification(forCompletedMode: TimerMode) {
        guard settings.enableNotifications else { return }

        let content = UNMutableNotificationContent()

        switch forCompletedMode {
        case .focus:
            content.title = "Focus Session Complete! 🎯"
            content.body = "Great work! Time for a well-deserved break."
        case .shortBreak:
            content.title = "Break Complete! ☕️"
            content.body = "Refreshed and ready? Time for another focus session!"
        case .longBreak:
            content.title = "Long Break Complete! 🌟"
            content.body = "You've earned it! Ready for your next focus session?"
        }

        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - State Persistence
    private func saveTimerState() {
        let stateData = TimerStateData(
            mode: mode.rawValue,
            timeRemaining: timeRemaining,
            completedSessions: completedSessions,
            startTimeInterval: startTime?.timeIntervalSince1970,
            isRunning: state == .running
        )

        if let data = try? JSONEncoder().encode(stateData) {
            UserDefaults.standard.set(data, forKey: SettingsKeys.Persistence.savedTimerState.rawValue)
        }
    }

    private static func loadTimerState() -> TimerStateData? {
        guard let data = UserDefaults.standard.data(forKey: SettingsKeys.Persistence.savedTimerState.rawValue),
              let stateData = try? JSONDecoder().decode(TimerStateData.self, from: data) else {
            return nil
        }
        return stateData
    }

    private func resetTimerState() {
        UserDefaults.standard.removeObject(forKey: SettingsKeys.Persistence.savedTimerState.rawValue)
    }
}
