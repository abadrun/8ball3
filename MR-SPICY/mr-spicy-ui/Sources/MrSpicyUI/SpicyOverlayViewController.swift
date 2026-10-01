//
//  SpicyOverlayViewController.swift
//  MR. SPICY UI — overlay container
//
//  MR. SPICY UI v1.0.0
//
//  The container owns:
//    * the state machine (`SpicyStateMachine`)
//    * the header, the tile grid and the single modal system
//    * layout direction, safe-area insets and responsive metrics
//
//  It knows nothing about any host application. Everything host-specific is
//  supplied by the embedder through `SpicyOverlayDataSource` /
//  `SpicyOverlayDelegate`, which is the single integration boundary.
//

#if canImport(UIKit)
import UIKit

// MARK: - Integration boundary

public protocol SpicyOverlayDataSource: AnyObject {
    /// Tiles to show. The host decides which UI surfaces exist and whether
    /// each one is enabled; the UI layer never invents state.
    func spicyOverlayTiles(_ controller: SpicyOverlayViewController) -> [SpicyFeatureTile.Model]
    /// Optional status shown in the header (e.g. "Connected").
    func spicyOverlayStatus(_ controller: SpicyOverlayViewController)
        -> (text: String, kind: SpicyStatusBadge.Kind)?
}

public protocol SpicyOverlayDelegate: AnyObject {
    func spicyOverlay(_ controller: SpicyOverlayViewController,
                      didSelectTile model: SpicyFeatureTile.Model)
    func spicyOverlay(_ controller: SpicyOverlayViewController,
                      didChangeState state: SpicyPresentationState)
    func spicyOverlay(_ controller: SpicyOverlayViewController,
                      didChangeLanguage language: SpicyLanguage)
}

public extension SpicyOverlayDelegate {
    func spicyOverlay(_ controller: SpicyOverlayViewController,
                      didChangeState state: SpicyPresentationState) {}
    func spicyOverlay(_ controller: SpicyOverlayViewController,
                      didChangeLanguage language: SpicyLanguage) {}
}

// MARK: - Controller

public final class SpicyOverlayViewController: UIViewController {

    public weak var dataSource: SpicyOverlayDataSource?
    public weak var delegate: SpicyOverlayDelegate?

    public private(set) var machine = SpicyStateMachine()

    // MARK: Views

    private let panel = SpicyCard(elevation: .floating, padding: .zero, radius: SpicyTheme.Radius.xl)
    private let header: SpicyHeaderView
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let tileGrid = SpicyFeatureTileGrid()
    private var currentModal: SpicyModalView?
    private var settingsController: SpicySettingsViewController?
    private var languageObserver: NSObjectProtocol?
    private var panelWidthConstraint: NSLayoutConstraint?

    // MARK: Init

