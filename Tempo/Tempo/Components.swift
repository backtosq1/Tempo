import SwiftUI

// MARK: - Common UI Components

// MARK: - StatCard Component
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let animationDelay: Double
    var themeColors: ThemeColors = .default
    @State private var appear = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                        .fontWeight(.medium)

                    Text(value)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(themeColors.textPrimary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                }

                Spacer()

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .scaleEffect(appear ? 1 : 0.5)
                    .opacity(appear ? 1 : 0)
            }
            .padding(20)
        }
        .background(themeColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: themeColors.cardShadow, radius: themeColors.shadowRadius, y: 5)
        .scaleEffect(appear ? 1 : 0.8)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay)) {
                appear = true
            }
        }
    }
}

// MARK: - InsightCard Component
struct InsightCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    var themeColors: ThemeColors = .default
    var animationDelay: Double = 0

    @State private var appear = false

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeColors.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeColors.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .background(themeColors.cardBackground.opacity(0.5))
        .cornerRadius(12)
        .offset(x: appear ? 0 : -20)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay)) {
                appear = true
            }
        }
    }
}

// MARK: - ControlButton Component
struct ControlButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    var isDisabled: Bool = false
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
                action()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3)) {
                        isPressed = false
                    }
                }
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 80, height: 70)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: 8, y: 4)
            )
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    var accentColor: Color = .blue
    var themeColors: ThemeColors = .default
    var animationDelay: Double = 0
    let content: Content

    @State private var appear = false

    init(title: String, icon: String, accentColor: Color = .blue, themeColors: ThemeColors = .default, animationDelay: Double = 0, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.themeColors = themeColors
        self.animationDelay = animationDelay
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeColors.textPrimary)
                Spacer()
            }

            VStack(spacing: 20) {
                content
            }
            .padding(20)
            .background(themeColors.cardBackground)
            .cornerRadius(16)
            .shadow(color: themeColors.cardShadow, radius: themeColors.shadowRadius, y: 5)
        }
        .scaleEffect(appear ? 1 : 0.95)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay)) {
                appear = true
            }
        }
    }
}

struct DurationSlider: View {
    @Binding var value: Int
    let label: String
    let icon: String
    let range: ClosedRange<Int>
    let suffix: String
    var accentColor: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text("\(value) \(suffix)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(accentColor)
                    .monospacedDigit()
            }
            
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(accentColor)
        }
    }
}

struct ToggleRow: View {
    let icon: String
    let label: String
    @Binding var isOn: Bool
    var accentColor: Color = .blue
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(label)
                Spacer()
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: accentColor))
    }
}

struct ThemeColorButton: View {
    let color: Color
    let name: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(isSelected ? 1 : 0.5)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .shadow(color: color.opacity(isSelected ? 0.5 : 0.1), radius: isSelected ? 4 : 2)
                    .scaleEffect(isSelected ? 1.1 : (isHovered ? 1.05 : 1))

                Text(name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - ThemePreviewButton Component
struct ThemePreviewButton: View {
    let theme: AppTheme
    let accent: Color
    let isSelected: Bool
    let action: () -> Void

    @State private var appear = false
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.colors(accent: accent).background)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.colors(accent: accent).cardBackground)
                        .frame(width: 50, height: 28)
                        .shadow(color: theme.colors(accent: accent).cardShadow, radius: 2)

                    Circle()
                        .fill(accent)
                        .frame(width: 12, height: 12)
                        .offset(y: -8)

