import UIKit

@available(iOS 26, *)
@MainActor
final class AnnotationInputView: UIView {
	var onSave: ((String) -> Void)?

	private let glassEffect = UIGlassEffect()

	private let glassEffectView: UIVisualEffectView = {
		let effectView = UIVisualEffectView(effect: nil)
		effectView.clipsToBounds = true
		effectView.cornerConfiguration = .corners(radius: .fixed(22))
		effectView.translatesAutoresizingMaskIntoConstraints = false
		return effectView
	}()

	private let textField: UITextField = {
		let field = UITextField()
		field.placeholder = "Add annotation..."
		field.borderStyle = .none
		field.font = .systemFont(ofSize: 16)
		field.returnKeyType = .done
		field.translatesAutoresizingMaskIntoConstraints = false
		return field
	}()

	private let saveButton: UIButton = {
		var config = UIButton.Configuration.plain()
		let symbolConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
		config.image = UIImage(systemName: "arrow.up.circle.fill", withConfiguration: symbolConfig)
		config.baseForegroundColor = .systemBlue
		let button = UIButton(configuration: config)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	private var bottomConstraint: NSLayoutConstraint?

	override init(frame: CGRect) {
		super.init(frame: frame)
		backgroundColor = .clear
		translatesAutoresizingMaskIntoConstraints = false
		isHidden = true

		addSubview(glassEffectView)
		NSLayoutConstraint.activate([
			glassEffectView.topAnchor.constraint(equalTo: topAnchor),
			glassEffectView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
			glassEffectView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
			glassEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
		])

		let stack = UIStackView(arrangedSubviews: [textField, saveButton])
		stack.axis = .horizontal
		stack.spacing = 8
		stack.translatesAutoresizingMaskIntoConstraints = false
		glassEffectView.contentView.addSubview(stack)

		NSLayoutConstraint.activate([
			stack.topAnchor.constraint(equalTo: glassEffectView.contentView.topAnchor, constant: 6),
			stack.leadingAnchor.constraint(equalTo: glassEffectView.contentView.leadingAnchor, constant: 16),
			stack.trailingAnchor.constraint(equalTo: glassEffectView.contentView.trailingAnchor, constant: -16),
			stack.bottomAnchor.constraint(equalTo: glassEffectView.contentView.bottomAnchor, constant: -6),
			stack.heightAnchor.constraint(equalToConstant: 36),
			saveButton.widthAnchor.constraint(equalToConstant: 36),
		])

		saveButton.addAction(UIAction { [weak self] _ in self?.handleSave() }, for: .touchUpInside)
		textField.addAction(UIAction { [weak self] _ in self?.handleSave() }, for: .editingDidEndOnExit)

		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func show() {
		textField.text = nil
		isHidden = false
		glassEffectView.effect = nil
		UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: []) { [weak self] in
			guard let self else { return }
			self.glassEffectView.effect = self.glassEffect
		}
		textField.becomeFirstResponder()
	}

	func hide() {
		textField.resignFirstResponder()
		UIView.animate(withDuration: 0.3, animations: { [weak self] in
			self?.glassEffectView.effect = nil
		}) { [weak self] _ in
			self?.isHidden = true
		}
	}

	func setBottomConstraint(_ constraint: NSLayoutConstraint) {
		bottomConstraint = constraint
	}

	private func handleSave() {
		guard let text = textField.text, !text.isEmpty else { return }
		onSave?(text)
		hide()
	}

	@objc private func keyboardWillShow(_ notification: Notification) {
		guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
			let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
		else { return }
		bottomConstraint?.constant = -keyboardFrame.height - 8
		UIView.animate(withDuration: duration) { [weak self] in
			self?.superview?.layoutIfNeeded()
		}
	}

	@objc private func keyboardWillHide(_ notification: Notification) {
		guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
		bottomConstraint?.constant = 0
		UIView.animate(withDuration: duration) { [weak self] in
			self?.superview?.layoutIfNeeded()
		}
	}
}
