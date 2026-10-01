//
//  SpicyLocalization.swift
//  MR. SPICY UI — centralised localisation
//
//  MR. SPICY UI v1.0.0
//
//  All user-visible strings in the MR. SPICY layer go through `SpicyL10n`.
//  Components never contain literal display text.
//
//  Supported languages: English (base / fallback) and Arabic.
//

#if canImport(UIKit)
import UIKit

// MARK: - Language

public enum SpicyLanguage: String, CaseIterable, Codable, Sendable {
    case english = "en"
    case arabic = "ar"

    /// The language's own name, for use in the language picker.
    public var endonym: String {
        switch self {
        case .english: return "English"
        case .arabic: return "العربية"
        }
    }

    public var layoutDirection: UIUserInterfaceLayoutDirection {
        switch self {
        case .english: return .leftToRight
        case .arabic: return .rightToLeft
        }
    }

    public var isRightToLeft: Bool { layoutDirection == .rightToLeft }

    public var locale: Locale { Locale(identifier: rawValue) }

    /// Resolves the best supported language for the user's preferred languages,
    /// falling back to English.
    public static func resolvedFromSystem() -> SpicyLanguage {
        for preferred in Locale.preferredLanguages {
            let code = preferred.split(separator: "-").first.map(String.init) ?? preferred
            if let match = SpicyLanguage(rawValue: code) { return match }
        }
        return .english
    }
}

// MARK: - Localisation centre

/// Centralised string provider for the MR. SPICY UI layer.
///
/// * Strings live in `Resources/<lang>.lproj/MrSpicy.strings` — never in code.
/// * A missing Arabic key silently falls back to English **and** is reported
///   through `missingKeyHandler`, so gaps are detectable in CI and in QA builds.
/// * Changing `current` posts `SpicyL10n.languageDidChangeNotification`; the
///   overlay container rebuilds its layout and semantic content attribute in
///   response — no app restart is required.
public final class SpicyL10n {

    public static let shared = SpicyL10n()

    public static let languageDidChangeNotification =
        Notification.Name("MrSpicyUI.languageDidChange")

    private static let storageKey = "MrSpicyUI.selectedLanguage"

    /// Called whenever a key is missing from the active language table.
    /// Default implementation asserts in debug and is a no-op in release.
    public var missingKeyHandler: (String, SpicyLanguage) -> Void = { key, language in
        #if DEBUG
        assertionFailure("MR. SPICY: missing localisation for key '\(key)' in \(language.rawValue)")
        #endif
        _ = (key, language)
    }

    private let defaults: UserDefaults
    private var bundleCache: [SpicyLanguage: Bundle] = [:]

