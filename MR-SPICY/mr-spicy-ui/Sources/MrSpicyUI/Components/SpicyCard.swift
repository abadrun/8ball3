//
//  SpicyCard.swift
//  MR. SPICY UI — elevated surface container
//
//  MR. SPICY UI v1.0.0
//

#if canImport(UIKit)
import UIKit

/// Rounded surface used for every grouped area in the MR. SPICY layer.
/// Content is added to `contentView`, which is already inset by the token grid.
public final class SpicyCard: UIView {

    public enum Elevation {
        case flat
        case raised
        case floating

        var shadow: SpicyTheme.Shadow {
            switch self {
            case .flat: return .none
            case .raised: return .level1
            case .floating: return .level2
            }
        }

        var fill: UIColor {
            switch self {
            case .flat: return SpicyTheme.Color.surfaceSunken
            case .raised: return SpicyTheme.Color.surface
            case .floating: return SpicyTheme.Color.surfaceElevated
            }
        }
    }

    public let contentView = UIView()
    public var elevation: Elevation { didSet { applyStyle() } }

    private var contentConstraints: [NSLayoutConstraint] = []

    public init(elevation: Elevation = .raised,
                padding: UIEdgeInsets = UIEdgeInsets(top: SpicyTheme.Spacing.l,
                                                     left: SpicyTheme.Spacing.l,
                                                     bottom: SpicyTheme.Spacing.l,
                                                     right: SpicyTheme.Spacing.l),
                radius: CGFloat = SpicyTheme.Radius.l) {
        self.elevation = elevation
        super.init(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentConstraints = contentView.spicyPin(to: self, insets: padding)
        spicyApply(radius: radius)
        layer.borderWidth = SpicyTheme.Stroke.hairline
        applyStyle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public func setPadding(_ insets: UIEdgeInsets) {
        contentConstraints[0].constant = insets.top
        contentConstraints[1].constant = insets.left
        contentConstraints[2].constant = -insets.right
        contentConstraints[3].constant = -insets.bottom
    }

    private func applyStyle() {
        backgroundColor = elevation.fill
        layer.borderColor = SpicyTheme.Color.border.cgColor
        spicyApply(shadow: elevation.shadow)
    }

    public override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        applyStyle()
    }
}

/// Section heading used above a group of cards or rows.
public final class SpicySectionHeader: UIView {

    private let label = UILabel()

    public init(key: SpicyStringKey) {
        super.init(frame: .zero)
        label.font = SpicyTheme.Typography.captionEmphasised()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = SpicyTheme.Color.textTertiary
        label.numberOfLines = 0
        label.text = SpicyL10n.shared.string(key).uppercased(with: SpicyL10n.shared.current.locale)
        label.textAlignment = SpicyLayoutDirection.textAlignment(for: SpicyL10n.shared.current)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        label.spicyPin(to: self, insets: UIEdgeInsets(top: SpicyTheme.Spacing.l,
                                                      left: SpicyTheme.Spacing.xs,
                                                      bottom: SpicyTheme.Spacing.s,
                                                      right: SpicyTheme.Spacing.xs))
        isAccessibilityElement = true
        accessibilityTraits = .header
        accessibilityLabel = label.text
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}
#endif
