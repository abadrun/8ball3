//
//  SpicyTheme.swift
//  MR. SPICY UI — centralised design tokens
//
//  MR. SPICY UI v1.0.0
//
//  Every visual value used by the MR. SPICY component library is declared here.
//  Components must never hard-code colours, radii, spacing, durations or fonts.
//
//  Brand colours were sampled from the supplied `logo.png`
//  (core red = sRGB 211,1,2 ; canvas = sRGB 5,3,5).
//

#if canImport(UIKit)
import UIKit

// MARK: - Theme

/// Namespace for all MR. SPICY design tokens.
///
/// `SpicyTheme` is intentionally a value-type namespace (no shared mutable
/// state) so that it can be used safely from any thread that is already on the
/// main actor, and so that it can never leak.
public enum SpicyTheme {

    // MARK: Colour

    public enum Color {

        // Brand -------------------------------------------------------------

        /// Primary brand red, sampled from the MR. SPICY mark.
        public static let primary = UIColor(spicyHex: 0xD30102)
        /// Pressed / active state of the primary brand red.
        public static let primaryPressed = UIColor(spicyHex: 0xA60103)
        /// Lighter brand tint used for text and icons on dark surfaces
        /// (contrast ratio vs `background` ≈ 5.1:1).
        public static let primaryTint = UIColor(spicyHex: 0xFF4D52)
        /// Low-emphasis brand wash for selected rows / chips.
        public static let primaryWash = UIColor(spicyHex: 0xD30102, alpha: 0.14)

        // Neutral surfaces ----------------------------------------------------

        public static let background = UIColor.spicyDynamic(dark: 0x0A0A0B, light: 0xF4F4F6)
        public static let surface = UIColor.spicyDynamic(dark: 0x141416, light: 0xFFFFFF)
        public static let surfaceElevated = UIColor.spicyDynamic(dark: 0x1C1C1F, light: 0xFFFFFF)
        public static let surfaceSunken = UIColor.spicyDynamic(dark: 0x0F0F11, light: 0xEDEDF1)
        public static let scrim = UIColor(spicyHex: 0x000000, alpha: 0.55)
        public static let separator = UIColor.spicyDynamic(dark: 0x2A2A2E, light: 0xDEDEE3)
        public static let border = UIColor.spicyDynamic(dark: 0x303036, light: 0xD2D2D9)

        // Text ----------------------------------------------------------------

        public static let textPrimary = UIColor.spicyDynamic(dark: 0xFFFFFF, light: 0x101014)
        public static let textSecondary = UIColor.spicyDynamic(dark: 0xA2A2AA, light: 0x5B5B66)
        public static let textTertiary = UIColor.spicyDynamic(dark: 0x74747C, light: 0x8A8A95)
        public static let textDisabled = UIColor.spicyDynamic(dark: 0x55555C, light: 0xAAAAB3)
        public static let textOnPrimary = UIColor(spicyHex: 0xFFFFFF)

        // Semantic -------------------------------------------------------------

        public static let success = UIColor(spicyHex: 0x2FBF71)
        public static let warning = UIColor(spicyHex: 0xF5A524)
        public static let danger = UIColor(spicyHex: 0xFF4D52)
        public static let info = UIColor(spicyHex: 0x3B82F6)
        public static let neutralBadge = UIColor.spicyDynamic(dark: 0x2A2A2E, light: 0xE4E4EA)

        // Control states ---------------------------------------------------------

        public static let controlFill = UIColor.spicyDynamic(dark: 0x1F1F23, light: 0xECECF1)
        public static let controlFillSelected = primaryWash
        public static let controlFillDisabled = UIColor.spicyDynamic(dark: 0x18181B, light: 0xF0F0F4)
    }

    // MARK: Spacing (4-pt grid)

    public enum Spacing {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 12
        public static let l: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
        public static let xxxl: CGFloat = 40
    }

    // MARK: Corner radius

    public enum Radius {
        public static let none: CGFloat = 0
        /// Small decorative dot (status indicators).
        public static let dot: CGFloat = 3
        public static let xs: CGFloat = 6
        public static let s: CGFloat = 10
        public static let m: CGFloat = 14
        public static let l: CGFloat = 20
        public static let xl: CGFloat = 28
        /// Use with `UIView.layer.cornerRadius = bounds.height / 2`.
        public static let pill: CGFloat = -1
    }

    // MARK: Stroke

    public enum Stroke {
        public static let hairline: CGFloat = 1.0 / UIScreen.main.scale
        public static let thin: CGFloat = 1
        public static let medium: CGFloat = 1.5
        public static let focus: CGFloat = 2
    }

    // MARK: Typography

    /// All text styles are built on `UIFontMetrics` so Dynamic Type works
    /// everywhere without any additional work in components.
    public enum Typography {
        public static func title() -> UIFont { scaled(.title3, size: 20, weight: .bold) }
        public static func headline() -> UIFont { scaled(.headline, size: 17, weight: .semibold) }
        public static func body() -> UIFont { scaled(.body, size: 15, weight: .regular) }
        public static func bodyEmphasised() -> UIFont { scaled(.body, size: 15, weight: .semibold) }
        public static func callout() -> UIFont { scaled(.callout, size: 14, weight: .regular) }
        public static func caption() -> UIFont { scaled(.caption1, size: 12, weight: .regular) }
        public static func captionEmphasised() -> UIFont { scaled(.caption1, size: 12, weight: .semibold) }
        public static func button() -> UIFont { scaled(.headline, size: 16, weight: .semibold) }

