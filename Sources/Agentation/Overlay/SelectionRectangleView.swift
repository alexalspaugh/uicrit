import UIKit

@MainActor
final class SelectionRectangleView: UIView {
	private let borderLayer = CAShapeLayer()

	override init(frame: CGRect) {
		super.init(frame: frame)
		isUserInteractionEnabled = false
		backgroundColor = .clear

		borderLayer.fillColor = UIColor.systemBlue.withAlphaComponent(0.06).cgColor
		borderLayer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
		borderLayer.lineWidth = 1
		borderLayer.lineDashPattern = [6, 4]
		layer.addSublayer(borderLayer)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		borderLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: 2).cgPath
		borderLayer.frame = bounds
	}
}