    public private(set) var current: SpicyLanguage {
        didSet {
            guard oldValue != current else { return }
            defaults.set(current.rawValue, forKey: Self.storageKey)
            NotificationCenter.default.post(name: Self.languageDidChangeNotification,
                                            object: self,
                                            userInfo: ["language": current.rawValue])
        }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Self.storageKey),
           let stored = SpicyLanguage(rawValue: raw) {
            self.current = stored
        } else {
            self.current = .resolvedFromSystem()
        }
    }

    public func setLanguage(_ language: SpicyLanguage) {
        current = language
    }

    /// Resource bundle that contains the MR. SPICY `.strings` tables.
    /// Works both for SwiftPM (`Bundle.module`) and for a host app that copies
    /// the resources into its main bundle.
    public static var resourceBundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        let candidate = Bundle(for: SpicyL10n.self)
        if let url = candidate.url(forResource: "MrSpicyUI", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return candidate
        #endif
    }()

    private func bundle(for language: SpicyLanguage) -> Bundle {
        if let cached = bundleCache[language] { return cached }
        let resolved: Bundle
        if let path = Self.resourceBundle.path(forResource: language.rawValue, ofType: "lproj"),
           let lproj = Bundle(path: path) {
            resolved = lproj
        } else {
            resolved = Self.resourceBundle
        }
        bundleCache[language] = resolved
        return resolved
    }

    private static let sentinel = "\u{0}MR_SPICY_MISSING\u{0}"

    /// Localised string for `key` in the active language, falling back to English.
    public func string(_ key: SpicyStringKey) -> String {
        string(key.rawValue)
    }

    public func string(_ key: String) -> String {
        let table = "MrSpicy"
        let value = bundle(for: current).localizedString(forKey: key,
                                                         value: Self.sentinel,
                                                         table: table)
        if value != Self.sentinel { return value }

        missingKeyHandler(key, current)

        if current != .english {
            let fallback = bundle(for: .english).localizedString(forKey: key,
                                                                 value: Self.sentinel,
                                                                 table: table)
            if fallback != Self.sentinel { return fallback }
        }
        #if DEBUG
        return "⟦\(key)⟧"   // loudly visible in QA builds
        #else
        return key
        #endif
    }

    /// Formatted string. Arguments are formatted with the active language's
    /// locale so numerals/dates follow the user's language.
    public func string(_ key: SpicyStringKey, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: current.locale, arguments: arguments)
    }

    /// Pluralised string. Requires a matching `.stringsdict` entry; falls back
    /// to the singular table when the dictionary entry is absent.
    public func plural(_ key: SpicyStringKey, count: Int) -> String {
        String(format: string(key), locale: current.locale, count)
    }

    /// Number formatted for the active language.
    public func number(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = current.locale
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - Type-safe keys

/// Every string used by the MR. SPICY layer. Keeping the keys in an enum makes
/// missing-translation checks a compile-time + CI matter rather than a runtime
/// surprise. `validate_localization.py` cross-checks this list against the
/// `.strings` tables.
public enum SpicyStringKey: String, CaseIterable, Sendable {

    // Header / container
    case headerTitle                = "spicy.header.title"
    case headerSubtitle             = "spicy.header.subtitle"
    case headerClose                = "spicy.header.close"
    case headerMinimise             = "spicy.header.minimise"
    case headerExpand               = "spicy.header.expand"
    case headerSettings             = "spicy.header.settings"

    // Generic actions
    case actionOK                   = "spicy.action.ok"
    case actionCancel               = "spicy.action.cancel"
    case actionClose                = "spicy.action.close"
    case actionRetry                = "spicy.action.retry"
    case actionDone                 = "spicy.action.done"
    case actionBack                 = "spicy.action.back"
    case actionLearnMore            = "spicy.action.learn_more"

    // Generic states
    case stateLoading               = "spicy.state.loading"
    case stateSuccess               = "spicy.state.success"
    case stateError                 = "spicy.state.error"
    case stateUnavailable           = "spicy.state.unavailable"
    case stateDisabled              = "spicy.state.disabled"
    case stateSelected              = "spicy.state.selected"
    case stateOn                    = "spicy.state.on"
    case stateOff                   = "spicy.state.off"

    // Settings
    case settingsTitle              = "spicy.settings.title"
    case settingsSectionGeneral     = "spicy.settings.section.general"
    case settingsSectionAppearance  = "spicy.settings.section.appearance"
    case settingsSectionAccessibility = "spicy.settings.section.accessibility"
    case settingsSectionAbout       = "spicy.settings.section.about"
    case settingsLanguage           = "spicy.settings.language"
    case settingsLanguageHint       = "spicy.settings.language.hint"
    case settingsAppearance         = "spicy.settings.appearance"
    case settingsAppearanceSystem   = "spicy.settings.appearance.system"
    case settingsAppearanceDark     = "spicy.settings.appearance.dark"
    case settingsAppearanceLight    = "spicy.settings.appearance.light"
    case settingsReduceMotion       = "spicy.settings.reduce_motion"
    case settingsReduceMotionHint   = "spicy.settings.reduce_motion.hint"
    case settingsLargerText         = "spicy.settings.larger_text"
    case settingsLargerTextHint     = "spicy.settings.larger_text.hint"
    case settingsHighContrast       = "spicy.settings.high_contrast"
    case settingsCompactLayout      = "spicy.settings.compact_layout"
    case settingsVersion            = "spicy.settings.version"
    case settingsHelp               = "spicy.settings.help"
    case settingsLegal              = "spicy.settings.legal"
    case settingsResetTitle         = "spicy.settings.reset.title"
    case settingsResetMessage       = "spicy.settings.reset.message"
    case settingsResetConfirm       = "spicy.settings.reset.confirm"

    // Language picker
    case languageTitle              = "spicy.language.title"
    case languageEnglish            = "spicy.language.english"
    case languageArabic             = "spicy.language.arabic"
    case languageChanged            = "spicy.language.changed"

    // About / info
    case aboutTitle                 = "spicy.about.title"
    case aboutUILayerVersion        = "spicy.about.ui_layer_version"
    case aboutDesignSystem          = "spicy.about.design_system"
    case aboutCredits               = "spicy.about.credits"

    // Accessibility-only strings
    case a11yLogo                   = "spicy.a11y.logo"
    case a11yPanel                  = "spicy.a11y.panel"
    case a11yModal                  = "spicy.a11y.modal"
    case a11yTileHint               = "spicy.a11y.tile.hint"
    case a11yRowHint                = "spicy.a11y.row.hint"
    case a11yBadgeValue             = "spicy.a11y.badge.value"
}

// MARK: - Convenience

public extension SpicyStringKey {
    /// Shorthand so components can write `SpicyStringKey.actionOK.localized`.
    var localized: String { SpicyL10n.shared.string(self) }
}
#endif
