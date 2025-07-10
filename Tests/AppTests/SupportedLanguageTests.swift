import Foundation
@preconcurrency import Lingo
import Solver
import Testing

@testable import Verbose

@Suite final class SupportedLanguageTests {

    func createTestLingo() throws -> Lingo {
        try Lingo(dataSource: TestLocalizationDataSource(), defaultLocale: "en")
    }

    let testSolver = Solver(words: ["test", "example", "word"])

    @Test func initializationWithoutRegionCode() throws {
        let locale = Locale(identifier: "de")
        let lingo = try createTestLingo()

        let supportedLanguage = SupportedLanguage(locale: locale, solver: testSolver, lingo: lingo)

        #expect(supportedLanguage.locale == locale)
        #expect(supportedLanguage.identifier == "de")
        #expect(supportedLanguage.languageCode == "de")
        #expect(supportedLanguage.regionCode == nil)
        #expect(supportedLanguage.localisedName == "Deutsch")
        #expect(supportedLanguage.solver.totalWords == 3)
    }
    
    @Test func initializationWithRegionCode() throws {
        let locale = Locale(identifier: "en_NZ")
        let lingo = try createTestLingo()

        let supportedLanguage = SupportedLanguage(locale: locale, solver: testSolver, lingo: lingo)

        #expect(supportedLanguage.locale == locale)
        #expect(supportedLanguage.identifier == "en-NZ")
        #expect(supportedLanguage.languageCode == "en")
        #expect(supportedLanguage.regionCode == "NZ")
        #expect(supportedLanguage.localisedName == "English (New Zealand)")
        #expect(supportedLanguage.solver.totalWords == 3)
    }

    @Test func localizationWithEnglish() throws {
        let locale = Locale(identifier: "en_NZ")
        let lingo = try createTestLingo()

        let supportedLanguage = SupportedLanguage(locale: locale, solver: testSolver, lingo: lingo)

        #expect(supportedLanguage.localize("app.title") == "Test Verbose")
        #expect(
            supportedLanguage.localize("error.pattern", interpolations: ["pattern": "foo"])
                == "Test error for pattern: foo")
    }

    @Test func localizationWithGerman() throws {
        let locale = Locale(identifier: "de_DE")
        let lingo = try createTestLingo()

        let supportedLanguage = SupportedLanguage(locale: locale, solver: testSolver, lingo: lingo)

        #expect(supportedLanguage.localize("app.title") == "Test Verbose")
        #expect(
            supportedLanguage.localize("error.pattern", interpolations: ["pattern": "bar"])
                == "Test Fehler für Muster: bar")
    }
}
