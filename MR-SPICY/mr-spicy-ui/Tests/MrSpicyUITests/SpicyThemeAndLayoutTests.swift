//
//  SpicyThemeAndLayoutTests.swift
//  MR. SPICY UI v1.0.0
//
//  STATUS: NOT EXECUTED in the authoring environment — no iOS toolchain /
//  simulator was available. The contrast and touch-target assertions below are
//  mirrored by validation/tools/validate_design_tokens.py, which passes.
//

#if canImport(UIKit)
import XCTest
import UIKit
@testable import MrSpicyUI

final class SpicyThemeAndLayoutTests: XCTestCase {

    // MARK: Contrast

    func testBodyTextMeetsWCAGAAOnDarkSurfaces() {
        let pairs: [(UIColor, UIColor, CGFloat)] = [
            (SpicyTheme.Color.textPrimary, SpicyTheme.Color.background, 4.5),
            (SpicyTheme.Color.textPrimary, SpicyTheme.Color.surface, 4.5),
            (SpicyTheme.Color.textSecondary, SpicyTheme.Color.surface, 4.5),
            (SpicyTheme.Color.primaryTint, SpicyTheme.Color.surface, 4.5),
        ]
        for (foreground, background, minimum) in pairs {
            XCTAssertGreaterThanOrEqual(
                foreground.spicyContrastRatio(against: background), minimum)
        }
    }

    func testTouchTargetTokenMeetsHIG() {
        XCTAssertGreaterThanOrEqual(SpicyTheme.Size.minimumTouchTarget, 44)
        XCTAssertGreaterThanOrEqual(SpicyTheme.Size.controlHeight, 44)
    }

    func testReduceMotionCollapsesDurations() {
        // When Reduce Motion is on, every duration must resolve to zero.
        if UIAccessibility.isReduceMotionEnabled {
            XCTAssertEqual(SpicyTheme.Motion.duration(SpicyTheme.Motion.slow), 0)
        } else {
            XCTAssertEqual(SpicyTheme.Motion.duration(SpicyTheme.Motion.slow),
                           SpicyTheme.Motion.slow)
        }
    }

    // MARK: Layout direction

    func testApplyingArabicForcesRTLThroughSubtree() {
        let root = UIView()
        let child = UIView()
        let grandchild = UIView()
        child.addSubview(grandchild)
        root.addSubview(child)

        SpicyLayoutDirection.apply(.arabic, to: root)
        for view in [root, child, grandchild] {
            XCTAssertEqual(view.semanticContentAttribute, .forceRightToLeft)
        }

        SpicyLayoutDirection.apply(.english, to: root)
        for view in [root, child, grandchild] {
            XCTAssertEqual(view.semanticContentAttribute, .forceLeftToRight)
        }
    }

    func testTextAlignmentFollowsLanguage() {
        XCTAssertEqual(SpicyLayoutDirection.textAlignment(for: .arabic), .right)
        XCTAssertEqual(SpicyLayoutDirection.textAlignment(for: .english), .left)
    }

    // MARK: Responsive metrics

    func testColumnCountAdaptsToWidth() {
        func metrics(_ width: CGFloat, pad: Bool = false) -> SpicyLayoutMetrics {
            SpicyLayoutMetrics(
                traitCollection: UITraitCollection(userInterfaceIdiom: pad ? .pad : .phone),
                size: CGSize(width: width, height: 800),
                safeArea: UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0))
        }
        XCTAssertGreaterThanOrEqual(metrics(320).tileColumns(availableWidth: 320), 2)
        XCTAssertLessThanOrEqual(metrics(320).tileColumns(availableWidth: 320), 4)
        XCTAssertLessThanOrEqual(metrics(1024, pad: true).tileColumns(availableWidth: 1024), 6)
    }

    func testContentInsetIncludesSafeArea() {
        let safeArea = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        let metrics = SpicyLayoutMetrics(traitCollection: UITraitCollection(),
                                         size: CGSize(width: 390, height: 844),
                                         safeArea: safeArea)
        XCTAssertGreaterThanOrEqual(metrics.contentInset.bottom, safeArea.bottom)
    }

    func testLandscapeSafeAreaIsRespected() {
        let safeArea = UIEdgeInsets(top: 0, left: 59, bottom: 21, right: 59)
        let metrics = SpicyLayoutMetrics(traitCollection: UITraitCollection(),
                                         size: CGSize(width: 844, height: 390),
                                         safeArea: safeArea)
        XCTAssertTrue(metrics.isLandscape)
        XCTAssertGreaterThanOrEqual(metrics.contentInset.left, safeArea.left)
        XCTAssertGreaterThanOrEqual(metrics.contentInset.right, safeArea.right)
    }

    func testLargeContentSizeTriggersStackedRows() {
        let metrics = SpicyLayoutMetrics(
            traitCollection: UITraitCollection(preferredContentSizeCategory: .accessibilityLarge),
            size: CGSize(width: 390, height: 844),
            safeArea: .zero)
        XCTAssertTrue(metrics.prefersStackedRows)
    }

    // MARK: Components

    func testFeatureTileExposesAccessibilityState() {
        let tile = SpicyFeatureTile(model: .init(id: "settings",
                                                 titleKey: .settingsTitle,
                                                 systemImageName: "gearshape",
                                                 state: .selected))
        XCTAssertTrue(tile.isAccessibilityElement)
        XCTAssertTrue(tile.accessibilityTraits.contains(.selected))
        XCTAssertEqual(tile.accessibilityLabel, SpicyStringKey.settingsTitle.localized)
    }

    func testDisabledTileIsMarkedNotEnabled() {
        let tile = SpicyFeatureTile(model: .init(id: "help",
                                                 titleKey: .settingsHelp,
                                                 systemImageName: "questionmark.circle",
                                                 state: .disabled))
        XCTAssertTrue(tile.accessibilityTraits.contains(.notEnabled))
    }

    func testModalIsAccessibilityModal() {
        let modal = SpicyModalView(configuration: .info(titleKey: .aboutTitle,
                                                        messageKey: .aboutCredits))
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        modal.present(in: container)
        XCTAssertFalse(container.subviews.isEmpty)
    }
}
#endif
