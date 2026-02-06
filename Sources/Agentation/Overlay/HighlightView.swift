import UIKit

@MainActor
final class HighlightView: UIView {
	private let borderLayer = CAShapeLayer()

	private let metadataLabel: UILabel = {
		let label = UILabel()
		label.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
		label.textColor = .white
		label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.85)
		label.numberOfLines = 0
		label.textAlignment = .left
		label.translatesAutoresizingMaskIntoConstraints = false
		label.layer.cornerRadius = 4
		label.layer.masksToBounds = true
		return label
	}()

	override init(frame: CGRect) {
		super.init(frame: frame)
		isUserInteractionEnabled = false
		borderLayer.fillColor = UIColor.systemBlue.withAlphaComponent(0.08).cgColor
		borderLayer.strokeColor = UIColor.systemBlue.cgColor
		borderLayer.lineWidth = 2
		layer.addSublayer(borderLayer)
		addSubview(metadataLabel)
		NSLayoutConstraint.activate([
			metadataLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
			metadataLabel.bottomAnchor.constraint(equalTo: topAnchor, constant: -2),
		])
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		borderLayer.path = UIBezierPath(rect: bounds).cgPath
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
}
