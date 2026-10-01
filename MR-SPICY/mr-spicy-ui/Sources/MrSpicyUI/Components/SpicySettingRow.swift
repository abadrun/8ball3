//
//  SpicySettingRow.swift
//  MR. SPICY UI — settings row primitives
//
//  MR. SPICY UI v1.0.0
//
//  Four row kinds cover every settings surface in the layer:
//  toggle, value, disclosure and informational. Rows switch to a stacked
//  layout automatically at accessibility text sizes so nothing is clipped.
//

#if canImport(UIKit)
import UIKit

public final class SpicySettingRow: UIControl {

    public enum Accessory {
        /// A real, host-backed boolean preference.
        case toggle(isOn: Bool, onChange: (Bool) -> Void)
        /// A value the user can change on another surface.
        case value(String)
        /// Navigates to another MR. SPICY surface.
        case disclosure
        /// Read-only information (version numbers, credits, …).
        case informational(String)
        case none
    }

    public struct Model {
        public let id: String
        public let titleKey: SpicyStringKey
        public let subtitleKey: SpicyStringKey?
        public let systemImageName: String?
        public var accessory: Accessory
        public var isEnabled: Bool

        public init(id: String,
                    titleKey: SpicyStringKey,
                    subtitleKey: SpicyStringKey? = nil,
                    systemImageName: String? = nil,
                    accessory: Accessory = .none,
                    isEnabled: Bool = true) {
            self.id = id
            self.titleKey = titleKey
            self.subtitleKey = subtitleKey
            self.systemImageName = systemImageName
            self.accessory = accessory
            self.isEnabled = isEnabled
        }
    }

    public private(set) var model: Model
    public var onSelect: ((Model) -> Void)?

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let valueLabel = UILabel()
    private let chevron = UIImageView()
    private let toggle = UISwitch()
    private let textStack = UIStackView()
    private let rootStack = UIStackView()
    private var toggleHandler: ((Bool) -> Void)?

    public init(model: Model) {
        self.model = model
        super.init(frame: .zero)

        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: SpicyTheme.Size.iconS, weight: .medium)
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.tintColor = SpicyTheme.Color.textSecondary

        titleLabel.font = SpicyTheme.Typography.body()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = SpicyTheme.Color.textPrimary
        titleLabel.numberOfLines = 0

        subtitleLabel.font = SpicyTheme.Typography.caption()
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = SpicyTheme.Color.textTertiary
        subtitleLabel.numberOfLines = 0

