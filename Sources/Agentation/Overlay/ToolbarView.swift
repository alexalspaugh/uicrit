import UIKit

@MainActor
final class ToolbarView: UIView {
	var onAnnotate: (() -> Void)?
	var onExport: (() -> Void)?
	var onDone: (() -> Void)?

	private let stackView: UIStackView = {
		let stack = UIStackView()
		stack.axis = .horizontal
		stack.distribution = .fillEqually
		stack.spacing = 12
		stack.translatesAutoresizingMaskIntoConstraints = false
		return stack
	}()

	private let annotateButton: UIButton = {
		var config = UIButton.Configuration.filled()
		config.title = "Annotate"
		config.baseBackgroundColor = .systemBlue
		config.baseForegroundColor = .white
		config.cornerStyle = .medium
		let button = UIButton(configuration: config)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	private let exportButton: UIButton = {
		var config = UIButton.Configuration.filled()
		config.title = "Export"
		config.baseBackgroundColor = .systemGreen
		config.baseForegroundColor = .white
		config.cornerStyle = .medium
		let button = UIButton(configuration: config)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	private let doneButton: UIButton = {
		var config = UIButton.Configuration.filled()
		config.title = "Done"
		config.baseBackgroundColor = .systemGray
		config.baseForegroundColor = .white
		config.cornerStyle = .medium
		let button = UIButton(configuration: config)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	override init(frame: CGRect) {
		super.init(frame: frame)
		backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
		translatesAutoresizingMaskIntoConstraints = false

		addSubview(stackView)
		stackView.addArrangedSubview(annotateButton)
		stackView.addArrangedSubview(exportButton)
		stackView.addArrangedSubview(doneButton)

		NSLayoutConstraint.activate([
			stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
			stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
			stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
			stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
			stackView.heightAnchor.constraint(equalToConstant: 44),
		])

		annotateButton.addAction(UIAction { [weak self] _ in self?.onAnnotate?() }, for: .touchUpInside)
		exportButton.addAction(UIAction { [weak self] _ in self?.onExport?() }, for: .touchUpInside)
		doneButton.addAction(UIAction { [weak self] _ in self?.onDone?() }, for: .touchUpInside)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
