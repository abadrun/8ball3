//
//  SpicyState.swift
//  MR. SPICY UI — explicit, testable state model
//
//  MR. SPICY UI v1.0.0
//
//  The overlay container has a single source of truth instead of a scattered
//  set of Booleans. Illegal transitions are impossible by construction and the
//  whole model is pure Swift, so it is unit-testable without a UI.
//

import Foundation

// MARK: - Presentation state

public enum SpicyPresentationState: Equatable, Sendable {
    case closed
    case minimised
    case expanded
    case settingsPresented
    case modalPresented(SpicyModalKind)
}

public enum SpicyModalKind: String, Equatable, Sendable {
    case info
    case confirmation
    case language
    case help
    case error
}

// MARK: - Content state

/// Generic loading state for any content the host legitimately supplies.
public enum SpicyContentState<Value: Equatable>: Equatable {
    case idle
    case loading
    case success(Value)
    case failure(SpicyFailure)
    case unavailable(reason: String)

    public var isLoading: Bool { if case .loading = self { return true }; return false }
    public var value: Value? { if case .success(let v) = self { return v }; return nil }
}

public struct SpicyFailure: Equatable, Error, Sendable {
    public let code: String
    public let messageKey: SpicyFailureMessage

    public init(code: String, messageKey: SpicyFailureMessage = .generic) {
        self.code = code
        self.messageKey = messageKey
    }
}

public enum SpicyFailureMessage: String, Equatable, Sendable {
    case generic
    case offline
    case timeout
    case notSupported
}

// MARK: - Control state

public struct SpicyControlState: Equatable, Sendable {
    public var isEnabled: Bool
    public var isSelected: Bool
    public var isBusy: Bool

    public init(isEnabled: Bool = true, isSelected: Bool = false, isBusy: Bool = false) {
        self.isEnabled = isEnabled
        self.isSelected = isSelected
        self.isBusy = isBusy
    }

    public static let `default` = SpicyControlState()
    public static let disabled = SpicyControlState(isEnabled: false)
    public static let selected = SpicyControlState(isSelected: true)
    public static let busy = SpicyControlState(isBusy: true)
}

// MARK: - Events

public enum SpicyEvent: Equatable, Sendable {
    case open
    case minimise
    case expand
    case close
    case openSettings
    case closeSettings
    case present(SpicyModalKind)
    case dismissModal
    case languageChanged(SpicyLanguageCode)
}

/// Mirrors `SpicyLanguage` without importing UIKit, so the state machine stays
/// platform-independent and unit-testable on any Swift toolchain.
public enum SpicyLanguageCode: String, Equatable, Sendable, CaseIterable {
    case en
    case ar

    public var isRightToLeft: Bool { self == .ar }
}

// MARK: - State machine

/// Deterministic reducer for the MR. SPICY overlay.
///
/// `reduce` is a pure function: given a state and an event it returns the next
/// state. Any transition that is not explicitly allowed leaves the state
/// unchanged, which makes "impossible UI" genuinely impossible.
public struct SpicyStateMachine {

    public private(set) var presentation: SpicyPresentationState
    public private(set) var language: SpicyLanguageCode
    /// Set for one read after a language change so the container knows it must
    /// rebuild its layout direction.
    public private(set) var needsDirectionRefresh: Bool = false

    public init(presentation: SpicyPresentationState = .closed,
                language: SpicyLanguageCode = .en) {
        self.presentation = presentation
        self.language = language
    }

    public static func reduce(_ state: SpicyPresentationState,
                              _ event: SpicyEvent) -> SpicyPresentationState {
        switch (state, event) {
        case (.closed, .open), (.minimised, .expand), (.minimised, .open):
            return .expanded
        case (.expanded, .minimise):
            return .minimised
        case (_, .close):
            return .closed
        case (.expanded, .openSettings):
            return .settingsPresented
        case (.settingsPresented, .closeSettings):
            return .expanded
        case (.expanded, .present(let kind)), (.settingsPresented, .present(let kind)):
            return .modalPresented(kind)
        case (.modalPresented, .dismissModal):
            return .expanded
        default:
            return state
        }
    }

    @discardableResult
    public mutating func send(_ event: SpicyEvent) -> SpicyPresentationState {
        if case .languageChanged(let code) = event {
            if code != language {
                language = code
                needsDirectionRefresh = true
            }
            return presentation
        }
        presentation = Self.reduce(presentation, event)
        return presentation
    }

    public mutating func consumeDirectionRefresh() -> Bool {
        defer { needsDirectionRefresh = false }
        return needsDirectionRefresh
    }

    public var isVisible: Bool { presentation != .closed }
    public var isModalVisible: Bool {
        if case .modalPresented = presentation { return true }
        return false
    }
}