        valueLabel.font = SpicyTheme.Typography.callout()
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.textColor = SpicyTheme.Color.textSecondary
        valueLabel.numberOfLines = 1
        valueLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        chevron.image = SpicyLayoutDirection.directionalImage(
            UIImage(systemName: "chevron.right"))
        chevron.tintColor = SpicyTheme.Color.textTertiary
        chevron.contentMode = .scaleAspectFit
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        toggle.onTintColor = SpicyTheme.Color.primary
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)

        textStack.axis = .vertical
        textStack.spacing = SpicyTheme.Spacing.xxs
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        rootStack.axis = .horizontal
        rootStack.alignment = .center
        rootStack.spacing = SpicyTheme.Spacing.m
        rootStack.isUserInteractionEnabled = true
        [iconView, textStack, valueLabel, toggle, chevron].forEach(rootStack.addArrangedSubview)
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rootStack)
        rootStack.spicyPin(to: self, insets: UIEdgeInsets(top: SpicyTheme.Spacing.m,
                                                          left: SpicyTheme.Spacing.l,
                                                          bottom: SpicyTheme.Spacing.m,
                                                          right: SpicyTheme.Spacing.l))

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: SpicyTheme.Size.minimumTouchTarget),
            iconView.widthAnchor.constraint(equalToConstant: SpicyTheme.Size.iconM),
            chevron.widthAnchor.constraint(equalToConstant: SpicyTheme.Size.iconXS),
        ])

        addTarget(self, action: #selector(rowTapped), for: .touchUpInside)
        apply(model: model)
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: Apply

    public func apply(model: Model) {
        self.model = model
        let l10n = SpicyL10n.shared
        titleLabel.text = l10n.string(model.titleKey)
        subtitleLabel.text = model.subtitleKey.map { l10n.string($0) }
        subtitleLabel.isHidden = subtitleLabel.text == nil

        let alignment = SpicyLayoutDirection.textAlignment(for: l10n.current)
        titleLabel.textAlignment = alignment
        subtitleLabel.textAlignment = alignment

        if let name = model.systemImageName {
            iconView.image = UIImage(systemName: name)
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
        }

        toggle.isHidden = true
        chevron.isHidden = true
        valueLabel.isHidden = true
        toggleHandler = nil

        switch model.accessory {
        case .toggle(let isOn, let onChange):
            toggle.isHidden = false
            toggle.setOn(isOn, animated: false)
            toggleHandler = onChange
            accessibilityTraits = model.isEnabled ? .button : [.button, .notEnabled]
            accessibilityValue = isOn ? SpicyStringKey.stateOn.localized
                                      : SpicyStringKey.stateOff.localized
        case .value(let text):
            valueLabel.isHidden = false
            valueLabel.text = text
            chevron.isHidden = false
            accessibilityTraits = .button
            accessibilityValue = text
        case .disclosure:
            chevron.isHidden = false
            accessibilityTraits = .button
            accessibilityValue = nil
        case .informational(let text):
            valueLabel.isHidden = false
            valueLabel.text = text
            accessibilityTraits = .staticText
            accessibilityValue = text
        case .none:
            accessibilityTraits = .staticText
            accessibilityValue = nil
        }

        isEnabled = model.isEnabled
        toggle.isEnabled = model.isEnabled
        alpha = model.isEnabled ? 1 : SpicyTheme.Opacity.disabled + 0.4
        accessibilityLabel = [titleLabel.text, subtitleLabel.text]
            .compactMap { $0 }.joined(separator: ", ")
        if case .disclosure = model.accessory {
            accessibilityHint = SpicyStringKey.a11yRowHint.localized
        }
        updateAxisForContentSize()
    }

    public override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        if previous?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            updateAxisForContentSize()
        }
    }

    /// Switches to a vertical layout at accessibility text sizes — this is what
    /// prevents clipped titles and unreachable switches at large Dynamic Type.
    private func updateAxisForContentSize() {
        let stacked = traitCollection.preferredContentSizeCategory
            >= SpicyTheme.Typography.stackedLayoutThreshold
        rootStack.axis = stacked ? .vertical : .horizontal
        rootStack.alignment = stacked ? .leading : .center
    }

    public override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? SpicyTheme.Color.controlFill : .clear
        }
    }

    @objc private func rowTapped() {
        guard model.isEnabled else { return }
        if case .toggle = model.accessory {
            toggle.setOn(!toggle.isOn, animated: true)
            toggleChanged()
            return
        }
        onSelect?(model)
    }

    @objc private func toggleChanged() {
        toggleHandler?(toggle.isOn)
        accessibilityValue = toggle.isOn ? SpicyStringKey.stateOn.localized
                                         : SpicyStringKey.stateOff.localized
        UIAccessibility.post(notification: .announcement, argument: accessibilityValue)
    }
}

/// Vertical group of rows inside a single card, with hairline separators.
public final class SpicySettingGroup: UIView {

    private let card = SpicyCard(elevation: .raised, padding: .zero, radius: SpicyTheme.Radius.l)
    private let stack = UIStackView()
    private var rows: [SpicySettingRow] = []

    public var onSelect: ((SpicySettingRow.Model) -> Void)?

    public init(models: [SpicySettingRow.Model]) {
        super.init(frame: .zero)
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.contentView.addSubview(stack)
        stack.spicyPin(to: card.contentView)
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)
        card.spicyPin(to: self)
        setModels(models)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public func setModels(_ models: [SpicySettingRow.Model]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        rows = []
        for (index, model) in models.enumerated() {
            let row = SpicySettingRow(model: model)
            row.onSelect = { [weak self] in self?.onSelect?($0) }
            rows.append(row)
            stack.addArrangedSubview(row)
            if index < models.count - 1 {
                let separator = UIView()
                separator.backgroundColor = SpicyTheme.Color.separator
                separator.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    separator.heightAnchor.constraint(equalToConstant: SpicyTheme.Stroke.hairline),
                ])
                stack.addArrangedSubview(separator)
            }
        }
    }

    public func updateRow(id: String, transform: (inout SpicySettingRow.Model) -> Void) {
        guard let row = rows.first(where: { $0.model.id == id }) else { return }
        var model = row.model
        transform(&model)
        row.apply(model: model)
    }
}
#endif
