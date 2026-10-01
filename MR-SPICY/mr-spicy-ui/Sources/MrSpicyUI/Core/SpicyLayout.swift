//
//  SpicyLayout.swift
//  MR. SPICY UI — RTL, safe area and responsive helpers
//
//  MR. SPICY UI v1.0.0
//

#if canImport(UIKit)
import UIKit

// MARK: - Layout direction

public enum SpicyLayoutDirection {

    /// Applies the semantic content attribute implied by the active MR. SPICY
    /// language to `view` and its whole subtree.
    ///
    /// This is what makes Arabic a genuine RTL layout rather than translated
    /// text inside an LTR skeleton: all MR. SPICY constraints use
    /// leading/trailing anchors, so flipping the semantic attribute mirrors the
    /// entire component tree, including stack-view ordering.
    public static func apply(_ language: SpicyLanguage, to view: UIView) {
        let attribute: UISemanticContentAttribute =
            language.isRightToLeft ? .forceRightToLeft : .forceLeftToRight
        applyRecursively(attribute, to: view)
    }

    private static func applyRecursively(_ attribute: UISemanticContentAttribute, to view: UIView) {
        view.semanticContentAttribute = attribute
        for subview in view.subviews {
            applyRecursively(attribute, to: subview)
        }
    }

    /// Mirrors directional iconography (chevrons, arrows, back buttons).
    /// Non-directional glyphs must *not* be passed through this helper.
    public static func directionalImage(_ image: UIImage?) -> UIImage? {
        image?.imageFlippedForRightToLeftLayoutDirection()
    }

    /// Natural text alignment for the active language.
    public static func textAlignment(for language: SpicyLanguage) -> NSTextAlignment {
        language.isRightToLeft ? .right : .left
    }

    /// Transform used to mirror a custom-drawn directional view.
    public static func mirrorTransform(for language: SpicyLanguage) -> CGAffineTransform {
        language.isRightToLeft ? CGAffineTransform(scaleX: -1, y: 1) : .identity
    }
}

// MARK: - Size classes / responsiveness

public struct SpicyLayoutMetrics {

    public enum Width {
        /// iPhone SE / mini class (≤ 375 pt).
        case compact
        /// Standard iPhone (376–413 pt).
        case regular
        /// iPhone Max / iPad in split view (≥ 414 pt).
        case wide
    }

    public let width: Width
    public let isLandscape: Bool
    public let isPad: Bool
    public let contentSizeCategory: UIContentSizeCategory
    public let safeArea: UIEdgeInsets

    public init(traitCollection: UITraitCollection,
                size: CGSize,
                safeArea: UIEdgeInsets) {
        if size.width <= 375 { width = .compact }
        else if size.width < 414 { width = .regular }
        else { width = .wide }
        isLandscape = size.width > size.height
        isPad = traitCollection.userInterfaceIdiom == .pad
        contentSizeCategory = traitCollection.preferredContentSizeCategory
        self.safeArea = safeArea
    }

    /// `true` when text has grown large enough that horizontal rows must become
    /// vertical stacks to avoid clipping.
    public var prefersStackedRows: Bool {
        contentSizeCategory >= SpicyTheme.Typography.stackedLayoutThreshold
    }

    /// Horizontal padding that keeps content clear of notches / rounded corners
    /// in every orientation.
    public var contentInset: UIEdgeInsets {
        let horizontal: CGFloat
        switch width {
        case .compact: horizontal = SpicyTheme.Spacing.m
        case .regular: horizontal = SpicyTheme.Spacing.l
        case .wide: horizontal = SpicyTheme.Spacing.xl
        }
        return UIEdgeInsets(top: SpicyTheme.Spacing.l,
                            left: horizontal + safeArea.left,
                            bottom: SpicyTheme.Spacing.l + safeArea.bottom,
                            right: horizontal + safeArea.right)
    }

    /// Side length used for feature tiles at this size class.
    public var tileSide: CGFloat {
        switch width {
        case .compact: return SpicyTheme.Size.tileSide - 8
        case .regular: return SpicyTheme.Size.tileSide
        case .wide: return SpicyTheme.Size.tileSide + 6
        }
    }

    /// Number of tiles per row — never hard-coded in a component.
    public func tileColumns(availableWidth: CGFloat) -> Int {
        let spacing = SpicyTheme.Spacing.m
        let usable = availableWidth - contentInset.left - contentInset.right
        let columns = Int((usable + spacing) / (tileSide + spacing))
        return max(2, min(isPad ? 6 : 4, columns))
    }

    /// Width of a modal for this environment.
    public func modalWidth(availableWidth: CGFloat) -> CGFloat {
        min(SpicyTheme.Size.modalMaxWidth,
            availableWidth - contentInset.left - contentInset.right)
    }
}

// MARK: - Auto Layout sugar

public extension UIView {

    /// Pins `self` to `other` using **directional** anchors so the result is
    /// automatically mirrored in RTL.
    @discardableResult
    func spicyPin(to other: UIView,
                  insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            topAnchor.constraint(equalTo: other.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: other.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: other.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: -insets.bottom),
        ]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    /// Pins `self` to the safe area of `other`. Every MR. SPICY root surface
    /// uses this, which is what keeps content clear of the status bar, Dynamic
    /// Island and home indicator.
    @discardableResult
    func spicyPinToSafeArea(of other: UIView,
                            insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        let guide = other.safeAreaLayoutGuide
        let constraints = [
            topAnchor.constraint(equalTo: guide.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -insets.bottom),
        ]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    /// Guarantees the HIG minimum hit target without changing visual size.
    @discardableResult
    func spicyEnforceMinimumTouchTarget() -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            widthAnchor.constraint(greaterThanOrEqualToConstant: SpicyTheme.Size.minimumTouchTarget),
            heightAnchor.constraint(greaterThanOrEqualToConstant: SpicyTheme.Size.minimumTouchTarget),
        ]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }
}
#endif
