import SwiftUI
import UserNotifications

struct TimerView: View {
    @ObservedObject var timerManager: TimerManager
    @AppStorage(SettingsKeys.Appearance.themeColor.rawValue) private var themeColorValue = "red"
    @AppStorage(SettingsKeys.Timer.focusDuration.rawValue) private var focusDuration = 25
    @AppStorage(SettingsKeys.Timer.shortBreakDuration.rawValue) private var shortBreakDuration = 5
    @AppStorage(SettingsKeys.Timer.longBreakDuration.rawValue) private var longBreakDuration = 15
    @AppStorage(SettingsKeys.Behavior.enableZenMusic.rawValue) private var enableZenMusic = false
    @AppStorage(SettingsKeys.Appearance.appTheme.rawValue) private var appTheme = "default"
    @AppStorage(SettingsKeys.Appearance.animationStyle.rawValue) private var animationStyle = "smooth"
    
    @StateObject private var zenPlayer = ZenMusicPlayer.shared
    @ObservedObject private var locManager = LocalizationManager.shared
    
    @State private var pulsate = false
    @State private var glow = false
    @State private var showModeTransition = false
    @State private var timerPulse = false
    @State private var ringPulse = false
    @State private var showingSessionPicker = false
    
    private var settings: SettingsStore { SettingsStore.shared }
    
    private var accentColor: Color { themeColorValue.themeColor }
    private var theme: ThemeColors { ThemeManager.colors(for: appTheme, accent: accentColor) }

    private var localizedModeName: String {
        switch timerManager.mode {
        case .focus: return L("timer.mode.focus")
        case .shortBreak: return L("timer.mode.shortBreak")
        case .longBreak: return L("timer.mode.longBreak")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Session selector
            sessionSelector
                .padding(.top, 30)

            // Task selector
            taskSelector
                .padding(.top, 8)
            
            // Mode header with transition animation
            modeHeader
                .padding(.top, 20)
                .padding(.bottom, 30)
            
            // Timer circle with enhanced animations
            timerCircle
                .padding(.bottom, 40)
            
            // Control buttons with animations
            controlButtons
                .padding(.horizontal, 30)
            
            zenMusicControl
            
            Spacer()
            
            // Session counter
            sessionCounter
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            theme.background
                .ignoresSafeArea()
        )
        .onChange(of: timerManager.mode) { _, _ in
            playModeTransitionAnimation()
        }
        .onChange(of: timerManager.state) { _, newState in
            if newState == .running {
                startTimerAnimations()
            } else {
                stopTimerAnimations()
            }
        }
        // Update timer when settings change
        .onChange(of: focusDuration) { _, _ in
            timerManager.updateTimerDuration()
        }
        .onChange(of: shortBreakDuration) { _, _ in
            timerManager.updateTimerDuration()
        }
        .onChange(of: longBreakDuration) { _, _ in
            timerManager.updateTimerDuration()
        }
        .onAppear {
            requestNotificationPermission()
            if timerManager.state == .running {
                startTimerAnimations()
            }
        }
    }
    