        /// Largest point size a component should grow to before it switches to a
        /// stacked (vertical) layout. Prevents clipping at accessibility sizes.
        public static let stackedLayoutThreshold: UIContentSizeCategory = .accessibilityMedium

        private static func scaled(_ style: UIFont.TextStyle,
                                   size: CGFloat,
                                   weight: UIFont.Weight) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
        }
    }

    // MARK: Icon & control sizing

    public enum Size {
        public static let iconXS: CGFloat = 14
        public static let iconS: CGFloat = 18
        public static let iconM: CGFloat = 22
        public static let iconL: CGFloat = 28

        /// Apple HIG minimum hit target.
        public static let minimumTouchTarget: CGFloat = 44
        public static let controlHeight: CGFloat = 44
        public static let compactControlHeight: CGFloat = 36
        public static let headerHeight: CGFloat = 56
        public static let tileSide: CGFloat = 76
        public static let badgeHeight: CGFloat = 22
        public static let modalMaxWidth: CGFloat = 420
        public static let overlayMaxWidth: CGFloat = 520
    }

    // MARK: Elevation

    public struct Shadow {
        public let color: UIColor
        public let opacity: Float
        public let radius: CGFloat
        public let offset: CGSize

        public static let none = Shadow(color: .clear, opacity: 0, radius: 0, offset: .zero)
        public static let level1 = Shadow(color: .black, opacity: 0.18, radius: 8, offset: CGSize(width: 0, height: 2))
        public static let level2 = Shadow(color: .black, opacity: 0.24, radius: 18, offset: CGSize(width: 0, height: 8))
        public static let level3 = Shadow(color: .black, opacity: 0.32, radius: 28, offset: CGSize(width: 0, height: 14))
    }

    // MARK: Opacity

    public enum Opacity {
        public static let disabled: CGFloat = 0.38
        public static let pressed: CGFloat = 0.72
        public static let overlayScrim: CGFloat = 0.55
        public static let subtle: CGFloat = 0.6
    }

    // MARK: Motion

    public enum Motion {
        public static let fast: TimeInterval = 0.16
        public static let standard: TimeInterval = 0.24
        public static let slow: TimeInterval = 0.36
        public static let springDamping: CGFloat = 0.86
        public static let springVelocity: CGFloat = 0.4

        /// Returns `0` when the user has enabled Reduce Motion, so callers can
        /// use the same animation code path in both cases.
        public static func duration(_ value: TimeInterval) -> TimeInterval {
            UIAccessibility.isReduceMotionEnabled ? 0 : value
        }

        public static func animate(_ value: TimeInterval = standard,
                                   animations: @escaping () -> Void,
                                   completion: ((Bool) -> Void)? = nil) {
            let d = duration(value)
            guard d > 0 else {
                animations()
                completion?(true)
                return
            }
            UIView.animate(withDuration: d,
                           delay: 0,
                           usingSpringWithDamping: springDamping,
                           initialSpringVelocity: springVelocity,
                           options: [.allowUserInteraction, .beginFromCurrentState],
                           animations: animations,
                           completion: completion)
        }
    }
}

// MARK: - UIView helpers

public extension UIView {

    /// Applies a MR. SPICY elevation token.
    func spicyApply(shadow: SpicyTheme.Shadow) {
        layer.shadowColor = shadow.color.cgColor
        layer.shadowOpacity = shadow.opacity
        layer.shadowRadius = shadow.radius
        layer.shadowOffset = shadow.offset
        layer.masksToBounds = false
    }

    /// Applies a MR. SPICY corner-radius token with continuous curvature.
    func spicyApply(radius: CGFloat) {
        layer.cornerCurve = .continuous
        layer.cornerRadius = radius
    }
}

// MARK: - UIColor helpers

public extension UIColor {

    convenience init(spicyHex hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255.0,
                  green: CGFloat((hex >> 8) & 0xFF) / 255.0,
                  blue: CGFloat(hex & 0xFF) / 255.0,
                  alpha: alpha)
    }

    /// Light/dark adaptive colour. MR. SPICY ships a dark-first palette; the
    /// light variants exist so the layer can be embedded in light-mode hosts.
    static func spicyDynamic(dark: UInt32, light: UInt32) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .light
                ? UIColor(spicyHex: light)
                : UIColor(spicyHex: dark)
        }
    }

    /// WCAG 2.1 relative-luminance contrast ratio against another colour.
    /// Used by the design-system unit tests, not at runtime.
    func spicyContrastRatio(against other: UIColor) -> CGFloat {
        func luminance(_ color: UIColor) -> CGFloat {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
                 .getRed(&r, green: &g, blue: &b, alpha: &a)
            func channel(_ c: CGFloat) -> CGFloat {
                c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
        }
        let l1 = luminance(self), l2 = luminance(other)
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }
}
#endif
