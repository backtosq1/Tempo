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
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textPrimary)
                    Text("Customize Tempo")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.top, 20)

                // Timer Settings
                SettingsSection(title: "Timer Settings", icon: "timer", accentColor: accentColor, themeColors: theme) {
                    DurationSlider(
                        value: $focusDuration,
                        label: "Focus Duration",
                        icon: "brain.head.profile",
                        range: 5...60,
                        suffix: "min",
                        accentColor: accentColor
                    )

                    DurationSlider(
                        value: $shortBreakDuration,
                        label: "Short Break",
                        icon: "cup.and.saucer",
                        range: 1...15,
                        suffix: "min",
                        accentColor: accentColor
                    )

                    DurationSlider(
                        value: $longBreakDuration,
                        label: "Long Break",
                        icon: "bed.double.fill",
                        range: 5...30,
                        suffix: "min",
                        accentColor: accentColor
                    )
                }

                // Session Presets
                SettingsSection(title: "Session Presets", icon: "list.bullet", accentColor: accentColor, themeColors: theme) {
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
                            Text("Add Session")
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
                SettingsSection(title: "Behavior", icon: "arrow.triangle.2.circlepath", accentColor: accentColor, themeColors: theme) {
                    ToggleRow(
                        icon: "play.circle.fill",
                        label: "Auto-start breaks",
                        isOn: $autoStartBreaks,
                        accentColor: accentColor
                    )

                    ToggleRow(
                        icon: "pause.circle.fill",
                        label: "Auto-start focus sessions",
                        isOn: $autoStartFocus,
                        accentColor: accentColor
                    )
                }

                // Notifications & Sounds
                SettingsSection(title: "Notifications & Sounds", icon: "bell.badge.fill", accentColor: accentColor, themeColors: theme) {
                    ToggleRow(
                        icon: "bell.fill",
                        label: "Enable notifications",
                        isOn: $enableNotifications,
                        accentColor: accentColor
                    )

                    ToggleRow(
                        icon: "speaker.wave.2.fill",
                        label: "Enable sounds",
                        isOn: $enableSounds,
                        accentColor: accentColor
                    )

                    ToggleRow(
                        icon: "music.note",
                        label: "Enable zen music during focus",
                        isOn: $enableZenMusic,
                        accentColor: accentColor
                    )
                }

                // Theme
                SettingsSection(title: "Theme", icon: "sparkles", accentColor: accentColor, themeColors: theme) {
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
                                Text("This theme uses \(currentTheme.forcesDarkMode ? "dark" : "light") mode")
                                    .font(.caption)
                            }
                            .foregroundColor(theme.textSecondary)
                        }
                    }
                }

                // Appearance
                SettingsSection(title: "Appearance", icon: "paintbrush.fill", accentColor: accentColor, themeColors: theme) {
                    // Appearance mode picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Appearance Mode")
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
                        Text("Animation Style")
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
                        label: "Keep theme color when switching sessions",
                        isOn: $overrideThemeColor,
                        accentColor: accentColor
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Accent Color")
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

                // AI Insights
                SettingsSection(title: "AI Insights", icon: "brain.head.profile", accentColor: accentColor, themeColors: theme) {
                    ToggleRow(
                        icon: "sparkles",
                        label: "Enable AI Insights",
                        isOn: $enableInsights,
                        accentColor: accentColor
                    )

                    if enableInsights {
                        ToggleRow(
                            icon: "text.bubble",
                            label: "Post-session feedback prompt",
                            isOn: $enablePostSessionFeedback,
                            accentColor: accentColor
                        )

                        // Location picker
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .frame(width: 20)
                                Text("Current Location")
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
                                Text("Clear AI Data")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // Reset & About
                SettingsSection(title: "About", icon: "info.circle.fill", accentColor: accentColor, themeColors: theme) {
                    VStack(spacing: 16) {
                        Button(action: {
                            updateManager.checkForUpdates()
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(accentColor)
                                Text("Check for Updates")
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
                                Text("Reset All Data")
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
        .alert("Reset All Data?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will delete all your statistics and reset settings to defaults. This action cannot be undone.")
        }
        .alert("Check for Updates", isPresented: $showingUpdateAlert) {
            if updateManager.updateAvailable {
                Button("Update in App Store") {
                    updateManager.openAppStore()
                }
                Button("Later", role: .cancel) { }
            } else if updateManager.errorMessage != nil {
                Button("OK", role: .cancel) { }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: {
            if updateManager.updateAvailable {
                Text("Version \(updateManager.latestVersion) is available. You are currently using version \(updateManager.currentVersion).")
            } else if let error = updateManager.errorMessage {
                Text("Failed to check for updates: \(error)")
            } else {
                Text("You are using the latest version.")
            }
        }
        .confirmationDialog("Delete Session?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let id = sessionToDelete {
                    editableSessions.removeAll { $0.id == id }
                    sessionToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                sessionToDelete = nil
            }
        }
        .alert("Clear AI Data?", isPresented: $showingClearAIConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                InsightsEngine.shared.clearAllAIData()
            }
        } message: {
            Text("This will delete all cached insights and AI analysis data. Your session history will not be affected.")
        }
    }

    private func resetAllData() {
        timerManager.resetAllData()
        onResetSettings?()
    }
}
