//
//  SpicyHeaderView.swift
//  MR. SPICY UI — branded panel header
//
//  MR. SPICY UI v1.0.0
//
//  Layout is built entirely from leading/trailing anchors, so the header
//  mirrors automatically in Arabic: brand mark moves to the trailing edge and
//  the control cluster moves to the leading edge.
//

#if canImport(UIKit)
import UIKit

public protocol SpicyHeaderViewDelegate: AnyObject {
    func spicyHeaderDidTapSettings(_ header: SpicyHeaderView)
    func spicyHeaderDidTapMinimise(_ header: SpicyHeaderView)
    func spicyHeaderDidTapClose(_ header: SpicyHeaderView)
}

public final class SpicyHeaderView: UIView {

    public weak var delegate: SpicyHeaderViewDelegate?

    public struct Configuration {
        public var showsSettings: Bool
        public var showsMinimise: Bool
        public var showsClose: Bool
        public var showsStatusBadge: Bool
        public var logo: UIImage?

        public init(showsSettings: Bool = true,
                    showsMinimise: Bool = true,
                    showsClose: Bool = true,
                    showsStatusBadge: Bool = false,
                    logo: UIImage? = SpicyBrand.logo()) {
            self.showsSettings = showsSettings
            self.showsMinimise = showsMinimise
            self.showsClose = showsClose
            self.showsStatusBadge = showsStatusBadge
            self.logo = logo
        }
    }

    // MARK: Subviews

    private let logoView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textStack = UIStackView()
    private let controlStack = UIStackView()
    private let separator = UIView()
    public let statusBadge = SpicyStatusBadge(kind: .neutral)

    private lazy var settingsButton = makeIconButton(
        systemName: "gearshape", key: .headerSettings,
        action: #selector(settingsTapped), mirrors: false)
    private lazy var minimiseButton = makeIconButton(
        systemName: "minus", key: .headerMinimise,
        action: #selector(minimiseTapped), mirrors: false)
    private lazy var closeButton = makeIconButton(
        systemName: "xmark", key: .headerClose,
        action: #selector(closeTapped), mirrors: false)

    private var languageObserver: NSObjectProtocol?

    // MARK: Init

    public init(configuration: Configuration = Configuration()) {
        super.init(frame: .zero)
        backgroundColor = SpicyTheme.Color.surfaceElevated

        logoView.image = configuration.logo
        logoView.contentMode = .scaleAspectFit
        logoView.spicyApply(radius: SpicyTheme.Radius.xs)
        logoView.clipsToBounds = true
        logoView.isAccessibilityElement = false

        titleLabel.font = SpicyTheme.Typography.title()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = SpicyTheme.Color.textPrimary
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        subtitleLabel.font = SpicyTheme.Typography.caption()
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = SpicyTheme.Color.textSecondary
        subtitleLabel.numberOfLines = 1

        textStack.axis = .vertical
        textStack.spacing = SpicyTheme.Spacing.xxs
        textStack.alignment = .fill
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        controlStack.axis = .horizontal
        controlStack.spacing = SpicyTheme.Spacing.xs
        controlStack.alignment = .center
        if configuration.showsSettings { controlStack.addArrangedSubview(settingsButton) }
        if configuration.showsMinimise { controlStack.addArrangedSubview(minimiseButton) }
        if configuration.showsClose { controlStack.addArrangedSubview(closeButton) }
        controlStack.setContentHuggingPriority(.required, for: .horizontal)
        controlStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        statusBadge.isHidden = !configuration.showsStatusBadge

        separator.backgroundColor = SpicyTheme.Color.separator

        [logoView, textStack, statusBadge, controlStack, separator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: SpicyTheme.Size.headerHeight),

            logoView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                              constant: SpicyTheme.Spacing.l),
            logoView.centerYAnchor.constraint(equalTo: centerYAnchor),
            logoView.widthAnchor.constraint(equalToConstant: SpicyTheme.Size.iconL),
            logoView.heightAnchor.constraint(equalToConstant: SpicyTheme.Size.iconL),

            textStack.leadingAnchor.constraint(equalTo: logoView.trailingAnchor,
                                               constant: SpicyTheme.Spacing.m),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor,
                                           constant: SpicyTheme.Spacing.s),

            statusBadge.leadingAnchor.constraint(equalTo: textStack.trailingAnchor,
                                                 constant: SpicyTheme.Spacing.s),
            statusBadge.centerYAnchor.constraint(equalTo: centerYAnchor),

            controlStack.leadingAnchor.constraint(greaterThanOrEqualTo: statusBadge.trailingAnchor,
                                                  constant: SpicyTheme.Spacing.s),
            controlStack.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                   constant: -SpicyTheme.Spacing.m),
            controlStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: SpicyTheme.Stroke.hairline),
        ])

        refreshText()
        languageObserver = NotificationCenter.default.addObserver(
            forName: SpicyL10n.languageDidChangeNotification,
            object: nil, queue: .main) { [weak self] _ in
                self?.refreshText()
        }

        // VoiceOver reads the brand + title as one element, then the controls.
        accessibilityElements = [textStack, statusBadge, controlStack]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    deinit {
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
    }

    // MARK: Public API

    public func setSubtitleHidden(_ hidden: Bool) {
        subtitleLabel.isHidden = hidden
    }

    // MARK: Internals

    private func refreshText() {
        titleLabel.text = SpicyStringKey.headerTitle.localized
        subtitleLabel.text = SpicyStringKey.headerSubtitle.localized
        let alignment = SpicyLayoutDirection.textAlignment(for: SpicyL10n.shared.current)
        titleLabel.textAlignment = alignment
        subtitleLabel.textAlignment = alignment
        textStack.accessibilityLabel = "\(titleLabel.text ?? ""), \(subtitleLabel.text ?? "")"
        textStack.isAccessibilityElement = true
        textStack.accessibilityTraits = .header
        settingsButton.accessibilityLabel = SpicyStringKey.headerSettings.localized
        minimiseButton.accessibilityLabel = SpicyStringKey.headerMinimise.localized
        closeButton.accessibilityLabel = SpicyStringKey.headerClose.localized
    }

    private func makeIconButton(systemName: String,
                                key: SpicyStringKey,
                                action: Selector,
                                mirrors: Bool) -> UIButton {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: systemName)
        button.setImage(mirrors ? SpicyLayoutDirection.directionalImage(image) : image,
                        for: .normal)
        button.tintColor = SpicyTheme.Color.textSecondary
        button.backgroundColor = SpicyTheme.Color.controlFill
        button.spicyApply(radius: SpicyTheme.Radius.s)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.accessibilityLabel = key.localized
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: SpicyTheme.Size.minimumTouchTarget - 8),
            button.heightAnchor.constraint(equalToConstant: SpicyTheme.Size.minimumTouchTarget - 8),
        ])
        // Visual size is 36 pt; the extra touch slop keeps the 44 pt target.
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return button
    }

    @objc private func settingsTapped() { delegate?.spicyHeaderDidTapSettings(self) }
    @objc private func minimiseTapped() { delegate?.spicyHeaderDidTapMinimise(self) }
    @objc private func closeTapped() { delegate?.spicyHeaderDidTapClose(self) }
}
#endif
