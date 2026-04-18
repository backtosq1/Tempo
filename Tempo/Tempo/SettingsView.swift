import SwiftUI

struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject private var updateManager = UpdateManager.shared
    var onResetSettings: (() -> Void)?

    @AppStorage(SettingsKeys.Timer.focusDuration.rawValue) private var focusDuration = 25
    @AppStorage(SettingsKeys.Timer.shortBreakDuration.rawValue) private var shortBreakDuration = 5
    @AppStorage(SettingsKeys.Timer.longBreakDuration.rawValue) private var longBreakDuration = 15

    @AppStorage(SettingsKeys.Timer.autoStartBreaks.rawValue) private var autoStartBreaks = true
    @AppStorage(SettingsKeys.Timer.autoStartFocus.rawValue) private var autoStartFocus = false
    @AppStorage(SettingsKeys.Behavior.enableNotifications.rawValue) private var enableNotifications = true
    @AppStorage(SettingsKeys.Behavior.enableSounds.rawValue) private var enableSounds = true
    @AppStorage(SettingsKeys.Behavior.enableZenMusic.rawValue) private var enableZenMusic = false

    @AppStorage(SettingsKeys.Appearance.themeColor.rawValue) private var themeColor = "red"
    @AppStorage(SettingsKeys.Appearance.overrideThemeColor.rawValue) private var overrideThemeColor = false
    @AppStorage(SettingsKeys.Appearance.appTheme.rawValue) private var appTheme = "default"
    @AppStorage(SettingsKeys.Appearance.appAppearance.rawValue) private var appAppearance = "system"
    @AppStorage(SettingsKeys.Appearance.animationStyle.rawValue) private var animationStyle = "smooth"

    @State private var showingResetConfirmation = false
    @State private var showingUpdateAlert = false
    @State private var expandedSessionId: UUID? = nil
    @State private var showingDeleteConfirmation = false
    @State private var sessionToDelete: UUID? = nil
    @State private var editableSessions: [SessionType] = []
    @State private var showingClearAIConfirmation = false
    @State private var selectedLocation: String?

    @AppStorage(SettingsKeys.Insights.enableInsights.rawValue) private var enableInsights = true
    @AppStorage(SettingsKeys.Insights.enablePostSessionFeedback.rawValue) private var enablePostSessionFeedback = false

    @ObservedObject private var locManager = LocalizationManager.shared

    private var accentColor: Color { themeColor.themeColor }
    private var theme: ThemeColors { ThemeManager.colors(for: appTheme, accent: accentColor) }

    private var currentTheme: AppTheme {
        AppTheme(rawValue: appTheme) ?? .default
    }

    let accentColors: [(id: String, name: String, color: Color)] = [
        ("red", "Red", .red),
        ("blue", "Blue", .blue),
        ("green", "Green", .green),
        ("orange", "Orange", .orange),
        ("purple", "Purple", .purple),
        ("pink", "Pink", .pink),
        ("teal", "Teal", .teal),
        ("indigo", "Indigo", .indigo),
        ("yellow", "Yellow", .yellow),
        ("mint", "Mint", .mint),
        ("cyan", "Cyan", .cyan),
        ("brown", "Brown", .brown),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("settings.title"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textPrimary)
                    Text(L("settings.subtitle"))
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.top, 20)

                // Timer Settings
                SettingsSection(title: L("settings.timerSettings"), icon: "timer", accentColor: accentColor, themeColors: theme) {
                    DurationSlider(
                        value: $focusDuration,
                        label: L("settings.focusDuration"),
                        icon: "brain.head.profile",
                        range: 5...60,
                        suffix: L("common.min"),
                        accentColor: accentColor
                    )

                    DurationSlider(
                        value: $shortBreakDuration,
                        label: L("settings.shortBreak"),
                        icon: "cup.and.saucer",
                        range: 1...15,
                        suffix: L("common.min"),
                        accentColor: accentColor
                    )

                    DurationSlider(
                        value: $longBreakDuration,
                        label: L("settings.longBreak"),
                        icon: "bed.double.fill",
                        range: 5...30,
                        suffix: L("common.min"),
                        accentColor: accentColor
                    )
                }

                // Session Presets
                SettingsSection(title: L("settings.sessionPresets"), icon: "list.bullet", accentColor: accentColor, themeColors: theme) {
                    ForEach($editableSessions) { $session in
                        SessionPresetRow(
                            session: $session,
                            isExpanded: expandedSessionId == session.id,
                            isDefault: SessionType.defaultSessions.contains(where: { $0.name == session.name }),
                            accentColor: accentColor,
                            themeColors: theme,
                            onToggleExpand: {
                                withAnimation(.spring(response: 0.3)) {
                                    expandedSessionId = expandedSessionId == session.id ? nil : session.id
                                }
                            },
                            onDelete: {
                                sessionToDelete = session.id
                                showingDeleteConfirmation = true
                            }
                        )
                    }

                    Button(action: {
                        let newSession = SessionType(
                            name: "Custom",
                            focusDuration: 25,
                            shortBreakDuration: 5,
                            longBreakDuration: 15,
                            colorHex: "orange"
                        )
                        editableSessions.append(newSession)
                        withAnimation(.spring(response: 0.3)) {
                            expandedSessionId = newSession.id
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(accentColor)
                            Text(L("settings.addSession"))
                                .foregroundColor(accentColor)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .onChange(of: editableSessions) {
                    timerManager.updateSessions(editableSessions)
                }

                // Behavior
                SettingsSection(title: L("settings.behavior"), icon: "arrow.triangle.2.circlepath", accentColor: accentColor, themeColors: theme) {
                    ToggleRow(
                        icon: "play.circle.fill",
                        label: L("settings.autoStartBreaks"),
                        isOn: $autoStartBreaks,
                        accentColor: accentColor
                    )

                    ToggleRow(
                        icon: "pause.circle.fill",
                        label: L("settings.autoStartFocus"),
                        isOn: $autoStartFocus,
                        accentColor: accentColor
                    )
                }

                // Notifications & Sounds
                SettingsSection(title: L("settings.notificationsAndSounds"), icon: "bell.badge.fill", accentColor: accentColor, themeColors: theme) {
                    ToggleRow(
                        icon: "bell.fill",
                        label: L("settings.enableNotifications"),
                        isOn: $enableNotifications,
                        accentColor: accentColor
                    )

                    ToggleRow(
                        icon: "speaker.wave.2.fill",
                        label: L("settings.enableSounds"),
                        isOn: $enableSounds,
                        accentColor: accentColor
                    )

                    ToggleRow(
                        icon: "music.note",
                        label: L("settings.enableZenMusic"),
                        isOn: $enableZenMusic,
                        accentColor: accentColor
                    )
                }

                // Theme
                SettingsSection(title: L("settings.theme"), icon: "sparkles", accentColor: accentColor, themeColors: theme) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            ForEach(AppTheme.allCases) { t in
                                ThemePreviewButton(
                                    theme: t,
                                    accent: accentColor,
                                    isSelected: appTheme == t.rawValue
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        appTheme = t.rawValue
                                    }
                                }
                            }
                        }

                        if currentTheme.locksAppearance {
                            HStack(spacing: 6) {
                                Image(systemName: currentTheme.forcesDarkMode ? "moon.fill" : "sun.max.fill")
                                    .font(.caption2)
                                Text(LF("settings.themeUses", currentTheme.forcesDarkMode ? L("settings.dark") : L("settings.light")))
                                    .font(.caption)
                            }
                            .foregroundColor(theme.textSecondary)
                        }
                    }
                }

                // Appearance
                SettingsSection(title: L("settings.appearance"), icon: "paintbrush.fill", accentColor: accentColor, themeColors: theme) {
                    // Appearance mode picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L("settings.appearanceMode"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textSecondary)

                        Picker("Appearance", selection: $appAppearance) {
                            ForEach(AppAppearance.allCases, id: \.rawValue) { mode in
                                Text(mode.displayName).tag(mode.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(currentTheme.locksAppearance)
                    }

                    // Animation style picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L("settings.animationStyle"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textSecondary)

                        Picker("Animation", selection: $animationStyle) {
                            ForEach(AnimationStyle.allCases, id: \.rawValue) { style in
                                Text(style.displayName).tag(style.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    ToggleRow(
                        icon: "lock.fill",
                        label: L("settings.keepThemeColor"),
                        isOn: $overrideThemeColor,
                        accentColor: accentColor
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text(L("settings.accentColor"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textSecondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 15) {
                            ForEach(accentColors, id: \.id) { id, name, color in
                                ThemeColorButton(
                                    color: color,
                                    name: name,
                                    isSelected: themeColor == id
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        themeColor = id
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }

                // Language
                SettingsSection(title: L("settings.language"), icon: "globe", accentColor: accentColor, themeColors: theme) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L("settings.appLanguage"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textSecondary)

                        HStack(spacing: 10) {
                            ForEach(LocalizationManager.Language.allCases, id: \.self) { lang in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        locManager.setLanguage(lang)
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Text(lang.displayName)
                                            .font(.system(size: 13, weight: locManager.currentLanguage == lang ? .semibold : .regular))
                                        if locManager.currentLanguage == lang {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(locManager.currentLanguage == lang ? accentColor.opacity(0.15) : Color.gray.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(locManager.currentLanguage == lang ? accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text(L("settings.languageNote"))
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }

                // AI Insights
                SettingsSection(title: L("settings.aiInsights"), icon: "brain.head.profile", accentColor: accentColor, themeColors: theme) {
                    ToggleRow(
                        icon: "sparkles",
                        label: L("settings.enableAIInsights"),
                        isOn: $enableInsights,
                        accentColor: accentColor
                    )

                    if enableInsights {
                        ToggleRow(
                            icon: "text.bubble",
                            label: L("settings.postSessionFeedback"),
                            isOn: $enablePostSessionFeedback,
                            accentColor: accentColor
                        )

                        // Location picker
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .frame(width: 20)
                                Text(L("settings.currentLocation"))
                                Spacer()
                            }
                            .font(.system(size: 14, weight: .medium))

                            HStack(spacing: 8) {
                                let locationTags = SettingsStore.shared.locationTags

                                ForEach(locationTags, id: \.self) { tag in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            if selectedLocation == tag {
                                                selectedLocation = nil
                                                SettingsStore.shared.currentLocation = nil
                                            } else {
                                                selectedLocation = tag
                                                SettingsStore.shared.currentLocation = tag
                                            }
                                        }
                                    }) {
                                        Text(tag)
                                            .font(.system(size: 12, weight: selectedLocation == tag ? .semibold : .regular))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(
                                                Capsule()
                                                    .fill(selectedLocation == tag ? accentColor.opacity(0.15) : Color.gray.opacity(0.1))
                                            )
                                            .overlay(
                                                Capsule()
                                                    .stroke(selectedLocation == tag ? accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        
                        // MARK: - Test Focus Data Button
                        /*
                        Button(action: {
                            timerManager.seedFocusTestData()
                            InsightsEngine.shared.refreshInsights(history: timerManager.getSessionHistory())
                        }) {
                            HStack {
                                Image(systemName: "flask.fill")
                                    .foregroundColor(accentColor)
                                Text("Generate Test Focus Data")
                                    .foregroundColor(accentColor)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        */
                        

                        Button(action: {
                            showingClearAIConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text(L("settings.clearAIData"))
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // Reset & About
                SettingsSection(title: L("settings.about"), icon: "info.circle.fill", accentColor: accentColor, themeColors: theme) {
                    VStack(spacing: 16) {
                        Button(action: {
                            updateManager.checkForUpdates()
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(accentColor)
                                Text(L("settings.checkForUpdates"))
                                    .foregroundColor(accentColor)
                                Spacer()
                                if updateManager.isChecking {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(accentColor.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(updateManager.isChecking)

                        Button(action: {
                            showingResetConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundColor(.red)
                                Text(L("settings.resetAllData"))
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tempo v\(updateManager.currentVersion)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }
                }

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal)
        }
        .background(theme.background)
        .onAppear {
            editableSessions = timerManager.availableSessions
            selectedLocation = SettingsStore.shared.currentLocation
        }
        .onChange(of: updateManager.isChecking) { _, newValue in
            if !newValue {
                showingUpdateAlert = true
            }
        }
        .alert(L("settings.resetAllDataTitle"), isPresented: $showingResetConfirmation) {
            Button(L("settings.cancel"), role: .cancel) { }
            Button(L("settings.reset"), role: .destructive) {
                resetAllData()
            }
        } message: {
            Text(L("settings.resetMessage"))
        }
        .alert(L("settings.checkForUpdatesTitle"), isPresented: $showingUpdateAlert) {
            if updateManager.updateAvailable {
                Button(L("settings.updateInAppStore")) {
                    updateManager.openAppStore()
                }
                Button(L("settings.later"), role: .cancel) { }
            } else if updateManager.errorMessage != nil {
                Button(L("settings.ok"), role: .cancel) { }
            } else {
                Button(L("settings.ok"), role: .cancel) { }
            }
        } message: {
            if updateManager.updateAvailable {
                Text(LF("settings.updateAvailable", updateManager.latestVersion, updateManager.currentVersion))
            } else if let error = updateManager.errorMessage {
                Text(LF("settings.updateFailed", error))
            } else {
                Text(L("settings.upToDate"))
            }
        }
        .confirmationDialog(L("settings.deleteSessionTitle"), isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button(L("sidebar.tasks.delete"), role: .destructive) {
                if let id = sessionToDelete {
                    editableSessions.removeAll { $0.id == id }
                    sessionToDelete = nil
                }
            }
            Button(L("settings.cancel"), role: .cancel) {
                sessionToDelete = nil
            }
        }
        .alert(L("settings.clearAIDataTitle"), isPresented: $showingClearAIConfirmation) {
            Button(L("settings.cancel"), role: .cancel) { }
            Button(L("sidebar.tasks.clear"), role: .destructive) {
                InsightsEngine.shared.clearAllAIData()
            }
        } message: {
            Text(L("settings.clearAIDataMessage"))
        }
    }

    private func resetAllData() {
        timerManager.resetAllData()
        onResetSettings?()
    }
}
