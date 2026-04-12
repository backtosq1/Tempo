import SwiftUI

struct HelpView: View {
    @AppStorage(SettingsKeys.Appearance.themeColor.rawValue) private var themeColor: String = "red"
    @AppStorage(SettingsKeys.Appearance.appTheme.rawValue) private var appTheme: String = "default"
    @ObservedObject private var updateManager = UpdateManager.shared

    private var accentColor: Color { themeColor.themeColor }
    private var theme: ThemeColors { ThemeManager.colors(for: appTheme, accent: accentColor) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero Header
                VStack(spacing: 12) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .cornerRadius(14)
                        .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)

                    Text("Tempo")
                        .font(.system(size: 28, weight: .bold, design: .rounded))

                    Text("v\(updateManager.currentVersion)")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)

                    Text("A focus timer designed for students")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .padding(.bottom, 4)

                // Features Grid
                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: "Features")

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        FeatureCard(
                            icon: "timer",
                            title: "Focus Timer",
                            description: "Pomodoro sessions with focus, short break, and long break cycles",
                            accent: accentColor,
                            theme: theme
                        )
                        FeatureCard(
                            icon: "rectangle.stack",
                            title: "Session Presets",
                            description: "Focus (25m), Deep Work (50m), Quick (15m), or create your own",
                            accent: accentColor,
                            theme: theme
                        )
                        FeatureCard(
                            icon: "music.note",
                            title: "Zen Music",
                            description: "Ambient music that auto-plays during focus and pauses on breaks",
                            accent: accentColor,
                            theme: theme
                        )
                        FeatureCard(
                            icon: "checklist",
                            title: "Todo List",
                            description: "Manage tasks with priorities, link them to sessions, and track progress",
                            accent: accentColor,
                            theme: theme
                        )
                        FeatureCard(
                            icon: "chart.bar",
                            title: "Statistics",
                            description: "Daily, weekly, and monthly insights with streaks and session history",
                            accent: accentColor,
                            theme: theme
                        )
                        FeatureCard(
                            icon: "trophy",
                            title: "Achievements",
                            description: "12 unlockable milestones like Early Bird, Streak Master, and more",
                            accent: accentColor,
                            theme: theme
                        )
                        FeatureCard(
                            icon: "pip",
                            title: "Mini Player",
                            description: "Compact floating timer that stays on top across all spaces",
                            accent: accentColor,
                            theme: theme
                        )
                        FeatureCard(
                            icon: "paintpalette",
                            title: "Themes & Colors",
                            description: "5 app themes, 12 accent colors, and 3 animation styles",
                            accent: accentColor,
                            theme: theme
                        )
                    }
                }

                // Quick Start
                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: "Quick Start")

                    VStack(alignment: .leading, spacing: 0) {
                        QuickStartRow(step: "1", text: "Press Space to start a focus session", isLast: false, accent: accentColor, theme: theme)
                        QuickStartRow(step: "2", text: "Work until the timer ends — a break starts automatically", isLast: false, accent: accentColor, theme: theme)
                        QuickStartRow(step: "3", text: "Every 4 sessions, enjoy a longer break", isLast: false, accent: accentColor, theme: theme)
                        QuickStartRow(step: "4", text: "Track your progress in Statistics and unlock Achievements", isLast: true, accent: accentColor, theme: theme)
                    }
                    .padding(16)
                    .background(theme.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: theme.cardShadow, radius: theme.shadowRadius / 2, y: 2)
                }

                // Keyboard Shortcuts
                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: "Keyboard Shortcuts")

                    VStack(spacing: 0) {
                        ShortcutRow(keys: "Space", action: "Start / Pause timer")
                        Divider().padding(.horizontal, 12)
                        ShortcutRow(keys: "⌘ R", action: "Stop and reset")
                        Divider().padding(.horizontal, 12)
                        ShortcutRow(keys: "⌘ S", action: "Skip to next session")
                        Divider().padding(.horizontal, 12)
                        ShortcutRow(keys: "⌘ M", action: "Open Mini Player")
                    }
                    .padding(.vertical, 4)
                    .background(theme.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: theme.cardShadow, radius: theme.shadowRadius / 2, y: 2)
                }

                // Credits
                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: "Credits")

                    VStack(alignment: .leading, spacing: 10) {
                        CreditRow(label: "Zen Music", value: "\"Inner Peace\" by Grand_Project (Pixabay)")
                        CreditRow(label: "Zen Music", value: "\"Zen Moods\" by djovan (Pixabay)")
                        CreditRow(label: "Zen Music", value: "\"Zen Garden\" by Grand_Project (Pixabay)")
                        CreditRow(label: "App Icon", value: "Created by Backtosq1")
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: theme.cardShadow, radius: theme.shadowRadius / 2, y: 2)
                }

                Spacer().frame(height: 30)
            }
            .padding(.horizontal)
        }
        .background(theme.background)
    }
}

// MARK: - Components

private struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.secondary)
            .tracking(0.8)
    }
}

private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let accent: Color
    let theme: ThemeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(accent)

            Text(title)
                .font(.system(size: 14, weight: .semibold))

            Text(description)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: theme.cardShadow, radius: theme.shadowRadius / 2, y: 2)
    }
}

private struct QuickStartRow: View {
    let step: String
    let text: String
    let isLast: Bool
    let accent: Color
    let theme: ThemeColors

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Text(step)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(accent)
                    .clipShape(Circle())

                if !isLast {
                    Rectangle()
                        .fill(accent.opacity(0.2))
                        .frame(width: 2)
                        .padding(.vertical, 2)
                }
            }

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .padding(.top, 2)
                .padding(.bottom, isLast ? 0 : 12)

            Spacer()
        }
    }
}

private struct CreditRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

struct ShortcutRow: View {
    let keys: String
    let action: String

    var body: some View {
        HStack {
            Text(keys)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.gray.opacity(0.12))
                .cornerRadius(6)

            Spacer()

            Text(action)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    @AppStorage(SettingsKeys.Appearance.themeColor.rawValue) private var themeColor: String = "red"
    @AppStorage(SettingsKeys.Appearance.appTheme.rawValue) private var appTheme: String = "default"

    private var accentColor: Color { themeColor.themeColor }
    private var theme: ThemeColors { ThemeManager.colors(for: appTheme, accent: accentColor) }

    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accentColor)

                Text(title)
                    .font(.headline)
            }

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: theme.cardShadow, radius: theme.shadowRadius / 2, y: 2)
    }
}

struct HelpItem: View {
    @AppStorage(SettingsKeys.Appearance.themeColor.rawValue) private var themeColor: String = "red"

    private var accentColor: Color { themeColor.themeColor }

    let number: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(accentColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct TipItem: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 14))

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
