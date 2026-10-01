//
//  SpicyModalView.swift
//  MR. SPICY UI — the single modal system
//
//  MR. SPICY UI v1.0.0
//
//  One modal implementation serves every dialog in the layer: info,
//  confirmation, loading, success, error and custom content. There is no
//  second popup implementation anywhere in the package.
//

#if canImport(UIKit)
import UIKit

public final class SpicyModalView: UIView {

    // MARK: Configuration

    public struct Action {
        public let titleKey: SpicyStringKey
        public let style: SpicyButton.Style
        public let handler: () -> Void

        public init(titleKey: SpicyStringKey,
                    style: SpicyButton.Style = .primary,
                    handler: @escaping () -> Void) {
            self.titleKey = titleKey
            self.style = style
            self.handler = handler
        }
    }

    public enum Tone {
        case neutral
        case success
        case error
        case loading

        var accent: UIColor {
            switch self {
            case .neutral: return SpicyTheme.Color.primaryTint
            case .success: return SpicyTheme.Color.success
            case .error: return SpicyTheme.Color.danger
            case .loading: return SpicyTheme.Color.textSecondary
            }
        }
    }

    public struct Configuration {
        public var titleKey: SpicyStringKey
        public var messageKey: SpicyStringKey?
        public var rawMessage: String?
        public var systemImageName: String?
        public var tone: Tone
        public var primary: Action?
        public var secondary: Action?
        public var showsCloseButton: Bool
        public var customContent: UIView?
        public var isDismissableByScrim: Bool

        public init(titleKey: SpicyStringKey,
                    messageKey: SpicyStringKey? = nil,
                    rawMessage: String? = nil,
                    systemImageName: String? = nil,
                    tone: Tone = .neutral,
                    primary: Action? = nil,
                    secondary: Action? = nil,
                    showsCloseButton: Bool = true,
                    customContent: UIView? = nil,
                    isDismissableByScrim: Bool = true) {
            self.titleKey = titleKey
            self.messageKey = messageKey
            self.rawMessage = rawMessage
            self.systemImageName = systemImageName
            self.tone = tone
            self.primary = primary
            self.secondary = secondary
            self.showsCloseButton = showsCloseButton
            self.customContent = customContent
            self.isDismissableByScrim = isDismissableByScrim
        }
    }

    // MARK: Subviews

    private let scrim = UIView()
    private let card = SpicyCard(elevation: .floating,
                                 padding: UIEdgeInsets(top: SpicyTheme.Spacing.xl,
                                                       left: SpicyTheme.Spacing.xl,
                                                       bottom: SpicyTheme.Spacing.l,
                                                       right: SpicyTheme.Spacing.xl),
                                 radius: SpicyTheme.Radius.xl)
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let contentStack = UIStackView()
    private let actionStack = UIStackView()
    private let closeButton = UIButton(type: .system)

    private var configuration: Configuration
    private var onDismiss: (() -> Void)?

    // MARK: Init

