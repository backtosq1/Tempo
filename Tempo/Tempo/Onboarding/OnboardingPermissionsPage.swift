import SwiftUI
import UserNotifications
import ApplicationServices

struct OnboardingPermissionsPage: View {
    @ObservedObject private var locManager = LocalizationManager.shared
    @State private var notificationsGranted = false
    @State private var accessibilityGranted = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 72, weight: .thin))
                .foregroundColor(.red)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 16) {
                Text(L("onb.perms.title"))
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text(L("onb.perms.body"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 48)
            }

            VStack(spacing: 12) {
                PermissionRow(
                    symbol: "bell.badge",
                    title: L("onb.perms.notif.title"),
                    detail: L("onb.perms.notif.detail"),
                    isGranted: notificationsGranted,
                    action: requestNotifications
                )
            }
            .padding(.horizontal, 48)

            Spacer()
        }
        .onAppear(perform: refreshStatuses)
    }

    private func refreshStatuses() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsGranted = settings.authorizationStatus == .authorized
            }
        }
        accessibilityGranted = AXIsProcessTrusted()
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                notificationsGranted = granted
            }
        }
    }
}

private struct PermissionRow: View {
    let symbol: String
    let title: String
    let detail: String
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundColor(.red)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
            } else {
                Button(L("onb.perms.allow")) { action() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }
}
