//
//  SpicyButton.swift
//  MR. SPICY UI — primary / secondary / ghost / destructive button
//
//  MR. SPICY UI v1.0.0
//

#if canImport(UIKit)
import UIKit

public final class SpicyButton: UIControl {

    public enum Style {
        case primary
        case secondary
        case ghost
        case destructive
    }

    public enum Size {
        case regular
        case compact

        var height: CGFloat {
            self == .regular ? SpicyTheme.Size.controlHeight
                             : SpicyTheme.Size.compactControlHeight
        }
    }

    // MARK: Public state

    public var style: Style { didSet { applyStyle() } }
    public var size: Size { didSet { heightConstraint?.constant = size.height } }

    public var titleKey: SpicyStringKey? {
        didSet { refreshText() }
    }

    public var isBusy: Bool = false {
        didSet {
            guard isBusy != oldValue else { return }
            spinner.isHidden = !isBusy
            isBusy ? spinner.startAnimating() : spinner.stopAnimating()
            titleLabel.alpha = isBusy ? 0 : 1
            iconView.alpha = isBusy ? 0 : 1
            isUserInteractionEnabled = !isBusy
            updateAccessibility()
        }
    }

    public override var isEnabled: Bool { didSet { applyStyle(); updateAccessibility() } }
    public override var isHighlighted: Bool {
        didSet {
            SpicyTheme.Motion.animate(SpicyTheme.Motion.fast) { [weak self] in
                guard let self else { return }
                self.alpha = self.isHighlighted ? SpicyTheme.Opacity.pressed : 1
                self.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            }
        }
    }

    // MARK: Subviews

    private let titleLabel = UILabel()
    private let iconView = UIImageView()
    private let stack = UIStackView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var heightConstraint: NSLayoutConstraint?
    private var languageObserver: NSObjectProtocol?

    // MARK: Init

    public init(style: Style = .primary,
                size: Size = .regular,
                titleKey: SpicyStringKey? = nil,
                icon: UIImage? = nil,
                mirrorsIconForRTL: Bool = false) {
        self.style = style
        self.size = size
        self.titleKey = titleKey
        super.init(frame: .zero)

        iconView.image = mirrorsIconForRTL
            ? SpicyLayoutDirection.directionalImage(icon) : icon
        iconView.contentMode = .scaleAspectFit
        iconView.isHidden = icon == nil
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.tintColor = SpicyTheme.Color.textOnPrimary

        titleLabel.font = SpicyTheme.Typography.button()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail

        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = SpicyTheme.Spacing.s
        stack.isUserInteractionEnabled = false
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        spinner.hidesWhenStopped = true
        spinner.isHidden = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)

        let h = heightAnchor.constraint(greaterThanOrEqualToConstant: size.height)
        h.priority = .required
        heightConstraint = h

        NSLayoutConstraint.activate([
            h,
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor,
                                           constant: SpicyTheme.Spacing.l),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor,
                                            constant: -SpicyTheme.Spacing.l),
            stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor,
                                       constant: SpicyTheme.Spacing.s),
            iconView.widthAnchor.constraint(equalToConstant: SpicyTheme.Size.iconS),
            iconView.heightAnchor.constraint(equalToConstant: SpicyTheme.Size.iconS),
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        spicyApply(radius: SpicyTheme.Radius.m)
        applyStyle()
        refreshText()
        isAccessibilityElement = true
        accessibilityTraits = .button

        languageObserver = NotificationCenter.default.addObserver(
            forName: SpicyL10n.languageDidChangeNotification,
            object: nil, queue: .main) { [weak self] _ in
                self?.refreshText()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    deinit {
        // Explicit observer removal – no retain cycle, no leaked observer.
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
    }

    // MARK: Styling

    public override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        if previous?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            applyStyle()
        }
    }

    private func applyStyle() {
        layer.borderWidth = 0
        switch style {
        case .primary:
            backgroundColor = isEnabled ? SpicyTheme.Color.primary
                                        : SpicyTheme.Color.controlFillDisabled
            titleLabel.textColor = isEnabled ? SpicyTheme.Color.textOnPrimary
                                             : SpicyTheme.Color.textDisabled
            spicyApply(shadow: isEnabled ? .level1 : .none)
        case .secondary:
            backgroundColor = SpicyTheme.Color.controlFill
            titleLabel.textColor = isEnabled ? SpicyTheme.Color.textPrimary
                                             : SpicyTheme.Color.textDisabled
            layer.borderWidth = SpicyTheme.Stroke.thin
            layer.borderColor = SpicyTheme.Color.border.cgColor
            spicyApply(shadow: .none)
        case .ghost:
            backgroundColor = .clear
            titleLabel.textColor = isEnabled ? SpicyTheme.Color.primaryTint
                                             : SpicyTheme.Color.textDisabled
            spicyApply(shadow: .none)
        case .destructive:
            backgroundColor = SpicyTheme.Color.danger.withAlphaComponent(0.16)
            titleLabel.textColor = SpicyTheme.Color.danger
            layer.borderWidth = SpicyTheme.Stroke.thin
            layer.borderColor = SpicyTheme.Color.danger.withAlphaComponent(0.5).cgColor
            spicyApply(shadow: .none)
        }
        iconView.tintColor = titleLabel.textColor
        spinner.color = titleLabel.textColor
        alpha = isEnabled ? 1 : SpicyTheme.Opacity.disabled + 0.4
    }

    private func refreshText() {
        guard let titleKey else { return }
        titleLabel.text = SpicyL10n.shared.string(titleKey)
        updateAccessibility()
    }

    private func updateAccessibility() {
        accessibilityLabel = titleLabel.text
        var traits: UIAccessibilityTraits = .button
        if !isEnabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
        accessibilityValue = isBusy ? SpicyStringKey.stateLoading.localized : nil
    }
}
#endif
