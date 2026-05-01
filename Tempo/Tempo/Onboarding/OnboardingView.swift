import SwiftUI

struct OnboardingView: View {
    @AppStorage(SettingsKeys.Onboarding.hasCompletedOnboarding.rawValue) private var hasCompletedOnboarding = false
    @ObservedObject private var locManager = LocalizationManager.shared
    @State private var currentPage = 0

    private let totalFeaturePages = 6

    var body: some View {
        ZStack {
            Color(.windowBackgroundColor).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if currentPage > 0 {
                        Button(L("onb.nav.skip")) { finish() }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .frame(height: 44)

                Group {
                    if currentPage == 0 {
                        LanguagePickerView(onContinue: { withAnimation { currentPage = 1 } })
                    } else if currentPage == totalFeaturePages {
                        OnboardingPermissionsPage()
                    } else {
                        OnboardingFeaturePage(pageIndex: currentPage)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(currentPage)

                if currentPage > 0 {
                    VStack(spacing: 20) {
                        OnboardingDotIndicator(totalPages: totalFeaturePages, currentPage: currentPage - 1)

                        HStack(spacing: 16) {
                            if currentPage > 1 {
                                Button(L("onb.nav.back")) { withAnimation { currentPage -= 1 } }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if currentPage < totalFeaturePages {
                                Button(L("onb.nav.next")) { withAnimation { currentPage += 1 } }
                                    .buttonStyle(.borderedProminent)
                            } else {
                                Button(L("onb.nav.finish")) { finish() }
                                    .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .frame(minWidth: 560, minHeight: 640)
    }

    private func finish() {
        hasCompletedOnboarding = true
    }
}

struct OnboardingDotIndicator: View {
    let totalPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage ? Color.red : Color.secondary.opacity(0.3))
                    .frame(width: i == currentPage ? 20 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}
