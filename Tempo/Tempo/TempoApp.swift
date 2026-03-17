import SwiftUI
import AppKit

extension Notification.Name {
    static let openMiniPlayer = Notification.Name("openMiniPlayer")
}

@main
struct TempoApp: App {
    @StateObject private var timerManager = TimerManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerManager)
                .frame(minWidth: 650, minHeight: 700)
                .onAppear {
                    setupKeyMonitors()
                    setupNotificationObservers()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Timer") {
                Button("Stop") {
                    timerManager.stop()
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("Skip") {
                    timerManager.skip()
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Divider()
                
                Button("Mini Player") {
                    openMiniPlayer()
                }
                .keyboardShortcut("m", modifiers: .command)
            }
        }
    }
    
    private func setupKeyMonitors() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyEvent(event)
            return event
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        // Don't handle keys when a text field is focused
        if isTextFieldFocused() {
            return
        }
        
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        switch event.keyCode {
        case 49: // Space key
            if flags.isEmpty {
                DispatchQueue.main.async {
                    timerManager.togglePlayPause()
                }
            }
        default:
            break
        }
    }
    
    private func isTextFieldFocused() -> Bool {
        guard let window = NSApp.windows.first(where: { $0.isKeyWindow }) else {
            return false
        }
        let firstResponder = window.firstResponder
        if firstResponder is NSTextField || firstResponder is NSTextView {
            return true
        }
        if let fieldEditor = window.fieldEditor(false, for: nil), fieldEditor.isEditable {
            return true
        }
        return false
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .openMiniPlayer,
            object: nil,
            queue: .main
        ) { _ in
            self.openMiniPlayer()
        }
    }
    
    private func openMiniPlayer() {
        if let existingWindow = NSApp.windows.first(where: { $0.title == "Mini Player" }) {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 80),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        panel.title = "Mini Player"
        panel.contentView = NSHostingView(rootView: MiniPlayerView(timerManager: timerManager))
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