                    // Checkmark badge
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(accent)
                            .background(Circle().fill(Color.white).frame(width: 12, height: 12))
                            .offset(x: 30, y: -22)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? accent : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                )
                .scaleEffect(isSelected ? 1.05 : (isHovered ? 1.02 : 1))

                Text(theme.displayName)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? accent : .secondary)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(appear ? 1 : 0.9)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(theme.hashValue % 5) * 0.05)) {
                appear = true
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - AchievementCard Component
struct AchievementCard: View {
    let achievement: Achievement
    let accentColor: Color
    var themeColors: ThemeColors = .default

    @State private var appear = false
    @ObservedObject private var locManager = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? accentColor.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundColor(achievement.isUnlocked ? accentColor : .gray)
            }

            Text(L("achievement.\(achievement.id).title"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(achievement.isUnlocked ? themeColors.textPrimary : themeColors.textSecondary)
                .lineLimit(1)

            if achievement.isUnlocked, let date = achievement.unlockedDate {
                Text(date, style: .date)
                    .font(.system(size: 9))
                    .foregroundColor(themeColors.textSecondary)
            } else {
                ProgressView(value: Double(achievement.progress), total: Double(achievement.goal))
                    .tint(accentColor)
                    .frame(width: 60)
                Text("\(achievement.progress)/\(achievement.goal)")
                    .font(.system(size: 9))
                    .foregroundColor(themeColors.textSecondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(themeColors.cardBackground)
        .cornerRadius(12)
        .help(achievement.isUnlocked
            ? "\(L("achievement.\(achievement.id).desc"))\n\(L("stats.unlocked"))"
            : "\(L("achievement.\(achievement.id).desc")) (\(achievement.progress)/\(achievement.goal))"
        )
        .opacity(achievement.isUnlocked ? 1 : 0.6)
        .scaleEffect(appear ? 1 : 0.9)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05)) {
                appear = true
            }
        }
    }
}

// MARK: - SessionPresetRow Component
struct SessionPresetRow: View {
    @Binding var session: SessionType
    let isExpanded: Bool
    let isDefault: Bool
    let accentColor: Color
    var themeColors: ThemeColors = .default
    let onToggleExpand: () -> Void
    let onDelete: () -> Void
    @ObservedObject private var locManager = LocalizationManager.shared

    let accentColors: [(id: String, name: String, color: Color)] = [
        ("red", "Red", .red), ("blue", "Blue", .blue), ("green", "Green", .green),
        ("orange", "Orange", .orange), ("purple", "Purple", .purple), ("pink", "Pink", .pink),
        ("teal", "Teal", .teal), ("indigo", "Indigo", .indigo), ("yellow", "Yellow", .yellow),
        ("mint", "Mint", .mint), ("cyan", "Cyan", .cyan), ("brown", "Brown", .brown),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggleExpand) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(session.colorHex.themeColor)
                        .frame(width: 10, height: 10)

                    Text(session.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeColors.textPrimary)

                    Spacer()

                    Text("\(session.focusDuration)/\(session.shortBreakDuration)/\(session.longBreakDuration)")
                        .font(.system(size: 12))
                        .foregroundColor(themeColors.textSecondary)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(themeColors.textSecondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(spacing: 16) {
                    TextField(L("settings.sessionName"), text: $session.name)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)

                    DurationSlider(value: $session.focusDuration, label: L("settings.focus"), icon: "brain.head.profile", range: 5...120, suffix: L("common.min"), accentColor: accentColor)
                    DurationSlider(value: $session.shortBreakDuration, label: L("settings.shortBreak"), icon: "cup.and.saucer", range: 1...30, suffix: L("common.min"), accentColor: accentColor)
                    DurationSlider(value: $session.longBreakDuration, label: L("settings.longBreak"), icon: "bed.double.fill", range: 5...60, suffix: L("common.min"), accentColor: accentColor)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("settings.color"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeColors.textSecondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                            ForEach(accentColors, id: \.id) { id, _, color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .opacity(session.colorHex == id ? 1 : 0)
                                    )
                                    .onTapGesture { session.colorHex = id }
                            }
                        }
                    }

                    if !isDefault {
                        Button(action: onDelete) {
                            HStack {
                                Image(systemName: "trash")
                                Text(L("settings.deleteSession"))
                            }
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .padding(12)
        .background(themeColors.cardBackground.opacity(0.3))
        .cornerRadius(10)
    }
}
