//  Tempo - AI Insights View
//  Displays personalized productivity insights and smart suggestions

import SwiftUI

struct InsightsView: View {
    @ObservedObject var timerManager: TimerManager
    @StateObject private var insightsEngine = InsightsEngine.shared

    @State private var selectedInsight: Insight?
    @State private var showPrivacyNotice = false
    @State private var appear = false

    private var themeColor: String { SettingsStore.shared.themeColor }
    private var accentColor: Color { themeColor.themeColor }
    private var appThemeValue: String { SettingsStore.shared.appTheme }
    private var theme: ThemeColors { ThemeManager.colors(for: appThemeValue, accent: accentColor) }
    private var settings: SettingsStore { SettingsStore.shared }

    private var hasEnoughData: Bool {
        let history = timerManager.getSessionHistory()
        let completedSessions = history.filter(\.completed)

        // Need at least 10 completed sessions AND data spanning at least 7 days
        guard completedSessions.count >= 10 else { return false }

        let calendar = Calendar.current
        let uniqueDays = Set(completedSessions.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count >= 7
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                if !hasEnoughData {
                    // Locked state - not enough data
                    lockedState
                } else {
                    // Smart Suggestion Banner
                    if let suggestion = insightsEngine.smartSuggestion {
                        smartSuggestionBanner(suggestion)
                    }

                    // Productivity Score Card
                    if !insightsEngine.currentInsights.isEmpty {
                        productivityScoreCard
                    }

                    // Insights Grid
                    if insightsEngine.currentInsights.isEmpty {
                        emptyState
                    } else {
                        insightsGrid
                    }

                    // Focus Quality Summary
                    focusQualitySummary
                }

                Spacer().frame(height: 40)
            }
            .padding(.horizontal)
        }
        .background(theme.background)
        .onAppear {
            if !settings.hasSeenAIPrivacyNotice && settings.enableInsights {
                showPrivacyNotice = true
            }
            if hasEnoughData {
                insightsEngine.refreshInsights(history: timerManager.getSessionHistory())
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appear = true
            }
        }
        .sheet(isPresented: $showPrivacyNotice) {
            aiPrivacyNotice
        }
        .sheet(item: $selectedInsight) { insight in
            insightDetailView(insight)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Insights")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textPrimary)
                    Text("Personalized productivity recommendations")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                Spacer()
                Button(action: {
                    insightsEngine.refreshInsights(history: timerManager.getSessionHistory())
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Smart Suggestion Banner

    private func smartSuggestionBanner(_ suggestion: SmartSuggestion) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                Text(suggestion.message)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            Button(action: {
                settings.focusDuration = suggestion.recommendedDuration
                timerManager.updateTimerDuration()
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
                        colors: [accentColor.opacity(0.15), accentColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(appear ? 1 : 0.95)
        .opacity(appear ? 1 : 0)
    }

    // MARK: - Productivity Score

    private var productivityScoreCard: some View {
        let history = timerManager.getSessionHistory()
        let patterns = ProductivityPatternModel.analyze(from: history)
        let scorePercent = Int(patterns.productivityScore * 100)

        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Productivity Score")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                    Text("Based on completion rate, consistency, and focus quality")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(theme.cardShadow, lineWidth: 6)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: CGFloat(patterns.productivityScore))
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    Text("\(scorePercent)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                }
            }
        }
        .padding(20)
        .background(theme.cardBackground)
        .cornerRadius(16)
        .shadow(color: theme.cardShadow, radius: theme.shadowRadius, y: 5)
    }

    // MARK: - Insights Grid

    private var insightsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(insightsEngine.currentInsights) { insight in
                insightCard(insight)
                    .onTapGesture { selectedInsight = insight }
            }
        }
    }

    private func insightCard(_ insight: Insight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.type.icon)
                    .font(.title2)
                    .foregroundColor(insight.type.color)
                Spacer()
                if insight.priority >= 4 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
            }

            Text(insight.title)
                .font(.headline)
                .foregroundColor(theme.textPrimary)
                .lineLimit(2)

            Text(insight.message)
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .lineLimit(3)

            if insight.actionable {
                Label("Action recommended", systemImage: "hand.tap.fill")
                    .font(.caption)
                    .foregroundColor(accentColor)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 170)
        .background(theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: theme.cardShadow, radius: theme.shadowRadius, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(insight.type.color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Focus Quality Summary

    private var focusQualitySummary: some View {
        let history = timerManager.getSessionHistory()
        let recentCompleted = history.suffix(20).filter(\.completed)
        let scores = recentCompleted.compactMap(\.focusQualityScore)

        return Group {
            if scores.count >= 3 {
                let avg = scores.reduce(0, +) / Double(scores.count)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Focus Quality")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)

                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text(String(format: "%.0f%%", avg * 100))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(accentColor)
                            Text("Avg Quality")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }

                        VStack(spacing: 4) {
                            Text(FocusQualityModel.ratingLabel(for: avg))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(theme.textPrimary)
                            Text("Rating")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }

                        Spacer()

                        VStack(spacing: 4) {
                            let avgInterruptions = Double(recentCompleted.reduce(0) { $0 + $1.interruptionCount }) / Double(max(1, recentCompleted.count))
                            Text(String(format: "%.1f", avgInterruptions))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(avgInterruptions > 3 ? .red : .green)
                            Text("Avg Pauses")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
                .padding(20)
                .background(theme.cardBackground)
                .cornerRadius(16)
                .shadow(color: theme.cardShadow, radius: theme.shadowRadius, y: 5)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(theme.textSecondary.opacity(0.5))
            Text("Not Enough Data Yet")
                .font(.title3.bold())
                .foregroundColor(theme.textPrimary)
            Text("Complete at least 10 focus sessions to unlock AI insights.")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }

    // MARK: - Locked State

    private var lockedState: some View {
        let history = timerManager.getSessionHistory()
        let completedCount = history.filter(\.completed).count
        let calendar = Calendar.current
        let uniqueDays = Set(history.filter(\.completed).map { calendar.startOfDay(for: $0.date) })
        let daysCount = uniqueDays.count

        return VStack(spacing: 20) {
            // Lock icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                Circle()
                    .stroke(accentColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 100, height: 100)
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(accentColor)
            }
            .padding(.top, 40)

            VStack(spacing: 8) {
                Text("AI Insights Locked")
                    .font(.title2.bold())
                    .foregroundColor(theme.textPrimary)
                Text("Build up your focus history to unlock personalized insights")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Progress indicators
            VStack(spacing: 16) {
                // Sessions requirement
                progressRow(
                    icon: "checkmark.circle.fill",
                    title: "Completed Sessions",
                    current: completedCount,
                    required: 10,
                    suffix: "sessions"
                )

                // Days requirement
                progressRow(
                    icon: "calendar",
                    title: "Active Days",
                    current: daysCount,
                    required: 7,
                    suffix: "days"
                )
            }
            .padding(.horizontal, 60)
            .padding(.top, 20)

            Spacer()
        }
        .padding(.vertical, 40)
        .opacity(appear ? 1 : 0)
        .scaleEffect(appear ? 1 : 0.95)
    }

    private func progressRow(icon: String, title: String, current: Int, required: Int, suffix: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(current >= required ? .green : theme.textSecondary)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Text("\(current)/\(required)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(current >= required ? .green : accentColor)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.cardShadow)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(current >= required ? Color.green : accentColor)
                        .frame(width: geo.size.width * min(1.0, CGFloat(current) / CGFloat(required)), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: theme.cardShadow, radius: theme.shadowRadius, y: 3)
    }

    // MARK: - Insight Detail Sheet

    private func insightDetailView(_ insight: Insight) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: insight.type.icon)
                    .font(.title)
                    .foregroundColor(insight.type.color)
                Text(insight.title)
                    .font(.title2.bold())
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Button("Done") { selectedInsight = nil }
                    .buttonStyle(.plain)
                    .foregroundColor(accentColor)
            }

            Text(insight.message)
                .font(.body)
                .foregroundColor(theme.textPrimary)

            if insight.actionable {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("What You Can Do")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                    Text(insight.type.actionSuggestion)
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 450, height: 300)
        .background(theme.background)
    }

    // MARK: - Privacy Notice

    private var aiPrivacyNotice: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Insights Privacy")
                .font(.title.bold())
                .foregroundColor(theme.textPrimary)

            Text("Tempo's AI insights are powered by on-device analysis. Here's what you should know:")
                .foregroundColor(theme.textSecondary)

            VStack(alignment: .leading, spacing: 15) {
                privacyPoint(icon: "lock.shield", title: "100% Private", description: "All analysis happens on your Mac. No data is sent to any server.")
                privacyPoint(icon: "brain", title: "Learning From You", description: "AI learns your patterns to provide personalized recommendations.")
                privacyPoint(icon: "hand.raised", title: "You're In Control", description: "Opt out anytime and delete all AI data from Settings.")
            }

            Spacer()

            Button(action: {
                settings.hasSeenAIPrivacyNotice = true
                showPrivacyNotice = false
            }) {
                Text("I Understand")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(width: 450, height: 380)
        .background(theme.background)
    }

    private func privacyPoint(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(accentColor)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
}

// Make Insight conform to Identifiable for sheet binding (it already does)
// but we need Hashable for item-based sheet
extension Insight: Hashable {
    static func == (lhs: Insight, rhs: Insight) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
