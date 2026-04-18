//  Tempo - Statistics View
//  Displays user's productivity statistics and insights

import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var timerManager: TimerManager
    @StateObject private var achievementManager = AchievementManager.shared
    @ObservedObject private var locManager = LocalizationManager.shared

    // MARK: - State
    @State private var showMonthChart = false
    @State private var chartAppear = false

    // MARK: - Computed Properties
    private var themeColor: String { SettingsStore.shared.themeColor }
    private var accentColor: Color { themeColor.themeColor }
    private var appThemeValue: String { SettingsStore.shared.appTheme }
    private var theme: ThemeColors { ThemeManager.colors(for: appThemeValue, accent: accentColor) }

    private var weeklyData: [TimerManager.DailyStat] { timerManager.getWeeklyData() }

    private var totalSessionsThisWeek: Int {
        weeklyData.reduce(0) { $0 + $1.sessions }
    }

    /// Formats total focus time as "Xh Ym" or "Ym" if less than an hour
    private var totalTimeString: String {
        let totalSeconds = Int(timerManager.totalFocusTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Total hours focused this month
    private var monthHoursString: String {
        let history = timerManager.getSessionHistory()
        let totalSeconds = history.filter {
            Calendar.current.dateInterval(of: .month, for: Date())?.contains($0.date) ?? false
        }.reduce(0.0) { $0 + $1.duration }
        let hours = totalSeconds / 3600.0
        return String(format: "%.0fh", hours)
    }

    /// Session history grouped by session type with counts
    private var sessionTypeBreakdown: [(type: String, count: Int, color: Color)] {
        let history = timerManager.getSessionHistory()
        var grouped: [String: Int] = [:]
        for record in history {
            grouped[record.sessionType, default: 0] += 1
        }
        let colors: [Color] = [accentColor, .green, .orange, .purple, .pink, .teal, .indigo, .yellow]
        return grouped.sorted(by: { $0.value > $1.value }).enumerated().map { index, pair in
            (type: pair.key, count: pair.value, color: colors[index % colors.count])
        }
    }

    /// Chart data filtered by selected range
    private var chartData: [TimerManager.DailyStat] {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let daysBack = showMonthChart ? 30 : 7
        guard let cutoff = calendar.date(byAdding: .day, value: -daysBack, to: now) else {
            return weeklyData
        }

        return weeklyData.filter { stat in
            if let date = formatter.date(from: stat.date) {
                return date >= cutoff
            }
            return false
        }.sorted(by: { $0.date < $1.date })
    }

    // MARK: - Insight Helpers

    private var completionRate: String {
        let history = timerManager.getSessionHistory()
        guard !history.isEmpty else { return "0%" }
        let completed = history.filter(\.completed).count
        let rate = Double(completed) / Double(history.count) * 100
        return String(format: "%.0f%%", rate)
    }

    private var avgSessionMinutes: String {
        let history = timerManager.getSessionHistory().filter(\.completed)
        guard !history.isEmpty else { return "0m" }
        let totalDuration = history.reduce(0.0) { $0 + $1.duration }
        let avgMinutes = totalDuration / Double(history.count) / 60.0
        return String(format: "%.0fm", avgMinutes)
    }

    private var mostProductiveDay: String {
        let history = timerManager.getSessionHistory()
        guard !history.isEmpty else { return "N/A" }
        let calendar = Calendar.current
        var weekdayCounts: [Int: Int] = [:]
        for record in history {
            let weekday = calendar.component(.weekday, from: record.date)
            weekdayCounts[weekday, default: 0] += 1
        }
        guard let maxDay = weekdayCounts.max(by: { $0.value < $1.value }) else { return "N/A" }
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let symbols = formatter.weekdaySymbols ?? []
        let index = maxDay.key - 1
        guard index >= 0 && index < symbols.count else { return "N/A" }
        return symbols[index]
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                headerSection

                // Quick Stats Grid (2x2)
                statsGrid

                // Weekly/Monthly Chart
                if !weeklyData.isEmpty {
                    chartSection
                }

                // Session Type Breakdown
                if !sessionTypeBreakdown.isEmpty {
                    sessionTypeSection
                }

                // Insights Section
                insightsSection

                // Achievements Section
                achievementsSection

                Spacer().frame(height: 40)
            }
            .padding(.horizontal)
        }
        .background(theme.background)
        .onAppear { _ = timerManager.getWeeklyData() }
    }

    // MARK: - View Sections
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(L("stats.title"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            Text(L("stats.subtitle"))
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
        }
        .padding(.top, 20)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            StatCard(
                title: L("stats.today"),
                value: "\(timerManager.todaySessionsCount)",
                subtitle: L("stats.sessions"),
                icon: "flame.fill",
                color: accentColor,
                animationDelay: 0.1,
                themeColors: theme
            )

            StatCard(
                title: L("stats.thisWeek"),
                value: "\(totalSessionsThisWeek)",
                subtitle: L("stats.sessions"),
                icon: "calendar",
                color: accentColor,
                animationDelay: 0.2,
                themeColors: theme
            )

            StatCard(
                title: L("stats.totalTime"),
                value: totalTimeString,
                subtitle: L("stats.focused"),
                icon: "clock.fill",
                color: accentColor,
                animationDelay: 0.3,
                themeColors: theme
            )

            StatCard(
                title: L("stats.thisMonth"),
                value: monthHoursString,
                subtitle: L("stats.focused"),
                icon: "calendar.badge.clock",
                color: accentColor,
                animationDelay: 0.4,
                themeColors: theme
            )
        }
        .padding(.horizontal)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Segmented picker for Week/Month
            Picker(L("stats.chartRange"), selection: $showMonthChart) {
                Text(L("stats.week")).tag(false)
                Text(L("stats.month")).tag(true)
            }
            .pickerStyle(.segmented)

            Text(showMonthChart ? L("stats.thisMonth") : L("stats.thisWeek"))
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            Chart(chartData) { stat in
                BarMark(
                    x: .value("Day", stat.dayOfWeek),
                    y: .value("Sessions", stat.sessions)
                )
                .foregroundStyle(accentColor.gradient)
                .cornerRadius(4)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 200)
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: theme.cardShadow, radius: theme.shadowRadius, y: 5)
        .scaleEffect(chartAppear ? 1 : 0.95)
        .opacity(chartAppear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                chartAppear = true
            }
        }
    }

    // MARK: - Session Type Breakdown
    private var sessionTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("stats.sessionTypes"))
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            let maxCount = sessionTypeBreakdown.map(\.count).max() ?? 1

            ForEach(sessionTypeBreakdown, id: \.type) { item in
                HStack(spacing: 10) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 10, height: 10)

                    Text(item.type)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                        .frame(width: 80, alignment: .leading)

                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.color.opacity(0.7))
                            .frame(
                                width: max(4, geo.size.width * CGFloat(item.count) / CGFloat(maxCount)),
                                height: 16
                            )
                    }
                    .frame(height: 16)

                    Text("\(item.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: theme.cardShadow, radius: theme.shadowRadius, y: 5)
    }

    // MARK: - Insights
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("stats.insights"))
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            if !weeklyData.isEmpty {
                // 1. Best day insight
                if let bestDay = weeklyData.max(by: { $0.sessions < $1.sessions }) {
                    InsightCard(
                        title: L("stats.bestDay"),
                        description: LF("stats.bestDayDesc", bestDay.dayOfWeek, bestDay.sessions),
                        icon: "trophy.fill",
                        color: .yellow,
                        themeColors: theme,
                        animationDelay: 0.1
                    )
                }

                // 2. Daily average insight
                let averageSessions = weeklyData.isEmpty ? 0 : Double(totalSessionsThisWeek) / Double(weeklyData.count)
                InsightCard(
                    title: L("stats.dailyAverage"),
                    description: LF("stats.dailyAverageDesc", averageSessions),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    themeColors: theme,
                    animationDelay: 0.2
                )

                // 3. Current streak insight (with best streak)
                let currentStreak = timerManager.calculateCurrentStreak()
                let bestStreak = SettingsStore.shared.bestStreakEver
                InsightCard(
                    title: L("stats.currentStreak"),
                    description: LF("stats.currentStreakDesc", currentStreak, bestStreak),
                    icon: "bolt.fill",
                    color: .orange,
                    themeColors: theme,
                    animationDelay: 0.3
                )

                // 4. Completion Rate
                InsightCard(
                    title: L("stats.completionRate"),
                    description: completionRate,
                    icon: "checkmark.circle.fill",
                    color: .blue,
                    themeColors: theme,
                    animationDelay: 0.4
                )

                // 5. Average Session
                InsightCard(
                    title: L("stats.avgSession"),
                    description: avgSessionMinutes,
                    icon: "timer",
                    color: .purple,
                    themeColors: theme,
                    animationDelay: 0.5
                )

                // 6. Most Productive Day
                InsightCard(
                    title: L("stats.mostProductiveDay"),
                    description: mostProductiveDay,
                    icon: "star.fill",
                    color: .mint,
                    themeColors: theme,
                    animationDelay: 0.6
                )
            } else {
                InsightCard(
                    title: L("stats.noDataYet"),
                    description: L("stats.noDataDesc"),
                    icon: "chart.bar.doc.horizontal",
                    color: .gray,
                    themeColors: theme
                )
            }
        }
        .padding()
        .background(theme.background)
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: theme.cardShadow, radius: theme.shadowRadius, y: 5)
    }

    // MARK: - Achievements
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L("stats.achievements"))
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Text(L("stats.hoverForInfo"))
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                Spacer()
                Text(LF("stats.unlockedCount", achievementManager.unlockedCount, achievementManager.achievements.count))
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(achievementManager.achievements) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        accentColor: accentColor,
                        themeColors: theme
                    )
                }
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: theme.cardShadow, radius: theme.shadowRadius, y: 5)
    }
}
