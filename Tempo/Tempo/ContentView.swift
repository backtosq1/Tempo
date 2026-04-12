import SwiftUI

struct ContentView: View {
    @EnvironmentObject var timerManager: TimerManager
    @AppStorage(SettingsKeys.Appearance.appTheme.rawValue) private var appTheme = "default"
    @AppStorage(SettingsKeys.Appearance.themeColor.rawValue) private var themeColorValue = "red"

    @State private var selectedTab: Int = 0

    private var settings: SettingsStore {
        SettingsStore.shared
    }

    private var accentColor: Color { themeColorValue.themeColor }
    private var theme: ThemeColors { ThemeManager.colors(for: appTheme, accent: accentColor) }

    var body: some View {
        NavigationView {
            SidebarView(selectedTab: $selectedTab)
                .frame(minWidth: 180, idealWidth: 200, maxWidth: 220)

            mainContentView
        }
    }

    @ViewBuilder
    private var mainContentView: some View {
        GeometryReader { geometry in
            ZStack {
                theme.background
                    .ignoresSafeArea()

                Group {
                    switch selectedTab {
                    case 0:
                        TimerView(timerManager: timerManager)
                    case 1:
                        InsightsView(timerManager: timerManager)
                    case 2:
                        StatsView(timerManager: timerManager)
                    case 3:
                        SettingsView(timerManager: timerManager, onResetSettings: resetSettings)
                    case 4:
                        HelpView()
                    default:
                        TimerView(timerManager: timerManager)
                    }
                }
                .padding(.top, 1)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
            }
        }
    }

    private func resetSettings() {
        settings.focusDuration = 25
        settings.shortBreakDuration = 5
        settings.longBreakDuration = 15
        settings.autoStartBreaks = true
        settings.autoStartFocus = false
        settings.enableNotifications = true
        settings.enableSounds = true
        settings.themeColor = "red"
        settings.enableZenMusic = false
        settings.appTheme = "default"
        settings.appAppearance = "system"
    }
}

extension Notification.Name {
    static let timerDataReset = Notification.Name("timerDataReset")
}