    public init(configuration: Configuration) {
        self.configuration = configuration
        super.init(frame: .zero)
        buildHierarchy()
        apply(configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func buildHierarchy() {
        scrim.backgroundColor = SpicyTheme.Color.scrim
        scrim.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrim)
        scrim.spicyPin(to: self)
        scrim.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(scrimTapped)))
        scrim.isAccessibilityElement = false

        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: SpicyTheme.Size.iconL, weight: .semibold)
        iconView.setContentHuggingPriority(.required, for: .vertical)

        titleLabel.font = SpicyTheme.Typography.title()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = SpicyTheme.Color.textPrimary
        titleLabel.numberOfLines = 0

        messageLabel.font = SpicyTheme.Typography.body()
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = SpicyTheme.Color.textSecondary
        messageLabel.numberOfLines = 0

        spinner.hidesWhenStopped = true

        contentStack.axis = .vertical
        contentStack.spacing = SpicyTheme.Spacing.m
        contentStack.alignment = .fill
        [iconView, spinner, titleLabel, messageLabel].forEach(contentStack.addArrangedSubview)

        actionStack.axis = .vertical
        actionStack.spacing = SpicyTheme.Spacing.s
        actionStack.alignment = .fill
        contentStack.addArrangedSubview(actionStack)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        card.contentView.addSubview(contentStack)
        contentStack.spicyPin(to: card.contentView)

        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = SpicyTheme.Color.textTertiary
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.accessibilityLabel = SpicyStringKey.actionClose.localized
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(closeButton)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: centerXAnchor),
            card.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            card.widthAnchor.constraint(lessThanOrEqualToConstant: SpicyTheme.Size.modalMaxWidth),
            card.leadingAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.leadingAnchor,
                                          constant: SpicyTheme.Spacing.l),
            card.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor,
                                           constant: -SpicyTheme.Spacing.l),
            card.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor,
                                      constant: SpicyTheme.Spacing.l),
            card.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor,
                                         constant: -SpicyTheme.Spacing.l),

            closeButton.topAnchor.constraint(equalTo: card.topAnchor, constant: SpicyTheme.Spacing.s),
            closeButton.trailingAnchor.constraint(equalTo: card.trailingAnchor,
                                                  constant: -SpicyTheme.Spacing.s),
            closeButton.widthAnchor.constraint(equalToConstant: SpicyTheme.Size.minimumTouchTarget),
            closeButton.heightAnchor.constraint(equalToConstant: SpicyTheme.Size.minimumTouchTarget),
        ])

        // The card is a modal container for VoiceOver: focus is trapped inside.
        card.accessibilityViewIsModal = true
    }

    // MARK: Apply

    public func apply(_ configuration: Configuration) {
        self.configuration = configuration
        let l10n = SpicyL10n.shared
        let alignment = SpicyLayoutDirection.textAlignment(for: l10n.current)

        titleLabel.text = l10n.string(configuration.titleKey)
        titleLabel.textAlignment = alignment

        if let raw = configuration.rawMessage {
            messageLabel.text = raw
        } else if let key = configuration.messageKey {
            messageLabel.text = l10n.string(key)
        } else {
            messageLabel.text = nil
        }
        messageLabel.textAlignment = alignment
        messageLabel.isHidden = messageLabel.text == nil

        if let name = configuration.systemImageName {
            iconView.image = UIImage(systemName: name)
            iconView.tintColor = configuration.tone.accent
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
        }

        if case .loading = configuration.tone {
            spinner.startAnimating()
            spinner.isHidden = false
        } else {
            spinner.stopAnimating()
            spinner.isHidden = true
        }

        actionStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let primary = configuration.primary {
            actionStack.addArrangedSubview(makeButton(primary))
        }
        if let secondary = configuration.secondary {
            actionStack.addArrangedSubview(makeButton(secondary))
        }
        actionStack.isHidden = actionStack.arrangedSubviews.isEmpty

        if let custom = configuration.customContent {
            contentStack.insertArrangedSubview(custom, at: contentStack.arrangedSubviews.count - 1)
        }

        closeButton.isHidden = !configuration.showsCloseButton

        SpicyLayoutDirection.apply(l10n.current, to: self)
        card.accessibilityLabel = "\(titleLabel.text ?? ""). \(messageLabel.text ?? "")"
    }

    private func makeButton(_ action: Action) -> SpicyButton {
        let button = SpicyButton(style: action.style, titleKey: action.titleKey)
        button.addAction(UIAction { [weak self] _ in
            action.handler()
            self?.dismiss()
        }, for: .touchUpInside)
        return button
    }

    // MARK: Presentation

    /// Presents the modal inside `container`, filling it.
    public func present(in container: UIView, onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
        translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(self)
        spicyPin(to: container)
        container.layoutIfNeeded()

        scrim.alpha = 0
        card.alpha = 0
        card.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            .translatedBy(x: 0, y: 12)
        SpicyTheme.Motion.animate(SpicyTheme.Motion.standard) { [weak self] in
            self?.scrim.alpha = 1
            self?.card.alpha = 1
            self?.card.transform = .identity
        }
        UIAccessibility.post(notification: .screenChanged, argument: card)
    }

    public func dismiss() {
        SpicyTheme.Motion.animate(SpicyTheme.Motion.fast, animations: { [weak self] in
            self?.scrim.alpha = 0
            self?.card.alpha = 0
            self?.card.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }, completion: { [weak self] _ in
            guard let self else { return }
            self.removeFromSuperview()
            self.onDismiss?()
            self.onDismiss = nil
        })
    }

    @objc private func scrimTapped() {
        guard configuration.isDismissableByScrim else { return }
        dismiss()
    }

    @objc private func closeTapped() { dismiss() }
}

// MARK: - Ready-made configurations

public extension SpicyModalView.Configuration {

    static func info(titleKey: SpicyStringKey,
                     messageKey: SpicyStringKey,
                     dismissKey: SpicyStringKey = .actionOK) -> Self {
        .init(titleKey: titleKey,
              messageKey: messageKey,
              systemImageName: "info.circle",
              tone: .neutral,
              primary: .init(titleKey: dismissKey, style: .primary, handler: {}))
    }

    static func confirmation(titleKey: SpicyStringKey,
                             messageKey: SpicyStringKey,
                             confirmKey: SpicyStringKey,
                             confirmStyle: SpicyButton.Style = .destructive,
                             onConfirm: @escaping () -> Void) -> Self {
        .init(titleKey: titleKey,
              messageKey: messageKey,
              systemImageName: "exclamationmark.triangle",
              tone: .neutral,
              primary: .init(titleKey: confirmKey, style: confirmStyle, handler: onConfirm),
              secondary: .init(titleKey: .actionCancel, style: .secondary, handler: {}))
    }

    static func loading(titleKey: SpicyStringKey = .stateLoading) -> Self {
        .init(titleKey: titleKey,
              tone: .loading,
              showsCloseButton: false,
              isDismissableByScrim: false)
    }

    static func error(messageKey: SpicyStringKey = .stateError,
                      retry: (() -> Void)? = nil) -> Self {
        .init(titleKey: .stateError,
              messageKey: messageKey,
              systemImageName: "xmark.octagon",
              tone: .error,
              primary: retry.map { .init(titleKey: .actionRetry, style: .primary, handler: $0) },
              secondary: .init(titleKey: .actionClose, style: .secondary, handler: {}))
    }

    static func success(titleKey: SpicyStringKey = .stateSuccess,
                        messageKey: SpicyStringKey? = nil) -> Self {
        .init(titleKey: titleKey,
              messageKey: messageKey,
              systemImageName: "checkmark.circle",
              tone: .success,
              primary: .init(titleKey: .actionDone, style: .primary, handler: {}))
    }
}
#endif
