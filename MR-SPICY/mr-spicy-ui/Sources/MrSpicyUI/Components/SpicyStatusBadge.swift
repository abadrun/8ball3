//
//  SpicyStatusBadge.swift
//  MR. SPICY UI — compact status pill
//
//  MR. SPICY UI v1.0.0
//
//  A badge only ever renders a state that the host has actually supplied.
//  It has no opinion about, and no access to, entitlements or server state.
//

#if canImport(UIKit)
import UIKit

public final class SpicyStatusBadge: UIView {

    public enum Kind {
        case neutral
        case success
        case warning
        case danger
        case info

        var foreground: UIColor {
            switch self {
            case .neutral: return SpicyTheme.Color.textSecondary
            case .success: return SpicyTheme.Color.success
            case .warning: return SpicyTheme.Color.warning
            case .danger: return SpicyTheme.Color.danger
            case .info: return SpicyTheme.Color.info
            }
        }

        var background: UIColor {
            self == .neutral ? SpicyTheme.Color.neutralBadge
                             : foreground.withAlphaComponent(0.16)
        }
    }

    public var kind: Kind { didSet { applyStyle() } }

    private let label = UILabel()
    private let dot = UIView()

    public init(kind: Kind = .neutral, textKey: SpicyStringKey? = nil) {
        self.kind = kind
        super.init(frame: .zero)

        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.layer.cornerRadius = SpicyTheme.Radius.dot
        addSubview(dot)

        label.font = SpicyTheme.Typography.captionEmphasised()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: SpicyTheme.Size.badgeHeight),
            dot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: SpicyTheme.Spacing.s),
            dot.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: SpicyTheme.Radius.dot * 2),
            dot.heightAnchor.constraint(equalToConstant: SpicyTheme.Radius.dot * 2),
            label.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: SpicyTheme.Spacing.xs + 2),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -SpicyTheme.Spacing.s),
            label.topAnchor.constraint(equalTo: topAnchor, constant: SpicyTheme.Spacing.xxs),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -SpicyTheme.Spacing.xxs),
        ])

        if let textKey { setText(textKey) }
        applyStyle()
        isAccessibilityElement = true
        accessibilityTraits = .staticText
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerCurve = .continuous
        layer.cornerRadius = bounds.height / 2
    }

    public func setText(_ key: SpicyStringKey) {
        label.text = SpicyL10n.shared.string(key)
        accessibilityLabel = label.text
    }

    public func setRawText(_ text: String) {
        label.text = text
        accessibilityLabel = text
    }

    private func applyStyle() {
        backgroundColor = kind.background
        label.textColor = kind.foreground
        dot.backgroundColor = kind.foreground
    }

    public override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        applyStyle()
    }
}
#endif
