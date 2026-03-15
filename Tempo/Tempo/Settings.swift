//  Tempo - A Pomodoro timer app for macOS
//  Settings.swift - Core settings and timer management

import Foundation
import SwiftUI
import Combine
import AudioToolbox
import UserNotifications
import AVFoundation

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
    }
    
    enum Session: String, CaseIterable {
        case currentSessionName, customSessions
    }
    
    enum Stats: String, CaseIterable {
        case totalFocusTime, totalSessions, todaySessions
        case lastSessionDate, weeklyData
    }
    
    enum Persistence: String, CaseIterable {
        case savedTimerState
    }
}

// MARK: - Settings Store
// Singleton class for managing all app settings via UserDefaults
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    private let defaults = UserDefaults.standard
    
    // MARK: Timer Settings
    var focusDuration: Int {
        get { defaults.integer(forKey: "focusDuration").nonZeroOrDefault(25) }
        set { defaults.set(newValue, forKey: "focusDuration") }
    }
    
    var shortBreakDuration: Int {
        get { defaults.integer(forKey: "shortBreakDuration").nonZeroOrDefault(5) }
        set { defaults.set(newValue, forKey: "shortBreakDuration") }
    }
    
    var longBreakDuration: Int {
        get { defaults.integer(forKey: "longBreakDuration").nonZeroOrDefault(15) }
        set { defaults.set(newValue, forKey: "longBreakDuration") }
    }
    
    var autoStartBreaks: Bool {
        get { defaults.object(forKey: "autoStartBreaks") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "autoStartBreaks") }
    }
    
    var autoStartFocus: Bool {
        get { defaults.object(forKey: "autoStartFocus") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "autoStartFocus") }
    }
    
    // MARK: Behavior Settings
    var enableNotifications: Bool {
        get { defaults.object(forKey: "enableNotifications") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "enableNotifications") }
    }
    
    var enableSounds: Bool {
        get { defaults.object(forKey: "enableSounds") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "enableSounds") }
    }
    
    var enableZenMusic: Bool {
        get { defaults.object(forKey: "enableZenMusic") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "enableZenMusic") }
    }
    
    // MARK: Appearance Settings
    var themeColor: String {
        get { defaults.string(forKey: "themeColor") ?? "red" }
        set { defaults.set(newValue, forKey: "themeColor") }
    }
    
    var overrideThemeColor: Bool {
        get { defaults.object(forKey: "overrideThemeColor") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "overrideThemeColor") }
    }
    
    var selectedTab: Int {
        get { defaults.integer(forKey: "selectedTab") }
        set { defaults.set(newValue, forKey: "selectedTab") }
    }
    
    // MARK: Session Settings
    var currentSessionName: String {
        get { defaults.string(forKey: "currentSessionName") ?? "" }
        set { defaults.set(newValue, forKey: "currentSessionName") }
    }
    
    var autoNameSessionFromTask: Bool {
        get { defaults.bool(forKey: "autoNameSessionFromTask") }
        set { defaults.set(newValue, forKey: "autoNameSessionFromTask") }
    }
    
    var customSessions: [SessionType] {
        get {
            guard let data = defaults.data(forKey: "customSessions"),
                  let sessions = try? JSONDecoder().decode([SessionType].self, from: data) else {
                return SessionType.defaultSessions
            }
            return sessions
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: "customSessions")
            }
        }
    }
    
    // MARK: Statistics Settings
    var totalFocusTime: Double {
        get { defaults.double(forKey: "totalFocusTime") }
        set { defaults.set(newValue, forKey: "totalFocusTime") }
    }
    
    var totalSessions: Int {
        get { defaults.integer(forKey: "totalSessions") }
        set { defaults.set(newValue, forKey: "totalSessions") }
    }
    
    var todaySessions: Int {
        get { defaults.integer(forKey: "todaySessions") }
        set { defaults.set(newValue, forKey: "todaySessions") }
    }
    
    var lastSessionDate: String {
        get { defaults.string(forKey: "lastSessionDate") ?? "" }
        set { defaults.set(newValue, forKey: "lastSessionDate") }
    }
    
    var weeklyDataJSON: String {
        get { defaults.string(forKey: "weeklyData") ?? "[]" }
        set { defaults.set(newValue, forKey: "weeklyData") }
    }
    
    var todos: [TodoItem] {
        get {
            guard let data = defaults.data(forKey: "todos"),
                  let todos = try? JSONDecoder().decode([TodoItem].self, from: data) else {
                return []
            }
            return todos
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: "todos")
            }
        }
    }
    
    func deleteCompletedTasks() {
        todos = todos.filter { !$0.isCompleted }
    }
    
    var currentTaskIndex: Int {
        get { defaults.integer(forKey: "currentTaskIndex") }
        set { defaults.set(newValue, forKey: "currentTaskIndex") }
    }
    
    var activeTasks: [TodoItem] {
        todos.filter { !$0.isCompleted }
    }
    
    var completedTasks: [TodoItem] {
        todos.filter { $0.isCompleted }
    }
    
    var tasksNeedingFocus: [TodoItem] {
        activeTasks.filter { $0.requiredMinutes > 0 }
    }
    
    var currentTask: TodoItem? {
        let focusTasks = tasksNeedingFocus
        guard !focusTasks.isEmpty else { return nil }
        if currentTaskIndex >= focusTasks.count {
            currentTaskIndex = 0
        }
        return focusTasks.first
    }
    
    func setCurrentTaskIndex(to taskId: UUID) {
        let active = activeTasks
        if let index = active.firstIndex(where: { $0.id == taskId }) {
            currentTaskIndex = index
        }
    }
    
    var totalTaskMinutes: Int {
        activeTasks.reduce(0) { $0 + $1.requiredMinutes }
    }
    
    var totalTaskTimeText: String {
        let total = totalTaskMinutes
        if total >= 60 {
            let hours = total / 60
            let mins = total % 60
            if mins > 0 {
                return "\(hours)h \(mins)m"
            }
            return "\(hours)h"
        }
        return "\(total)m"
    }
    
    func advanceToNextTask() {
        let active = activeTasks
        if currentTaskIndex < active.count - 1 {
            currentTaskIndex += 1
        }
    }
    
    func resetTaskIndex() {
        currentTaskIndex = 0
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

// MARK: - Todo Item
struct TodoItem: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var requiredMinutes: Int
    var sessionId: UUID?
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, requiredMinutes: Int = 25, sessionId: UUID? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.requiredMinutes = requiredMinutes
        self.sessionId = sessionId
    }
    
    var requiredTimeText: String {
        if requiredMinutes == 0 {
            return "None"
        }
        if requiredMinutes >= 60 {
            let hours = requiredMinutes / 60
            let mins = requiredMinutes % 60
            if mins > 0 {
                return "\(hours)h \(mins)m"
            }
            return "\(hours)h"
        }
        return "\(requiredMinutes)m"
    }
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

