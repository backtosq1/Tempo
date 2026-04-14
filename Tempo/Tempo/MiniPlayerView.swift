import SwiftUI

// MARK: - Mini Player View
/// Compact floating timer window that stays on top of other apps
struct MiniPlayerView: View {
    @ObservedObject var timerManager: TimerManager

    @State private var appear = false
    @State private var isHovered = false

    // MARK: - Computed Properties
    private var themeColor: String { SettingsStore.shared.themeColor }
    private var accentColor: Color { themeColor.themeColor }
    private var appThemeValue: String { SettingsStore.shared.appTheme }
    private var theme: ThemeColors { ThemeManager.colors(for: appThemeValue, accent: accentColor) }

    private var progress: CGFloat {
        let settings = SettingsStore.shared
        let totalTime: TimeInterval
        switch timerManager.mode {
        case .focus:
            totalTime = TimeInterval(settings.focusDuration * 60)
        case .shortBreak:
            totalTime = TimeInterval(settings.shortBreakDuration * 60)
        case .longBreak:
            totalTime = TimeInterval(settings.longBreakDuration * 60)
        }
        guard totalTime > 0 else { return 0 }
        return 1 - CGFloat(timerManager.timeRemaining / totalTime)
    }

    private var activeTask: TodoItem? {
        guard let taskId = timerManager.activeTaskId else { return nil }
        return timerManager.todos.first(where: { $0.id == taskId })
    }

    private var modeEmoji: String {
        switch timerManager.mode {
        case .focus: return "🎯"
        case .shortBreak: return "☕️"
        case .longBreak: return "🌟"
        }
    }

    private var incompleteTodos: [TodoItem] {
        timerManager.todos.filter { !$0.isCompleted }
    }

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private func dueDateColor(for date: Date) -> Color {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return .orange }
        if date < Date() { return .red }
        return .secondary
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top: task selector
            HStack(spacing: 3) {
                Text("📌")
                    .font(.system(size: 9))

                Menu {
                    Button(action: { timerManager.setActiveTask(nil) }) {
                        HStack {
                            Text("No Task")
                            if timerManager.activeTaskId == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    if !incompleteTodos.isEmpty {
                        Divider()

                        ForEach(incompleteTodos) { todo in
                            Button(action: { timerManager.setActiveTask(todo.id) }) {
                                HStack {
                                    Circle()
                                        .fill(todo.priority.color)
                                        .frame(width: 8, height: 8)
                                    Text(todo.title)
                                    if let due = todo.dueDate {
                                        Text("· \(Self.shortDateFormatter.string(from: due))")
                                            .foregroundColor(dueDateColor(for: due))
                                    }
                                    if timerManager.activeTaskId == todo.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if let task = activeTask {
                            Text(task.title)
                                .font(.system(size: 11))
                                .foregroundColor(theme.textPrimary)
                                .lineLimit(1)

                            if let due = task.dueDate {
                                Text(Self.shortDateFormatter.string(from: due))
                                    .font(.system(size: 9))
                                    .foregroundColor(dueDateColor(for: due))
                            }
                        } else {
                            Text("Select Task")
                                .font(.system(size: 11))
                                .foregroundColor(theme.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 4)

            // Bottom: mode + timer + controls
            HStack(spacing: 14) {
                // Left: mode label
                HStack(spacing: 4) {
                    Text(modeEmoji)
                        .font(.system(size: 9))
                    Text(timerManager.mode.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(accentColor)
                }
                .frame(maxWidth: 85, alignment: .leading)

                Spacer()

                // Center: timer
                Text(timeString(from: timerManager.timeRemaining))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(theme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.3), value: timerManager.timeRemaining)
                    .fixedSize()

                Spacer()

                // Right: controls
                HStack(spacing: 6) {
                    MiniButton(icon: "stop.fill", size: 10, color: theme.textSecondary) {
                        timerManager.stop()
                    }
                    .opacity(timerManager.state == .stopped ? 0.4 : 1)
                    .disabled(timerManager.state == .stopped)

                    MiniButton(
                        icon: timerManager.state == .running ? "pause.fill" : "play.fill",
                        size: 14,
                        color: accentColor
                    ) {
                        timerManager.togglePlayPause()
                    }

                    MiniButton(icon: "forward.fill", size: 10, color: theme.textSecondary) {
                        timerManager.skip()
                    }

                    Divider()
                        .frame(height: 16)
                        .padding(.horizontal, 2)

                    MiniButton(icon: "xmark", size: 9, color: theme.textSecondary.opacity(0.6)) {
                        closeWindow()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            // Progress bar — centered at bottom with padding
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(accentColor.opacity(0.12))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.8), accentColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(4, geo.size.width * progress))
                        .animation(.linear(duration: 0.5), value: progress)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(timerManager.state == .running ? 0.2 : 0), lineWidth: 1)
                .animation(.easeInOut(duration: 0.3), value: timerManager.state)
        )
        .scaleEffect(appear ? 1 : 0.95)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appear = true
            }
        }
        .background(DraggableView())
    }

    // MARK: - Helper Methods
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func closeWindow() {
        NSApp.windows.first { $0.title == "Mini Player" }?.close()
    }
}

// MARK: - Mini Button
private struct MiniButton: View {
    let icon: String
    let size: CGFloat
    let color: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
                .scaleEffect(isHovered ? 1.15 : 1)
        }
        .buttonStyle(.borderless)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Draggable View
/// Allows the mini player window to be dragged anywhere
struct DraggableView: NSViewRepresentable {
    func makeNSView(context: Context) -> DraggableNSView {
        DraggableNSView()
    }

    func updateNSView(_ nsView: DraggableNSView, context: Context) {}
}

class DraggableNSView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }
}