    private var sessionSelector: some View {
        Menu {
            ForEach(timerManager.availableSessions) { session in
                Button(action: {
                    timerManager.setSession(session)
                }) {
                    HStack {
                        Circle()
                            .fill(session.colorHex.themeColor)
                            .frame(width: 10, height: 10)
                        Text(session.name)
                        if timerManager.currentSessionName == session.name {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
                Text(timerManager.currentSessionName.isEmpty ? L("timer.selectSession") : timerManager.currentSessionName)
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var activeTaskName: String? {
        guard let taskId = timerManager.activeTaskId else { return nil }
        return timerManager.todos.first(where: { $0.id == taskId })?.title
    }

    private var taskSelector: some View {
        Menu {
            Button(action: {
                timerManager.setActiveTask(nil)
            }) {
                HStack {
                    Text(L("timer.noTask"))
                    if timerManager.activeTaskId == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            ForEach(timerManager.todos.filter { !$0.isCompleted }) { todo in
                Button(action: {
                    timerManager.setActiveTask(todo.id)
                }) {
                    HStack {
                        Circle()
                            .fill(todo.priority.color)
                            .frame(width: 8, height: 8)
                        Text(todo.title)
                        if timerManager.activeTaskId == todo.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "checklist")
                    .font(.system(size: 10))
                if let name = activeTaskName {
                    Text(LF("timer.workingOn", name))
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                } else {
                    Text(L("timer.selectTask"))
                        .font(.system(size: 12, weight: .medium))
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var modeHeader: some View {
        VStack(spacing: 8) {
            Text(localizedModeName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accentColor.opacity(0.7))
                .tracking(1.5)
                .scaleEffect(showModeTransition ? 1.2 : 1)
                .opacity(showModeTransition ? 0 : 1)
                .animation(AnimationProvider.spring(for: animationStyle), value: showModeTransition)
            
            Text(timeString(from: timerManager.timeRemaining))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(theme.textPrimary)
                .scaleEffect(pulsate ? 1.05 : 1)
                .animation(
                    Animation.easeInOut(duration: 1)
                        .repeatForever(autoreverses: true)
                        .delay(0.2),
                    value: pulsate
                )
                .onAppear {
                    pulsate = timerManager.state == .running
                }
                .onChange(of: timerManager.state) { _, newState in
                    pulsate = newState == .running
                }
        }
    }
    
    private var timerCircle: some View {
        ZStack {
            // Outer glow effect when timer is running
            if timerManager.state == .running {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 320, height: 320)
                    .scaleEffect(timerPulse ? 1.05 : 1)
                    .opacity(timerPulse ? 1 : 0.7)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: timerPulse
                    )
            }
            
            // Background rings
            ForEach(0..<3) { i in
                Circle()
                    .stroke(
                        accentColor.opacity(0.1),
                        style: StrokeStyle(lineWidth: 2, dash: [2, 4])
                    )
                    .frame(width: 280 + CGFloat(i * 20), height: 280 + CGFloat(i * 20))
                    .opacity(0.3)
            }
            
            // Pulsing progress ring background
            Circle()
                .stroke(
                    accentColor.opacity(0.2),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .scaleEffect(ringPulse ? 1.02 : 1)
                .opacity(ringPulse ? 0.8 : 0.5)
                .animation(
                    Animation.easeInOut(duration: 1)
                        .repeatForever(autoreverses: true),
                    value: ringPulse
                )
            
            // Main progress ring
            Circle()
                .trim(from: 0, to: timerProgress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            accentColor,
                            accentColor.opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: accentColor.opacity(glow ? 0.5 : 0.2),
                    radius: (glow ? 20 : 10) * theme.glowIntensity,
                    x: 0,
                    y: 0
                )
                .animation(AnimationProvider.springSlow(for: animationStyle), value: timerProgress)
            
            // Animated dashes for running timer
            if timerManager.state == .running {
                Circle()
                    .trim(from: 0, to: 0.1)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                accentColor.opacity(0.8),
                                accentColor.opacity(0.4)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round, dash: [2, 8])
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90 + timerDashRotation))
                    .animation(
                        Animation.linear(duration: 2)
                            .repeatForever(autoreverses: false),
                        value: timerDashRotation
                    )
            }
            
            // Center content
            VStack(spacing: 12) {
                Text(L("timer.timeRemaining"))
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .tracking(1)

                Text(timeString(from: timerManager.timeRemaining))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(theme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5), value: timerManager.timeRemaining)
                    .scaleEffect(timerManager.state == .running ? 1.02 : 1)
                    .animation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                        value: timerManager.state == .running
                    )
            }
        }
        .onAppear { glow = true }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 20) {
            // Stop button
            ControlButton(
                title: L("timer.stop"),
                icon: "stop.fill",
                color: .gray,
                action: { timerManager.stop() },
                isDisabled: timerManager.state == .stopped
            )
            
            // Main control button
            ControlButton(
                title: timerManager.state == .running ? L("timer.pause") : L("timer.start"),
                icon: timerManager.state == .running ? "pause.fill" : "play.fill",
                color: timerManager.state == .running ? .orange : accentColor,
                action: {
                    withAnimation(.spring(response: 0.3)) {
                        if timerManager.state == .running {
                            timerManager.pause()
                        } else {
                            timerManager.start()
                        }
                    }
                }
            )
            .scaleEffect(timerManager.state == .running ? 1.05 : 1)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.5),
                value: timerManager.state
            )
            
            // Skip button
            ControlButton(
                title: L("timer.skip"),
                icon: "forward.fill",
                color: .green,
                action: { timerManager.skip() }
            )
        }
    }
    
    @ViewBuilder
    private var zenMusicControl: some View {
        if enableZenMusic {
            HStack(spacing: 12) {
                Button(action: {
                    zenPlayer.toggle()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: zenPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 18))

                        Text(zenPlayer.isPlaying ? zenPlayer.getCurrentStationName() : L("timer.playZenMusic"))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(zenPlayer.isPlaying ? accentColor : .secondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule()
                            .fill(zenPlayer.isPlaying ? accentColor.opacity(0.15) : Color.gray.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    zenPlayer.nextStation()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Circle().fill(Color.gray.opacity(0.1)))
                }
                .buttonStyle(PlainButtonStyle())
                .help(L("timer.nextTrack"))
            }
            .padding(.top, 16)
            .onChange(of: timerManager.mode) { _, newMode in
                if newMode == .focus && enableZenMusic && !zenPlayer.isPlaying {
                    zenPlayer.play()
                } else if newMode != .focus && zenPlayer.isPlaying {
                    zenPlayer.stop()
                }
            }
            .onChange(of: timerManager.state) { _, newState in
                if newState == .running && enableZenMusic && timerManager.mode == .focus && !zenPlayer.isPlaying {
                    zenPlayer.play()
                } else if newState == .stopped && zenPlayer.isPlaying {
                    zenPlayer.stop()
                }
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var sessionCounter: some View {
        HStack(spacing: 20) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(index < (timerManager.completedSessions % 4) ?
                          accentColor :
                          Color.gray.opacity(0.2))
                    .frame(width: 12, height: 12)
                    .scaleEffect(index == (timerManager.completedSessions % 4) ? 1.2 : 1)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.5),
                        value: timerManager.completedSessions
                    )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    // Helper for rotating dash animation
    private var timerDashRotation: Double {
        let progress = timerProgress
        return progress * 360
    }
    
    private var timerProgress: CGFloat {
        let totalTime: TimeInterval
        switch timerManager.mode {
        case .focus:
            totalTime = TimeInterval(focusDuration * 60)
        case .shortBreak:
            totalTime = TimeInterval(shortBreakDuration * 60)
        case .longBreak:
            totalTime = TimeInterval(longBreakDuration * 60)
        }
        return 1 - CGFloat(timerManager.timeRemaining / totalTime)
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func playModeTransitionAnimation() {
        showModeTransition = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5)) {
                showModeTransition = false
            }
        }
    }
    
    private func startTimerAnimations() {
        withAnimation(.easeInOut(duration: 0.5)) {
            timerPulse = true
            ringPulse = true
        }
    }
    
    private func stopTimerAnimations() {
        withAnimation(.easeInOut(duration: 0.5)) {
            timerPulse = false
            ringPulse = false
        }
    }
}