// MARK: - Timer Manager
/// Main controller for the pomodoro timer functionality
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
    @Published var currentTask: TodoItem?
    
    // MARK: - Private Properties
    private let settings = SettingsStore.shared
    private var timer: Timer?
    private var startTime: Date?
    
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
        let focusDurationDefault = defaults.integer(forKey: "focusDuration").nonZeroOrDefault(25)
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
        
        checkAndResetDailyCounter()
        loadWeeklyData()
        loadCurrentTask()
        
        NotificationCenter.default.addObserver(
            forName: .tasksDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadCurrentTask()
        }
    }
    
    private func loadCurrentTask() {
        currentTask = settings.currentTask
        if settings.autoNameSessionFromTask, let task = currentTask {
            currentSessionName = task.title
            settings.currentSessionName = task.title
        }
    }
    
    func refreshCurrentTask() {
        loadCurrentTask()
    }
    
    func markCurrentTaskCompleted() {
        guard let task = currentTask else { return }
        var todos = settings.todos
        if let index = todos.firstIndex(where: { $0.id == task.id }) {
            todos[index].isCompleted = true
            settings.todos = todos
            settings.advanceToNextTask()
            loadCurrentTask()
        }
    }
    
    // MARK: - Public Methods
    func start() {
        guard state != .running else { return }
        
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
                self.saveTimerState()
            } else {
                self.timerCompleted()
            }
        }
        state = .running
        saveTimerState()
    }
    
    func pause() {
        timer?.invalidate()
        state = .paused
        saveTimerState()
    }
    
    func stop() {
        timer?.invalidate()
        startTime = nil
        state = .stopped
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
        if settings.autoNameSessionFromTask, let task = settings.currentTask {
            currentSessionName = task.title
            settings.currentSessionName = task.title
        } else {
            currentSessionName = session.name
            settings.currentSessionName = session.name
        }
        settings.focusDuration = session.focusDuration
        settings.shortBreakDuration = session.shortBreakDuration
        settings.longBreakDuration = session.longBreakDuration
        
        if !settings.overrideThemeColor {
            settings.themeColor = session.colorHex
        }
        
        if state == .stopped {
            resetTimer()
        }
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
    
    func resetAllData() {
        stop()
        completedSessions = 0
        mode = .focus
        settings.totalFocusTime = 0
        settings.totalSessions = 0
        settings.todaySessions = 0
        settings.lastSessionDate = ""
        settings.weeklyDataJSON = "[]"
        resetTimer()
        startTime = nil
        resetTimerState()
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
            }
            
            // Mark current task as completed if user chose to do so
            markCurrentTaskCompleted()
            
            updateLastSessionDate()
            
            // Determine break type (long break every 4 sessions)
            if completedSessions % 4 == 0 {
                mode = .longBreak
                timeRemaining = longBreakTime
            } else {
                mode = .shortBreak
                timeRemaining = shortBreakTime
            }
            
            if settings.autoStartBreaks {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.start()
                }
            }
        } else {
            // Switch back to focus
            mode = .focus
            timeRemaining = focusTime
            
            if settings.autoStartFocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.start()
                }
            }
        }
        
        state = .stopped
        startTime = nil
        saveTimerState()
        playNotificationSound()
        loadCurrentTask()
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
        
        let last7Days = getLast7Days()
        let filtered = decoded.filter { last7Days.contains($0.date) }
        
        if let encoded = try? JSONEncoder().encode(filtered),
           let jsonString = String(data: encoded, encoding: .utf8) {
            settings.weeklyDataJSON = jsonString
            objectWillChange.send()
        }
    }
    
    private func getLast7Days() -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return (0..<7).map { offset in
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
        
        // Keep only last 7 days
        let last7Days = getLast7Days()
        weeklyData = weeklyData.filter { last7Days.contains($0.date) }
        
        if let encoded = try? JSONEncoder().encode(weeklyData),
           let jsonString = String(data: encoded, encoding: .utf8) {
            settings.weeklyDataJSON = jsonString
            objectWillChange.send()
        }
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
            UserDefaults.standard.set(data, forKey: "savedTimerState")
        }
    }
    
    private static func loadTimerState() -> TimerStateData? {
        guard let data = UserDefaults.standard.data(forKey: "savedTimerState"),
              let stateData = try? JSONDecoder().decode(TimerStateData.self, from: data) else {
            return nil
        }
        return stateData
    }
    
    private func resetTimerState() {
        UserDefaults.standard.removeObject(forKey: "savedTimerState")
    }
}

// MARK: - Zen Music Player
final class ZenMusicPlayer: ObservableObject {
    static let shared = ZenMusicPlayer()
    
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var settings: SettingsStore { SettingsStore.shared }
    
    private init() {}
    
    func toggle() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }
    
    func play() {
        guard !isPlaying else { return }
        
        isLoading = true
        
        guard let url = Bundle.main.url(forResource: "inner_peace", withExtension: "mp3") else {
            print("Failed to find inner_peace.mp3 in bundle")
            isLoading = false
            return
        }
        
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = 0.5
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        
        player?.play()
        isPlaying = true
        isLoading = false
    }
    
    func stop() {
        player?.pause()
        player = nil
        playerItem = nil
        isPlaying = false
        isLoading = false
    }
    
    func getCurrentStationName() -> String {
        return "Inner Peace"
    }
    
    func nextStation() {}
}
