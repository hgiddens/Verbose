import Foundation
@preconcurrency import Lingo

struct TestLocalizationDataSource: LocalizationDataSource {
    let testData: [String: [String: String]] = [
        "en": [
            "app.title": "Test Verbose",
            "app.subtitle": "Test subtitle for English",
            "entry.title": "Test entry title",
            "error.pattern": "Test error for pattern: %{pattern}",
            "language.combined": "%{language} (%{region})",
        ],
        "de": [
            "app.title": "Test Verbose",
            "app.subtitle": "Test Untertitel auf Deutsch",
            "entry.title": "Lösen wir mal ein Wort!",
            "error.pattern": "Test Fehler für Muster: %{pattern}",
            "language.combined": "%{language} (%{region})",
        ],
    ]

    func availableLocales() throws -> [LocaleIdentifier] { Array(testData.keys) }

    func localizations(forLocale locale: LocaleIdentifier) throws -> [LocalizationKey: Localization]
    {
        testData[locale]!.mapValues { value in
            Localization.universal(value: value)
        }
    }
}
