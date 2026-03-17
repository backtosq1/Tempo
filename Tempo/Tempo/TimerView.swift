import SwiftUI
import UserNotifications

struct TimerView: View {
    @ObservedObject var timerManager: TimerManager
    @AppStorage("themeColor") private var themeColorValue = "red"
    @AppStorage("focusDuration") private var focusDuration = 25
    @AppStorage("shortBreakDuration") private var shortBreakDuration = 5
    @AppStorage("longBreakDuration") private var longBreakDuration = 15
    @AppStorage("enableZenMusic") private var enableZenMusic = false
    
    @StateObject private var zenPlayer = ZenMusicPlayer.shared
    
    @State private var pulsate = false
    @State private var glow = false
    @State private var showModeTransition = false
    @State private var timerPulse = false
    @State private var ringPulse = false
    @State private var showingSessionPicker = false
    
    private var settings: SettingsStore { SettingsStore.shared }
    
    // Convert theme color string to SwiftUI Color
    private var accentColor: Color {
        switch themeColorValue {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Session selector
            sessionSelector
                .padding(.top, 30)
            
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
            
            taskControls
            
            Spacer()
            
            // Session counter
            sessionCounter
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color(.windowBackgroundColor)
                .ignoresSafeArea()
        )
        .onChange(of: timerManager.mode) { _, _ in
            playModeTransitionAnimation()
            timerManager.refreshCurrentTask()
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
            timerManager.refreshCurrentTask()
            if timerManager.state == .running {
                startTimerAnimations()
            }
        }
    }
    
    private var sessionSelector: some View {
        let isTaskSession = settings.autoNameSessionFromTask && timerManager.currentTask != nil
        
        return Menu {
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
                Text(timerManager.currentSessionName.isEmpty ? "Select Session" : timerManager.currentSessionName)
                    .font(.system(size: 12, weight: .medium))
                if !isTaskSession {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .opacity(isTaskSession ? 0.6 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isTaskSession)
    }
    
    private var modeHeader: some View {
        VStack(spacing: 8) {
            Text(timerManager.mode.rawValue.uppercased())
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accentColor.opacity(0.7))
                .tracking(1.5)
                .scaleEffect(showModeTransition ? 1.2 : 1)
                .opacity(showModeTransition ? 0 : 1)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showModeTransition)
            
            Text(timeString(from: timerManager.timeRemaining))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.primary)
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
                    radius: glow ? 20 : 10,
                    x: 0,
                    y: 0
                )
                .animation(.spring(response: 1, dampingFraction: 0.6), value: timerProgress)
            
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
            VStack(spacing: 8) {
                if timerManager.mode == .focus {
                    if let task = timerManager.currentTask {
                        VStack(spacing: 6) {
                            Text(timeString(from: timerManager.timeRemaining))
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.primary)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.5), value: timerManager.timeRemaining)
                                .scaleEffect(timerManager.state == .running ? 1.02 : 1)
                                .animation(
                                    Animation.easeInOut(duration: 0.8)
                                        .repeatForever(autoreverses: true),
                                    value: timerManager.state == .running
                                )
                            
                            Text(task.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                            
                            Text(task.requiredTimeText)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(accentColor.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(accentColor.opacity(0.1))
                                .cornerRadius(4)
                        }
                        .frame(maxWidth: 200)
                    } else {
                        timeRemainingView
                    }
                } else {
                    Text("Time Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .tracking(1)
                    
                    Text(timeString(from: timerManager.timeRemaining))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.primary)
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
        }
        .onAppear { glow = true }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 20) {
            // Stop button
            ControlButton(
                title: "Stop",
                icon: "stop.fill",
                color: .gray,
                action: { timerManager.stop() },
                isDisabled: timerManager.state == .stopped
            )
            
            // Main control button
            ControlButton(
                title: timerManager.state == .running ? "Pause" : "Start",
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
                title: "Skip",
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
                        
                        Text(zenPlayer.isPlaying ? "Inner Peace" : "Play Zen Music")
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
    
    private var timeRemainingView: some View {
        VStack(spacing: 8) {
            Text("Time Remaining")
                .font(.caption)
                .foregroundColor(.secondary)
                .tracking(1)
            
            Text(timeString(from: timerManager.timeRemaining))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.primary)
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
    
    @ViewBuilder
    private var taskControls: some View {
        if timerManager.mode == .focus, timerManager.currentTask != nil {
            HStack(spacing: 12) {
                Button(action: {
                    timerManager.markCurrentTaskCompleted()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Complete Task")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 8)
        }
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
