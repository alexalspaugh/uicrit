import UIKit

@MainActor
final class HighlightView: UIView {
	private let borderLayer = CAShapeLayer()

	private let metadataLabel: UILabel = {
		let label = UILabel()
		label.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
		label.textColor = .white
		label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
		label.numberOfLines = 0
		label.textAlignment = .left
		label.translatesAutoresizingMaskIntoConstraints = false
		label.layer.cornerRadius = 4
		label.layer.masksToBounds = true
		return label
	}()

	private var labelBottomConstraint: NSLayoutConstraint?
	private var labelTopConstraint: NSLayoutConstraint?

	override init(frame: CGRect) {
		super.init(frame: frame)
		isUserInteractionEnabled = false
		borderLayer.fillColor = UIColor.systemBlue.withAlphaComponent(0.06).cgColor
		borderLayer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.6).cgColor
		borderLayer.lineWidth = 2
		layer.addSublayer(borderLayer)
		addSubview(metadataLabel)

		let leadingConstraint = metadataLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
		leadingConstraint.priority = .defaultHigh

		let bottom = metadataLabel.bottomAnchor.constraint(equalTo: topAnchor, constant: -2)
		labelBottomConstraint = bottom

		let top = metadataLabel.topAnchor.constraint(equalTo: bottomAnchor, constant: 2)
		labelTopConstraint = top
		top.isActive = false

		NSLayoutConstraint.activate([
			leadingConstraint,
			bottom,
		])
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func didMoveToSuperview() {
		super.didMoveToSuperview()
		guard let superview else { return }
		NSLayoutConstraint.activate([
			metadataLabel.leadingAnchor.constraint(greaterThanOrEqualTo: superview.leadingAnchor, constant: 8),
			metadataLabel.trailingAnchor.constraint(lessThanOrEqualTo: superview.trailingAnchor, constant: -8),
		])
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		borderLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: 3).cgPath
		borderLayer.frame = bounds
	}

	func configure(className: String, accessibilityID: String?, propertyName: String?) {
		var parts = [className]
		if let propertyName {
			parts.append(".\(propertyName)")
		}
		if let accessibilityID {
			parts.append("id: \(accessibilityID)")
		}
		metadataLabel.text = "  " + parts.joined(separator: " · ") + "  "
	}

	func animateIn() {
		alpha = 0
		transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
		UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) { [weak self] in
			self?.alpha = 1
			self?.transform = .identity
		}
	}

	func updateLabelPosition(containerBounds: CGRect) {
		if frame.origin.y < 60 {
			labelBottomConstraint?.isActive = false
			labelTopConstraint?.isActive = true
		} else {
			labelTopConstraint?.isActive = false
			labelBottomConstraint?.isActive = true
		}
	}
}
