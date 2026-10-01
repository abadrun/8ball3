//
//  SpicyStateMachineTests.swift
//  MR. SPICY UI v1.0.0
//
//  These tests are pure Swift (no UIKit) and therefore run on any toolchain.
//
//  STATUS: NOT EXECUTED in the authoring environment — no Swift toolchain was
//  available. See validation/validation-report.md.
//

import XCTest
@testable import MrSpicyUI

final class SpicyStateMachineTests: XCTestCase {

    func testStartsClosed() {
        let machine = SpicyStateMachine()
        XCTAssertEqual(machine.presentation, .closed)
        XCTAssertFalse(machine.isVisible)
    }

    func testOpenExpands() {
        var machine = SpicyStateMachine()
        XCTAssertEqual(machine.send(.open), .expanded)
        XCTAssertTrue(machine.isVisible)
    }

    func testMinimiseAndExpandRoundTrip() {
        var machine = SpicyStateMachine()
        machine.send(.open)
        XCTAssertEqual(machine.send(.minimise), .minimised)
        XCTAssertEqual(machine.send(.expand), .expanded)
    }

    func testCloseFromAnyState() {
        for event in [SpicyEvent.open, .minimise, .openSettings, .present(.info)] {
            var machine = SpicyStateMachine()
            machine.send(.open)
            machine.send(event)
            XCTAssertEqual(machine.send(.close), .closed,
                           "close must always return to .closed (from \(event))")
        }
    }

    func testSettingsOnlyFromExpanded() {
        var machine = SpicyStateMachine()
        // Illegal: settings cannot open while closed.
        XCTAssertEqual(machine.send(.openSettings), .closed)
        machine.send(.open)
        XCTAssertEqual(machine.send(.openSettings), .settingsPresented)
        XCTAssertEqual(machine.send(.closeSettings), .expanded)
    }

    func testModalPresentationAndDismissal() {
        var machine = SpicyStateMachine()
        machine.send(.open)
        XCTAssertEqual(machine.send(.present(.language)), .modalPresented(.language))
        XCTAssertTrue(machine.isModalVisible)
        XCTAssertEqual(machine.send(.dismissModal), .expanded)
        XCTAssertFalse(machine.isModalVisible)
    }

    func testUnknownTransitionsAreNoOps() {
        var machine = SpicyStateMachine()
        XCTAssertEqual(machine.send(.minimise), .closed)
        XCTAssertEqual(machine.send(.dismissModal), .closed)
    }

    func testLanguageChangeDoesNotAlterPresentation() {
        var machine = SpicyStateMachine()
        machine.send(.open)
        XCTAssertEqual(machine.send(.languageChanged(.ar)), .expanded)
        XCTAssertEqual(machine.language, .ar)
        XCTAssertTrue(machine.consumeDirectionRefresh())
        XCTAssertFalse(machine.consumeDirectionRefresh(), "flag must be consumed once")
    }

    func testReducerIsPure() {
        XCTAssertEqual(SpicyStateMachine.reduce(.closed, .open), .expanded)
        XCTAssertEqual(SpicyStateMachine.reduce(.expanded, .minimise), .minimised)
        XCTAssertEqual(SpicyStateMachine.reduce(.minimised, .minimise), .minimised)
    }

    func testRightToLeftFlag() {
        XCTAssertTrue(SpicyLanguageCode.ar.isRightToLeft)
        XCTAssertFalse(SpicyLanguageCode.en.isRightToLeft)
    }
}
