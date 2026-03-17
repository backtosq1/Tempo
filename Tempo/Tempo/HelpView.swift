import SwiftUI

struct HelpView: View {
    @AppStorage("themeColor") private var themeColor: String = "red"
    @ObservedObject private var updateManager = UpdateManager.shared
    
    private var accentColor: Color {
        switch themeColor {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        default: return .red
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Help & About")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("How to use Tempo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

            // How to Use
            HelpSection(title: "Getting Started", icon: "questionmark.circle.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        HelpItem(
                            number: "1",
                            title: "Start a Focus Session",
                            description: "Click the play button in the center of the timer, or press the Space bar on your keyboard. The default focus duration is 25 minutes."
                        )
                        
                        HelpItem(
                            number: "2",
                            title: "Work Until the Timer Ends",
                            description: "Focus on your task until the timer completes. Avoid distractions during this time for maximum productivity."
                        )
                        
                        HelpItem(
                            number: "3",
                            title: "Take a Break",
                            description: "When the focus session ends, you'll automatically transition to a short break (5 minutes). After completing 4 focus sessions, you'll get a long break (15 minutes)."
                        )
                        
                        HelpItem(
                            number: "4",
                            title: "Repeat the Cycle",
                            description: "Continue alternating between focus sessions and breaks. Each set of 4 focus sessions earns you a longer break."
                        )
                    }
                }
                
                // Customizing Tempo
                HelpSection(title: "Customizing Your Sessions", icon: "slider.horizontal.3") {
                    VStack(alignment: .leading, spacing: 16) {
                        HelpItem(
                            number: "1",
                            title: "Choose a Session Type",
                            description: "Click the session selector dropdown to choose between Focus (25 min), Deep Work (50 min), or Quick (15 min) sessions."
                        )
                        
                        HelpItem(
                            number: "2",
                            title: "Adjust Session Durations",
                            description: "In Settings, you can customize focus duration (5-60 min), short break (1-15 min), and long break (5-30 min)."
                        )
                        
                        HelpItem(
                            number: "3",
                            title: "Auto-Start Options",
                            description: "Enable 'Auto-start breaks' to automatically begin breaks after focus sessions. Enable 'Auto-start focus' to begin the next focus session after a break."
                        )
                        
                        HelpItem(
                            number: "4",
                            title: "Keep Your Theme Color",
                            description: "In Settings, enable 'Keep theme color when switching sessions' to prevent the color from changing when you select different session types."
                        )
                        HelpItem(
                            number: "5",
                            title: "Todo-list in the sidebar",
                            description: "Take full advantage of the convenient todo-list in the sidebar! Add todo items, double-click to edit todo items, and check the circle when you're done with them!"
                        )
                    }
                }
                
                // Zen Music
                HelpSection(title: "Zen Music", icon: "music.note") {
                    VStack(alignment: .leading, spacing: 16) {
                        HelpItem(
                            number: "1",
                            title: "Enable Zen Music",
                            description: "Go to Settings and toggle 'Enable zen music during focus' to turn on ambient music during your focus sessions."
                        )
                        
                        HelpItem(
                            number: "2",
                            title: "How It Works",
                            description: "When enabled, zen music will automatically start when you begin a focus session and stop when you take a break or stop the timer. Just remember not to accidentally play it at full blast ;)"
                        )
                        
                        HelpItem(
                            number: "3",
                            title: "Manual Control",
                            description: "You can also manually play/pause the music using the control that appears below the timer."
                        )
                    }
                }
                
                // Keyboard Shortcuts
                HelpSection(title: "Keyboard Shortcuts", icon: "keyboard.fill") {
                    VStack(spacing: 12) {
                        ShortcutRow(keys: "Space", action: "Start or pause the timer")
                        ShortcutRow(keys: "⌘+R", action: "Stop and reset the timer")
                        ShortcutRow(keys: "⌘+S", action: "Skip to the next session (focus/break)")
                        ShortcutRow(keys: "⌘+M", action: "Open the Mini Player window")
                    }
                }
                
                // Credits
                HelpSection(title: "Credits", icon: "heart.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Zen Music")
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text("The ambient music used in Tempo is \"Inner Peace\" by \"Grand_Project\" from Pixabay. Licensed under the Pixabay Content License - free for commercial use with no attribution required.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("App Icon")
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text("Created by Backtosq1.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Version")
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text("Tempo v\(updateManager.currentVersion) - A focus timer app for macOS. Designed for students.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal)
        }
        .background(Color(.windowBackgroundColor))
    }
}

struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    @AppStorage("themeColor") private var themeColor: String = "red"
    
    private var accentColor: Color {
        switch themeColor {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        default: return .red
        }
    }
    
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
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
}

struct HelpItem: View {
    @AppStorage("themeColor") private var themeColor: String = "red"
    
    private var accentColor: Color {
        switch themeColor {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        default: return .red
        }
    }
    
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

struct ShortcutRow: View {
    let keys: String
    let action: String
    
    var body: some View {
        HStack {
            Text(keys)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(6)
            
            Text(action)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            Spacer()
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
