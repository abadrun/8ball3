//
//  SpicyFeatureTile.swift
//  MR. SPICY UI — reusable icon tile for navigation / UI categories
//
//  MR. SPICY UI v1.0.0
//
//  A tile is a *navigation and presentation* control: it selects a MR. SPICY UI
//  surface (settings, language, help, about, …). Tiles do not perform or
//  represent any host behaviour on their own; their state is always supplied
//  by the embedding application.
//

#if canImport(UIKit)
import UIKit

public final class SpicyFeatureTile: UIControl {

    public struct Model {
        public let id: String
        public let titleKey: SpicyStringKey
        public let systemImageName: String
        public let mirrorsIconForRTL: Bool
        public var state: SpicyControlState
        public let accessibilityHintKey: SpicyStringKey?

        public init(id: String,
                    titleKey: SpicyStringKey,
                    systemImageName: String,
                    mirrorsIconForRTL: Bool = false,
                    state: SpicyControlState = .default,
                    accessibilityHintKey: SpicyStringKey? = .a11yTileHint) {
            self.id = id
            self.titleKey = titleKey
            self.systemImageName = systemImageName
            self.mirrorsIconForRTL = mirrorsIconForRTL
            self.state = state
            self.accessibilityHintKey = accessibilityHintKey
        }
    }

    public private(set) var model: Model

    private let circle = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var languageObserver: NSObjectProtocol?

    public init(model: Model) {
        self.model = model
        super.init(frame: .zero)

        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.isUserInteractionEnabled = false
        addSubview(circle)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: SpicyTheme.Size.iconM, weight: .semibold)
        circle.addSubview(iconView)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        circle.addSubview(spinner)

        titleLabel.font = SpicyTheme.Typography.caption()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        let side = SpicyTheme.Size.tileSide - 20
        NSLayoutConstraint.activate([
            circle.topAnchor.constraint(equalTo: topAnchor),
            circle.centerXAnchor.constraint(equalTo: centerXAnchor),
            circle.widthAnchor.constraint(equalToConstant: side),
            circle.heightAnchor.constraint(equalToConstant: side),

            iconView.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
            spinner.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: circle.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: circle.bottomAnchor,
                                            constant: SpicyTheme.Spacing.s),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            widthAnchor.constraint(greaterThanOrEqualToConstant: SpicyTheme.Size.minimumTouchTarget),
            heightAnchor.constraint(greaterThanOrEqualToConstant: SpicyTheme.Size.minimumTouchTarget),
        ])

        circle.layer.cornerCurve = .continuous
        circle.layer.cornerRadius = side / 2
        circle.layer.borderWidth = SpicyTheme.Stroke.thin

        apply(model: model)
        isAccessibilityElement = true

        languageObserver = NotificationCenter.default.addObserver(
            forName: SpicyL10n.languageDidChangeNotification,
            object: nil, queue: .main) { [weak self] _ in
                guard let self else { return }
                self.apply(model: self.model)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    deinit {
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
    }

    // MARK: State

    public func apply(model: Model) {
        self.model = model
        let image = UIImage(systemName: model.systemImageName)
        iconView.image = model.mirrorsIconForRTL
            ? SpicyLayoutDirection.directionalImage(image) : image
        titleLabel.text = SpicyL10n.shared.string(model.titleKey)
        isEnabled = model.state.isEnabled
        isSelected = model.state.isSelected
        model.state.isBusy ? spinner.startAnimating() : spinner.stopAnimating()
        iconView.isHidden = model.state.isBusy
        applyStyle()
        updateAccessibility()
    }

    public override var isSelected: Bool { didSet { applyStyle() } }
    public override var isEnabled: Bool { didSet { applyStyle(); updateAccessibility() } }
    public override var isHighlighted: Bool {
        didSet {
            SpicyTheme.Motion.animate(SpicyTheme.Motion.fast) { [weak self] in
                guard let self else { return }
                self.circle.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.94, y: 0.94) : .identity
            }
        }
    }

    private func applyStyle() {
        let tint: UIColor
        if !isEnabled {
            circle.backgroundColor = SpicyTheme.Color.controlFillDisabled
            circle.layer.borderColor = SpicyTheme.Color.border.cgColor
            tint = SpicyTheme.Color.textDisabled
        } else if isSelected {
            circle.backgroundColor = SpicyTheme.Color.primaryWash
            circle.layer.borderColor = SpicyTheme.Color.primary.cgColor
            tint = SpicyTheme.Color.primaryTint
        } else {
            circle.backgroundColor = SpicyTheme.Color.controlFill
            circle.layer.borderColor = SpicyTheme.Color.border.cgColor
            tint = SpicyTheme.Color.textPrimary
        }
        iconView.tintColor = tint
        spinner.color = tint
        titleLabel.textColor = isEnabled
            ? (isSelected ? SpicyTheme.Color.primaryTint : SpicyTheme.Color.textSecondary)
            : SpicyTheme.Color.textDisabled
    }

    private func updateAccessibility() {
        accessibilityLabel = titleLabel.text
        var traits: UIAccessibilityTraits = .button
        if isSelected { traits.insert(.selected) }
        if !isEnabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
        if let hint = model.accessibilityHintKey {
            accessibilityHint = SpicyL10n.shared.string(hint)
        }
        if model.state.isBusy {
            accessibilityValue = SpicyStringKey.stateLoading.localized
        } else if isSelected {
            accessibilityValue = SpicyStringKey.stateSelected.localized
        } else {
            accessibilityValue = nil
        }
    }

    public override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        applyStyle()
    }
}

/// Grid container that lays tiles out responsively and mirrors in RTL.
public final class SpicyFeatureTileGrid: UIView {

    public var onSelect: ((SpicyFeatureTile.Model) -> Void)?

    private let stack = UIStackView()
    private var tiles: [SpicyFeatureTile] = []
    private var columns: Int = 4

    public init() {
        super.init(frame: .zero)
        stack.axis = .vertical
        stack.spacing = SpicyTheme.Spacing.l
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.spicyPin(to: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public func setModels(_ models: [SpicyFeatureTile.Model], columns: Int) {
        self.columns = max(2, columns)
        // Tiles are rebuilt only when the model set or column count changes,
        // never on every layout pass.
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        tiles = models.map { model in
            let tile = SpicyFeatureTile(model: model)
            tile.addTarget(self, action: #selector(tileTapped(_:)), for: .touchUpInside)
            return tile
        }
        for row in stride(from: 0, to: tiles.count, by: self.columns) {
            let rowStack = UIStackView(arrangedSubviews:
                Array(tiles[row..<min(row + self.columns, tiles.count)]))
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.alignment = .top
            rowStack.spacing = SpicyTheme.Spacing.m
            // Pad the final row so tiles keep their column width.
            let missing = self.columns - rowStack.arrangedSubviews.count
            for _ in 0..<max(0, missing) { rowStack.addArrangedSubview(UIView()) }
            stack.addArrangedSubview(rowStack)
        }
    }

    public func updateModel(id: String, transform: (inout SpicyFeatureTile.Model) -> Void) {
        guard let tile = tiles.first(where: { $0.model.id == id }) else { return }
        var model = tile.model
        transform(&model)
        tile.apply(model: model)
    }

    @objc private func tileTapped(_ sender: SpicyFeatureTile) {
        onSelect?(sender.model)
    }
}
#endif
