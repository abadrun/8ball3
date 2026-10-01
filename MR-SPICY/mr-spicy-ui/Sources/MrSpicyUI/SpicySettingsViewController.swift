//
//  SpicySettingsViewController.swift
//  MR. SPICY UI — settings surface
//
//  MR. SPICY UI v1.0.0
//
//  Every row here maps to a real, verifiable state:
//    * Language           — owned by `SpicyL10n`
//    * Appearance         — owned by `UIUserInterfaceStyle` on the container
//    * Reduce Motion      — read-only mirror of the iOS accessibility setting
//    * Larger Text        — read-only mirror of the Dynamic Type setting
//    * Version / about    — static facts about the UI layer
//
//  No row claims to control behaviour that the UI layer does not actually own.
//  Read-only rows are rendered as `.informational` and are not interactive.
//

#if canImport(UIKit)
import UIKit

public final class SpicySettingsViewController: UIViewController {

    public var onClose: (() -> Void)?

    /// Host-owned appearance preference. The UI layer applies it to its own
    /// view tree only; it never changes the host's global appearance.
    public enum Appearance: String, CaseIterable {
        case system, dark, light

        var style: UIUserInterfaceStyle {
            switch self {
            case .system: return .unspecified
            case .dark: return .dark
            case .light: return .light
            }
        }

        var titleKey: SpicyStringKey {
            switch self {
            case .system: return .settingsAppearanceSystem
            case .dark: return .settingsAppearanceDark
            case .light: return .settingsAppearanceLight
            }
        }
    }

    public private(set) var appearance: Appearance = .system {
        didSet {
            view.window?.overrideUserInterfaceStyle = appearance.style
            view.overrideUserInterfaceStyle = appearance.style
        }
    }

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let header = SpicyHeaderView(configuration: .init(showsSettings: false,
                                                              showsMinimise: false,
                                                              showsClose: true,
                                                              showsStatusBadge: false))
    private var languageObserver: NSObjectProtocol?
    private var contentSizeObserver: NSObjectProtocol?

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SpicyTheme.Color.background