    public init(headerConfiguration: SpicyHeaderView.Configuration = .init()) {
        self.header = SpicyHeaderView(configuration: headerConfiguration)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    deinit {
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
    }

    // MARK: Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)

        header.delegate = self
        header.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView.addSubview(header)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        panel.contentView.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = SpicyTheme.Spacing.l
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        contentStack.addArrangedSubview(tileGrid)

        let widthConstraint = panel.widthAnchor.constraint(
            lessThanOrEqualToConstant: SpicyTheme.Size.overlayMaxWidth)
        panelWidthConstraint = widthConstraint

        NSLayoutConstraint.activate([
            panel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            panel.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor,
                                       constant: SpicyTheme.Spacing.m),
            panel.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -SpicyTheme.Spacing.m),
            panel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            panel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor,
                                           constant: SpicyTheme.Spacing.m),
            panel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor,
                                            constant: -SpicyTheme.Spacing.m),
            widthConstraint,

            header.topAnchor.constraint(equalTo: panel.contentView.topAnchor),
            header.leadingAnchor.constraint(equalTo: panel.contentView.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: panel.contentView.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: panel.contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: panel.contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: panel.contentView.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor,
                                              constant: SpicyTheme.Spacing.l),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                                                 constant: -SpicyTheme.Spacing.l),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                                                  constant: SpicyTheme.Spacing.l),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                                                   constant: -SpicyTheme.Spacing.l),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor,
                                                constant: -2 * SpicyTheme.Spacing.l),
        ])

        tileGrid.onSelect = { [weak self] model in
            guard let self else { return }
            self.delegate?.spicyOverlay(self, didSelectTile: model)
        }

        panel.spicyApply(shadow: .level3)
        applyLanguage(SpicyL10n.shared.current)

        languageObserver = NotificationCenter.default.addObserver(
            forName: SpicyL10n.languageDidChangeNotification,
            object: nil, queue: .main) { [weak self] _ in
                guard let self else { return }
                self.applyLanguage(SpicyL10n.shared.current)
                self.reload()
                self.delegate?.spicyOverlay(self, didChangeLanguage: SpicyL10n.shared.current)
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutTilesIfNeeded()
    }

    public override func viewWillTransition(to size: CGSize,
                                            with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.layoutTilesIfNeeded(for: size)
        })
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        SpicyBrand.purgeCaches()
    }

    // MARK: Public API

    /// Reloads tiles and header status from the data source.
    public func reload() {
        let tiles = dataSource?.spicyOverlayTiles(self) ?? []
        let metrics = currentMetrics()
        tileGrid.setModels(tiles, columns: metrics.tileColumns(availableWidth: view.bounds.width))

        if let status = dataSource?.spicyOverlayStatus(self) {
            header.statusBadge.isHidden = false
            header.statusBadge.kind = status.kind
            header.statusBadge.setRawText(status.text)
        } else {
            header.statusBadge.isHidden = true
        }
    }

    @discardableResult
    public func send(_ event: SpicyEvent) -> SpicyPresentationState {
        let previous = machine.presentation
        let next = machine.send(event)
        guard next != previous else { return next }
        applyPresentationState(next)
        delegate?.spicyOverlay(self, didChangeState: next)
        return next
    }

    /// Presents a modal using the single MR. SPICY modal system.
    public func presentModal(_ configuration: SpicyModalView.Configuration,
                             kind: SpicyModalKind = .info) {
        currentModal?.dismiss()
        let modal = SpicyModalView(configuration: configuration)
        currentModal = modal
        send(.present(kind))
        modal.present(in: view) { [weak self] in
            guard let self else { return }
            self.currentModal = nil
            self.send(.dismissModal)
        }
    }

    public func presentSettings(_ controller: SpicySettingsViewController) {
        settingsController = controller
        addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        controller.view.spicyPin(to: view)
        controller.didMove(toParent: self)
        controller.onClose = { [weak self] in self?.dismissSettings() }
        send(.openSettings)

        controller.view.alpha = 0
        SpicyTheme.Motion.animate { controller.view.alpha = 1 }
        UIAccessibility.post(notification: .screenChanged, argument: controller.view)
    }

    public func dismissSettings() {
        guard let controller = settingsController else { return }
        SpicyTheme.Motion.animate(SpicyTheme.Motion.fast, animations: {
            controller.view.alpha = 0
        }, completion: { [weak self] _ in
            controller.willMove(toParent: nil)
            controller.view.removeFromSuperview()
            controller.removeFromParent()
            self?.settingsController = nil
            self?.send(.closeSettings)
            UIAccessibility.post(notification: .screenChanged, argument: self?.panel)
        })
    }

    // MARK: Internals

    private func currentMetrics() -> SpicyLayoutMetrics {
        SpicyLayoutMetrics(traitCollection: traitCollection,
                           size: view.bounds.size,
                           safeArea: view.safeAreaInsets)
    }

    private var lastColumnCount = 0

    private func layoutTilesIfNeeded(for size: CGSize? = nil) {
        let metrics = SpicyLayoutMetrics(traitCollection: traitCollection,
                                         size: size ?? view.bounds.size,
                                         safeArea: view.safeAreaInsets)
        let columns = metrics.tileColumns(availableWidth: (size ?? view.bounds.size).width)
        // Avoid rebuilding the grid on every layout pass.
        guard columns != lastColumnCount else { return }
        lastColumnCount = columns
        let tiles = dataSource?.spicyOverlayTiles(self) ?? []
        tileGrid.setModels(tiles, columns: columns)
    }

    private func applyLanguage(_ language: SpicyLanguage) {
        SpicyLayoutDirection.apply(language, to: view)
        machine.send(.languageChanged(language == .arabic ? .ar : .en))
        _ = machine.consumeDirectionRefresh()
        view.setNeedsLayout()
    }

    private func applyPresentationState(_ state: SpicyPresentationState) {
        switch state {
        case .closed:
            SpicyTheme.Motion.animate(SpicyTheme.Motion.fast, animations: { [weak self] in
                self?.view.alpha = 0
            }, completion: { [weak self] _ in
                self?.view.isHidden = true
            })
        case .minimised:
            view.isHidden = false
            view.alpha = 1
            SpicyTheme.Motion.animate { [weak self] in
                self?.scrollView.alpha = 0
                self?.scrollView.isHidden = true
                self?.header.setSubtitleHidden(true)
            }
        case .expanded:
            view.isHidden = false
            SpicyTheme.Motion.animate { [weak self] in
                self?.view.alpha = 1
                self?.scrollView.isHidden = false
                self?.scrollView.alpha = 1
                self?.header.setSubtitleHidden(false)
            }
        case .settingsPresented, .modalPresented:
            break
        }
    }
}

// MARK: - Header delegate

extension SpicyOverlayViewController: SpicyHeaderViewDelegate {

    public func spicyHeaderDidTapSettings(_ header: SpicyHeaderView) {
        let controller = SpicySettingsViewController()
        presentSettings(controller)
    }

    public func spicyHeaderDidTapMinimise(_ header: SpicyHeaderView) {
        send(machine.presentation == .minimised ? .expand : .minimise)
    }

    public func spicyHeaderDidTapClose(_ header: SpicyHeaderView) {
        send(.close)
    }
}
#endif
