import UIKit

@available(iOS 26, *)
@MainActor
final class ToolbarView: UIView {
	var onDone: (() -> Void)?
	var onConfirm: (() -> Void)?
	var onRedo: (() -> Void)?

	enum Mode {
		case idle
		case areaSelected
	}

	private let containerEffectView: UIVisualEffectView = {
		let container = UIGlassContainerEffect()
		let effectView = UIVisualEffectView(effect: container)
		effectView.translatesAutoresizingMaskIntoConstraints = false
		return effectView
	}()

	private let instructionLabel: UILabel = {
		let label = UILabel()
		label.text = "Drag to select"
		label.font = .systemFont(ofSize: 13, weight: .medium)
		label.textColor = .secondaryLabel
		label.textAlignment = .center
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()

	private lazy var dismissButton: UIView = {
		makeCircularGlassButton(systemName: "xmark", tinted: false) { [weak self] in
			self?.onDone?()
		}
	}()

	private lazy var redoButton: UIView = {
		makeCircularGlassButton(systemName: "xmark", tinted: false) { [weak self] in
			self?.onRedo?()
		}
	}()

	private lazy var confirmButton: UIView = {
		makeCircularGlassButton(systemName: "checkmark", tinted: true) { [weak self] in
			self?.onConfirm?()
		}
	}()

	private let buttonContainer: UIStackView = {
		let stack = UIStackView()
		stack.axis = .horizontal
		stack.spacing = 16
		stack.alignment = .center
		stack.translatesAutoresizingMaskIntoConstraints = false
		return stack
	}()

	private let outerStack: UIStackView = {
		let stack = UIStackView()
		stack.axis = .vertical
		stack.spacing = 12
		stack.alignment = .center
		stack.translatesAutoresizingMaskIntoConstraints = false
		return stack
	}()

	override init(frame: CGRect) {
		super.init(frame: frame)
		backgroundColor = .clear
		translatesAutoresizingMaskIntoConstraints = false

		addSubview(containerEffectView)
		containerEffectView.contentView.addSubview(outerStack)
		outerStack.addArrangedSubview(instructionLabel)
		outerStack.addArrangedSubview(buttonContainer)

		buttonContainer.addArrangedSubview(dismissButton)

		NSLayoutConstraint.activate([
			containerEffectView.topAnchor.constraint(equalTo: topAnchor),
			containerEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
			containerEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
			containerEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),

			outerStack.topAnchor.constraint(equalTo: containerEffectView.contentView.topAnchor, constant: 12),
			outerStack.leadingAnchor.constraint(equalTo: containerEffectView.contentView.leadingAnchor, constant: 12),
			outerStack.trailingAnchor.constraint(equalTo: containerEffectView.contentView.trailingAnchor, constant: -12),
			outerStack.bottomAnchor.constraint(equalTo: containerEffectView.contentView.bottomAnchor, constant: -12),
		])
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func setMode(_ mode: Mode) {
		buttonContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
		switch mode {
		case .idle:
			instructionLabel.isHidden = false
			buttonContainer.addArrangedSubview(dismissButton)
			UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: []) { [weak self] in
				self?.layoutIfNeeded()
			}
		case .areaSelected:
			instructionLabel.isHidden = true
			UIView.performWithoutAnimation {
				buttonContainer.addArrangedSubview(redoButton)
				buttonContainer.addArrangedSubview(confirmButton)
				buttonContainer.layoutIfNeeded()
			}
			redoButton.transform = CGAffineTransform(translationX: 36, y: 0)
			confirmButton.transform = CGAffineTransform(translationX: -36, y: 0)
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3, options: []) { [weak self] in
				self?.redoButton.transform = .identity
				self?.confirmButton.transform = .identity
				self?.buttonContainer.layoutIfNeeded()
			}
		}
	}

	private func makeCircularGlassButton(
		systemName: String,
		tinted: Bool,
		action: @escaping () -> Void
	) -> UIView {
		let size: CGFloat = 56

		let wrapper = UIView()
		wrapper.translatesAutoresizingMaskIntoConstraints = false

		let glassEffect = UIGlassEffect()
		glassEffect.isInteractive = true
		if tinted {
			glassEffect.tintColor = .systemBlue
		}

		let effectView = UIVisualEffectView(effect: glassEffect)
		effectView.clipsToBounds = true
		effectView.cornerConfiguration = .corners(radius: .fixed(size / 2))
		effectView.translatesAutoresizingMaskIntoConstraints = false
		wrapper.addSubview(effectView)

		let symbolConfig = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
		let imageView = UIImageView(image: UIImage(systemName: systemName, withConfiguration: symbolConfig))
		imageView.tintColor = tinted ? .white : .label
		imageView.contentMode = .center
		imageView.translatesAutoresizingMaskIntoConstraints = false
		effectView.contentView.addSubview(imageView)

		let button = UIButton()
		button.backgroundColor = .clear
		button.translatesAutoresizingMaskIntoConstraints = false
		button.addAction(UIAction { _ in action() }, for: .touchUpInside)
		wrapper.addSubview(button)

		NSLayoutConstraint.activate([
			wrapper.widthAnchor.constraint(equalToConstant: size),
			wrapper.heightAnchor.constraint(equalToConstant: size),

			effectView.topAnchor.constraint(equalTo: wrapper.topAnchor),
			effectView.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
			effectView.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
			effectView.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),

			imageView.centerXAnchor.constraint(equalTo: effectView.contentView.centerXAnchor),
			imageView.centerYAnchor.constraint(equalTo: effectView.contentView.centerYAnchor),

			button.topAnchor.constraint(equalTo: wrapper.topAnchor),
			button.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
			button.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
			button.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
		])

		return wrapper
	}
}