        header.delegate = self
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = SpicyTheme.Spacing.s
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                                          constant: -SpicyTheme.Spacing.xxl),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                                           constant: SpicyTheme.Spacing.l),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                                            constant: -SpicyTheme.Spacing.l),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor,
                                         constant: -2 * SpicyTheme.Spacing.l),
        ])

        rebuild()

        languageObserver = NotificationCenter.default.addObserver(
            forName: SpicyL10n.languageDidChangeNotification,
            object: nil, queue: .main) { [weak self] _ in
                guard let self else { return }
                SpicyLayoutDirection.apply(SpicyL10n.shared.current, to: self.view)
                self.rebuild()
                UIAccessibility.post(notification: .announcement,
                                     argument: SpicyStringKey.languageChanged.localized)
        }

        // Accessibility mirrors must refresh when the user changes system
        // settings while the panel is open.
        contentSizeObserver = NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil, queue: .main) { [weak self] _ in
                self?.rebuild()
        }

        SpicyLayoutDirection.apply(SpicyL10n.shared.current, to: view)
    }

    deinit {
        [languageObserver, contentSizeObserver].compactMap { $0 }.forEach {
            NotificationCenter.default.removeObserver($0)
        }
    }

    // MARK: Build

    private func rebuild() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // General -----------------------------------------------------------
        stack.addArrangedSubview(SpicySectionHeader(key: .settingsSectionGeneral))
        let general = SpicySettingGroup(models: [
            .init(id: "language",
                  titleKey: .settingsLanguage,
                  subtitleKey: .settingsLanguageHint,
                  systemImageName: "globe",
                  accessory: .value(SpicyL10n.shared.current.endonym)),
        ])
        general.onSelect = { [weak self] model in
            guard model.id == "language" else { return }
            self?.presentLanguagePicker()
        }
        stack.addArrangedSubview(general)

        // Appearance ---------------------------------------------------------
        stack.addArrangedSubview(SpicySectionHeader(key: .settingsSectionAppearance))
        let appearanceGroup = SpicySettingGroup(models: [
            .init(id: "appearance",
                  titleKey: .settingsAppearance,
                  systemImageName: "circle.lefthalf.filled",
                  accessory: .value(SpicyL10n.shared.string(appearance.titleKey))),
        ])
        appearanceGroup.onSelect = { [weak self] _ in self?.presentAppearancePicker() }
        stack.addArrangedSubview(appearanceGroup)

        // Accessibility (read-only mirrors of iOS settings) --------------------
        stack.addArrangedSubview(SpicySectionHeader(key: .settingsSectionAccessibility))
        stack.addArrangedSubview(SpicySettingGroup(models: [
            .init(id: "reduce-motion",
                  titleKey: .settingsReduceMotion,
                  subtitleKey: .settingsReduceMotionHint,
                  systemImageName: "figure.walk.motion",
                  accessory: .informational(
                      UIAccessibility.isReduceMotionEnabled
                        ? SpicyStringKey.stateOn.localized
                        : SpicyStringKey.stateOff.localized)),
            .init(id: "larger-text",
                  titleKey: .settingsLargerText,
                  subtitleKey: .settingsLargerTextHint,
                  systemImageName: "textformat.size",
                  accessory: .informational(
                      traitCollection.preferredContentSizeCategory.rawValue
                        .replacingOccurrences(of: "UICTContentSizeCategory", with: ""))),
        ]))

        // About -----------------------------------------------------------------
        stack.addArrangedSubview(SpicySectionHeader(key: .settingsSectionAbout))
        stack.addArrangedSubview(SpicySettingGroup(models: [
            .init(id: "version",
                  titleKey: .settingsVersion,
                  systemImageName: "number",
                  accessory: .informational(SpicyBrand.uiLayerVersion)),
            .init(id: "design-system",
                  titleKey: .aboutDesignSystem,
                  systemImageName: "paintpalette",
                  accessory: .informational("MR. SPICY")),
        ]))
    }

    // MARK: Pickers (single modal system)

    private func presentLanguagePicker() {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = SpicyTheme.Spacing.s
        for language in SpicyLanguage.allCases {
            let button = SpicyButton(
                style: language == SpicyL10n.shared.current ? .primary : .secondary,
                titleKey: language == .english ? .languageEnglish : .languageArabic)
            button.addAction(UIAction { [weak self] _ in
                SpicyL10n.shared.setLanguage(language)
                self?.dismissModal()
            }, for: .touchUpInside)
            container.addArrangedSubview(button)
        }
        presentModal(.init(titleKey: .languageTitle,
                           messageKey: .settingsLanguageHint,
                           systemImageName: "globe",
                           customContent: container))
    }

    private func presentAppearancePicker() {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = SpicyTheme.Spacing.s
        for option in Appearance.allCases {
            let button = SpicyButton(style: option == appearance ? .primary : .secondary,
                                     titleKey: option.titleKey)
            button.addAction(UIAction { [weak self] _ in
                self?.appearance = option
                self?.rebuild()
                self?.dismissModal()
            }, for: .touchUpInside)
            container.addArrangedSubview(button)
        }
        presentModal(.init(titleKey: .settingsAppearance,
                           systemImageName: "circle.lefthalf.filled",
                           customContent: container))
    }

    private var modal: SpicyModalView?

    private func presentModal(_ configuration: SpicyModalView.Configuration) {
        modal?.dismiss()
        let modal = SpicyModalView(configuration: configuration)
        self.modal = modal
        modal.present(in: view) { [weak self] in self?.modal = nil }
    }

    private func dismissModal() {
        modal?.dismiss()
    }
}

extension SpicySettingsViewController: SpicyHeaderViewDelegate {
    public func spicyHeaderDidTapSettings(_ header: SpicyHeaderView) {}
    public func spicyHeaderDidTapMinimise(_ header: SpicyHeaderView) {}
    public func spicyHeaderDidTapClose(_ header: SpicyHeaderView) { onClose?() }
}
#endif
