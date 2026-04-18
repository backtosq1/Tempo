import Foundation
import Combine

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    enum Language: String, CaseIterable {
        case english = "en"
        case simplifiedChinese = "zh-Hans"

        var displayName: String {
            switch self {
            case .english: return "English"
            case .simplifiedChinese: return "简体中文"
            }
        }
    }

    @Published private(set) var currentLanguage: Language

    private var bundle: Bundle = .main

    private init() {
        let stored = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        currentLanguage = Language(rawValue: stored) ?? .english
        bundle = Self.bundle(for: currentLanguage)
    }

    func setLanguage(_ language: Language) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
        bundle = Self.bundle(for: language)
        objectWillChange.send()
    }

    func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    private static func bundle(for language: Language) -> Bundle {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let b = Bundle(path: path) else {
            return .main
        }
        return b
    }
}

func L(_ key: String) -> String {
    LocalizationManager.shared.string(key)
}

func LF(_ key: String, _ args: CVarArg...) -> String {
    String(format: LocalizationManager.shared.string(key), arguments: args)
}
