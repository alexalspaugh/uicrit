import UIKit

@MainActor
final class ToolbarView: UIView {
	var onAnnotate: (() -> Void)?
	var onExport: (() -> Void)?
	var onDone: (() -> Void)?

	private let glassEffectView: UIVisualEffectView = {
		let effectView = UIVisualEffectView(effect: UIGlassEffect())
		effectView.clipsToBounds = true
		effectView.layer.cornerRadius = 24
		effectView.translatesAutoresizingMaskIntoConstraints = false
		return effectView
	}()

	private let stackView: UIStackView = {
		let stack = UIStackView()
		stack.axis = .horizontal
		stack.distribution = .equalSpacing
		stack.spacing = 16
		stack.translatesAutoresizingMaskIntoConstraints = false
		return stack
	}()

	private lazy var annotateButton: UIButton = {
		let button = ToolbarView.makeIconButton(systemName: "pencil.tip.crop.circle")
		button.addAction(UIAction { [weak self] _ in self?.onAnnotate?() }, for: .touchUpInside)
		return button
	}()

	private lazy var exportButton: UIButton = {
		let button = ToolbarView.makeIconButton(systemName: "square.and.arrow.up")
		button.addAction(UIAction { [weak self] _ in self?.onExport?() }, for: .touchUpInside)
		return button
	}()

	private lazy var doneButton: UIButton = {
		let button = ToolbarView.makeIconButton(systemName: "xmark.circle.fill")
		button.addAction(UIAction { [weak self] _ in self?.onDone?() }, for: .touchUpInside)
		return button
	}()

	override init(frame: CGRect) {
		super.init(frame: frame)
		backgroundColor = .clear
		translatesAutoresizingMaskIntoConstraints = false

		addSubview(glassEffectView)
		glassEffectView.contentView.addSubview(stackView)

		stackView.addArrangedSubview(annotateButton)
		stackView.addArrangedSubview(exportButton)
		stackView.addArrangedSubview(doneButton)

		NSLayoutConstraint.activate([
			glassEffectView.topAnchor.constraint(equalTo: topAnchor),
			glassEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
			glassEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
			glassEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),

			stackView.topAnchor.constraint(equalTo: glassEffectView.contentView.topAnchor, constant: 6),
			stackView.leadingAnchor.constraint(equalTo: glassEffectView.contentView.leadingAnchor, constant: 20),
			stackView.trailingAnchor.constraint(equalTo: glassEffectView.contentView.trailingAnchor, constant: -20),
			stackView.bottomAnchor.constraint(equalTo: glassEffectView.contentView.bottomAnchor, constant: -6),
			stackView.heightAnchor.constraint(equalToConstant: 36),
		])
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private static func makeIconButton(systemName: String) -> UIButton {
		var config = UIButton.Configuration.plain()
		let symbolConfig = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
		config.image = UIImage(systemName: systemName, withConfiguration: symbolConfig)
		config.baseForegroundColor = .label
		let button = UIButton(configuration: config)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}
}
