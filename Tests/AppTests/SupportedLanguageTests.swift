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

    @Test func testValidInitialization() throws {
        let locale = Locale(identifier: "en_NZ")
        let lingo = try createTestLingo()

        let supportedLanguage = SupportedLanguage(locale: locale, solver: testSolver, lingo: lingo)

        #expect(supportedLanguage.locale.identifier == "en_NZ")
        #expect(supportedLanguage.solver.totalWords == 3)
        #expect(supportedLanguage.languageCode == "en")
    }

    @Test func testLocalizationWithEnglish() throws {
        let locale = Locale(identifier: "en_NZ")
        let lingo = try createTestLingo()

        let supportedLanguage = SupportedLanguage(locale: locale, solver: testSolver, lingo: lingo)

        #expect(supportedLanguage.localize("app.title") == "Test Verbose")
        #expect(
            supportedLanguage.localize("error.pattern", interpolations: ["pattern": "foo"])
                == "Test error for pattern: foo")
    }

    @Test func testLocalizationWithGerman() throws {
        let locale = Locale(identifier: "de_DE")
        let lingo = try createTestLingo()

        let supportedLanguage = SupportedLanguage(locale: locale, solver: testSolver, lingo: lingo)

        #expect(supportedLanguage.localize("app.title") == "Test Verbose")
        #expect(
            supportedLanguage.localize("error.pattern", interpolations: ["pattern": "bar"])
                == "Test Fehler für Muster: bar")
    }
}
