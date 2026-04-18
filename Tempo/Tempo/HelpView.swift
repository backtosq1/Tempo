import SwiftUI

struct HelpView: View {
    @AppStorage(SettingsKeys.Appearance.themeColor.rawValue) private var themeColor: String = "red"
    @AppStorage(SettingsKeys.Appearance.appTheme.rawValue) private var appTheme: String = "default"
    @ObservedObject private var updateManager = UpdateManager.shared
    @ObservedObject private var locManager = LocalizationManager.shared

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

                    Text(L("help.tagline"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .padding(.bottom, 4)

                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: L("help.features"))

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        FeatureCard(icon: "timer", title: L("help.feature.timer.title"), description: L("help.feature.timer.desc"), accent: accentColor, theme: theme)
                        FeatureCard(icon: "rectangle.stack", title: L("help.feature.presets.title"), description: L("help.feature.presets.desc"), accent: accentColor, theme: theme)
                        FeatureCard(icon: "music.note", title: L("help.feature.zen.title"), description: L("help.feature.zen.desc"), accent: accentColor, theme: theme)
                        FeatureCard(icon: "checklist", title: L("help.feature.todo.title"), description: L("help.feature.todo.desc"), accent: accentColor, theme: theme)
                        FeatureCard(icon: "chart.bar", title: L("help.feature.stats.title"), description: L("help.feature.stats.desc"), accent: accentColor, theme: theme)
                        FeatureCard(icon: "brain", title: L("help.feature.ai.title"), description: L("help.feature.ai.desc"), accent: accentColor, theme: theme)
                        FeatureCard(icon: "trophy", title: L("help.feature.achievements.title"), description: L("help.feature.achievements.desc"), accent: accentColor, theme: theme)
                        FeatureCard(icon: "pip", title: L("help.feature.miniPlayer.title"), description: L("help.feature.miniPlayer.desc"), accent: accentColor, theme: theme)
                        FeatureCard(icon: "paintpalette", title: L("help.feature.themes.title"), description: L("help.feature.themes.desc"), accent: accentColor, theme: theme)
                    }
                }

                // Quick Start
                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: L("help.quickStart"))

                    VStack(alignment: .leading, spacing: 0) {
                        QuickStartRow(step: "1", text: L("help.step1"), isLast: false, accent: accentColor, theme: theme)
                        QuickStartRow(step: "2", text: L("help.step2"), isLast: false, accent: accentColor, theme: theme)
                        QuickStartRow(step: "3", text: L("help.step3"), isLast: false, accent: accentColor, theme: theme)
                        QuickStartRow(step: "4", text: L("help.step4"), isLast: true, accent: accentColor, theme: theme)
                    }
                    .padding(16)
                    .background(theme.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: theme.cardShadow, radius: theme.shadowRadius / 2, y: 2)
                }

                // Keyboard Shortcuts
                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: L("help.shortcuts"))

                    VStack(spacing: 0) {
                        ShortcutRow(keys: "Space", action: L("help.shortcut.space"))
                        Divider().padding(.horizontal, 12)
                        ShortcutRow(keys: "⌘ R", action: L("help.shortcut.cmdR"))
                        Divider().padding(.horizontal, 12)
                        ShortcutRow(keys: "⌘ S", action: L("help.shortcut.cmdS"))
                        Divider().padding(.horizontal, 12)
                        ShortcutRow(keys: "⌘ M", action: L("help.shortcut.cmdM"))
                    }
                    .padding(.vertical, 4)
                    .background(theme.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: theme.cardShadow, radius: theme.shadowRadius / 2, y: 2)
                }

                // AI & ML Features
                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: L("help.aiML"))

                    VStack(spacing: 0) {
                        AIFeatureRow(icon: "chart.line.uptrend.xyaxis", title: L("help.ai.peak.title"), description: L("help.ai.peak.desc"), accent: accentColor, theme: theme)
                        Divider().padding(.horizontal, 12)
                        AIFeatureRow(icon: "waveform.path.ecg", title: L("help.ai.quality.title"), description: L("help.ai.quality.desc"), accent: accentColor, theme: theme)
                        Divider().padding(.horizontal, 12)
                        AIFeatureRow(icon: "lightbulb.fill", title: L("help.ai.suggest.title"), description: L("help.ai.suggest.desc"), accent: accentColor, theme: theme)
                        Divider().padding(.horizontal, 12)
                        AIFeatureRow(icon: "lock.shield", title: L("help.ai.private.title"), description: L("help.ai.private.desc"), accent: accentColor, theme: theme)
                    }
                    .background(theme.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: theme.cardShadow, radius: theme.shadowRadius / 2, y: 2)
                }

                // Credits
                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: L("help.credits"))

                    VStack(alignment: .leading, spacing: 10) {
                        CreditRow(label: L("help.credit.zenMusic"), value: "\"Inner Peace\" by Grand_Project (Pixabay)")
                        CreditRow(label: L("help.credit.zenMusic"), value: "\"Zen Moods\" by djovan (Pixabay)")
                        CreditRow(label: L("help.credit.zenMusic"), value: "\"Zen Garden\" by Grand_Project (Pixabay)")
                        CreditRow(label: L("help.credit.appIcon"), value: "Created by Backtosq1")
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

private struct AIFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let accent: Color
    let theme: ThemeColors

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accent)
                .frame(width: 20)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
