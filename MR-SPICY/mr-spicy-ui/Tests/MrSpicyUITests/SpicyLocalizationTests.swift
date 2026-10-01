//
//  SpicyLocalizationTests.swift
//  MR. SPICY UI v1.0.0
//
//  STATUS: NOT EXECUTED in the authoring environment — no Swift/iOS toolchain
//  was available. The equivalent key-parity, format-specifier and
//  untranslated-value checks ARE executed by
//  validation/tools/validate_localization.py, which passes.
//

#if canImport(UIKit)
import XCTest
@testable import MrSpicyUI

final class SpicyLocalizationTests: XCTestCase {

    private var l10n: SpicyL10n!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "MrSpicyUITests")!
        defaults.removePersistentDomain(forName: "MrSpicyUITests")
        l10n = SpicyL10n(defaults: defaults)
    }

    func testEveryDeclaredKeyResolvesInEnglish() {
        l10n.setLanguage(.english)
        for key in SpicyStringKey.allCases {
            let value = l10n.string(key)
            XCTAssertFalse(value.isEmpty, "empty value for \(key.rawValue)")
            XCTAssertFalse(value.hasPrefix("⟦"), "missing English string for \(key.rawValue)")
        }
    }

    func testEveryDeclaredKeyResolvesInArabic() {
        var missing: [String] = []
        l10n.missingKeyHandler = { key, _ in missing.append(key) }
        l10n.setLanguage(.arabic)
        for key in SpicyStringKey.allCases {
            _ = l10n.string(key)
        }
        XCTAssertTrue(missing.isEmpty, "missing Arabic strings: \(missing)")
    }

    func testFallsBackToEnglishAndReportsMissingKey() {
        var reported: [String] = []
        l10n.missingKeyHandler = { key, _ in reported.append(key) }
        l10n.setLanguage(.arabic)
        _ = l10n.string("spicy.key.that.does.not.exist")
        XCTAssertEqual(reported, ["spicy.key.that.does.not.exist"])
    }

    func testLanguageChangePostsNotification() {
        l10n.setLanguage(.english)
        let expectation = expectation(
            forNotification: SpicyL10n.languageDidChangeNotification,
            object: l10n, handler: nil)
        l10n.setLanguage(.arabic)
        wait(for: [expectation], timeout: 1)
    }

    func testArabicIsRightToLeft() {
        XCTAssertTrue(SpicyLanguage.arabic.isRightToLeft)
        XCTAssertEqual(SpicyLanguage.arabic.layoutDirection, .rightToLeft)
        XCTAssertFalse(SpicyLanguage.english.isRightToLeft)
    }

    func testSelectionPersists() {
        l10n.setLanguage(.arabic)
        let reloaded = SpicyL10n(defaults: defaults)
        XCTAssertEqual(reloaded.current, .arabic)
    }

    func testNumbersUseActiveLocale() {
        l10n.setLanguage(.english)
        XCTAssertEqual(l10n.number(1234), "1,234")
        l10n.setLanguage(.arabic)
        XCTAssertFalse(l10n.number(1234).isEmpty)
    }
}
#endif
