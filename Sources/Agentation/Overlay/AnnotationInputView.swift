import UIKit

@MainActor
final class AnnotationInputView: UIView {
	var onSave: ((String) -> Void)?

	private let textField: UITextField = {
		let field = UITextField()
		field.placeholder = "Add annotation..."
		field.borderStyle = .roundedRect
		field.font = .systemFont(ofSize: 14)
		field.returnKeyType = .done
		field.translatesAutoresizingMaskIntoConstraints = false
		return field
	}()

	private let saveButton: UIButton = {
		var config = UIButton.Configuration.filled()
		config.title = "Save"
		config.baseBackgroundColor = .systemBlue
		config.baseForegroundColor = .white
		config.cornerStyle = .medium
		let button = UIButton(configuration: config)
		button.translatesAutoresizingMaskIntoConstraints = false
		return button
	}()

	private var bottomConstraint: NSLayoutConstraint?

	override init(frame: CGRect) {
		super.init(frame: frame)
		backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
		translatesAutoresizingMaskIntoConstraints = false
		isHidden = true

		let stack = UIStackView(arrangedSubviews: [textField, saveButton])
		stack.axis = .horizontal
		stack.spacing = 8
		stack.translatesAutoresizingMaskIntoConstraints = false
		addSubview(stack)

		NSLayoutConstraint.activate([
			stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
			stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
			stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
			stack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
			stack.heightAnchor.constraint(equalToConstant: 44),
			saveButton.widthAnchor.constraint(equalToConstant: 60),
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
		textField.becomeFirstResponder()
	}

	func hide() {
		textField.resignFirstResponder()
		isHidden = true
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
		bottomConstraint?.constant = -keyboardFrame.height
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
