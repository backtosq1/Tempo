import SwiftUI

struct OnboardingPageData {
    let symbol: String
    let titleKey: String
    let bodyKey: String
}

private let pages: [OnboardingPageData] = [
    OnboardingPageData(symbol: "timer", titleKey: "onb.p1.title", bodyKey: "onb.p1.body"),
    OnboardingPageData(symbol: "slider.horizontal.3", titleKey: "onb.p2.title", bodyKey: "onb.p2.body"),
    OnboardingPageData(symbol: "music.note", titleKey: "onb.p3.title", bodyKey: "onb.p3.body"),
    OnboardingPageData(symbol: "brain.head.profile", titleKey: "onb.p4.title", bodyKey: "onb.p4.body"),
    OnboardingPageData(symbol: "medal.fill", titleKey: "onb.p5.title", bodyKey: "onb.p5.body"),
]

struct OnboardingFeaturePage: View {
    let pageIndex: Int
    @ObservedObject private var locManager = LocalizationManager.shared

    private var data: OnboardingPageData {
        pages[pageIndex - 1]
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: data.symbol)
                .font(.system(size: 72, weight: .thin))
                .foregroundColor(.red)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 16) {
                Text(L(data.titleKey))
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text(L(data.bodyKey))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 48)
            }

            Spacer()
        }
    }
}
