import SwiftUI

struct LanguagePickerView: View {
    @ObservedObject private var locManager = LocalizationManager.shared
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "timer")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundColor(.red)
                Text("Tempo")
                    .font(.largeTitle.bold())
            }

            Text("Choose your language / 选择语言")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 14) {
                ForEach(LocalizationManager.Language.allCases, id: \.self) { lang in
                    LanguagePillButton(
                        language: lang,
                        isSelected: locManager.currentLanguage == lang,
                        onTap: { locManager.setLanguage(lang) }
                    )
                }
            }
            .padding(.horizontal, 60)

            Spacer()

            Button(locManager.currentLanguage == .simplifiedChinese ? "继续 →" : "Continue →") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 40)
        }
    }
}

private struct LanguagePillButton: View {
    let language: LocalizationManager.Language
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(language.displayName)
                    .font(.title3.weight(.medium))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.red : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isSelected ? Color.red.opacity(0.08) : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
