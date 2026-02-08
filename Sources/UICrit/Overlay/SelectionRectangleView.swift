import UIKit

@MainActor
final class SelectionRectangleView: UIView {
	enum Corner: CaseIterable {
		case topLeft, topRight, bottomLeft, bottomRight
	}

	enum HitArea {
		case corner(Corner)
		case inside
		case none
	}

	private let borderLayer = CAShapeLayer()
	private let topLeftHandle = CAShapeLayer()
	private let topRightHandle = CAShapeLayer()
	private let bottomLeftHandle = CAShapeLayer()
	private let bottomRightHandle = CAShapeLayer()

	var handlesVisible: Bool = false {
		didSet {
			topLeftHandle.isHidden = !handlesVisible
			topRightHandle.isHidden = !handlesVisible
			bottomLeftHandle.isHidden = !handlesVisible
			bottomRightHandle.isHidden = !handlesVisible
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		isUserInteractionEnabled = false
		backgroundColor = .clear

		borderLayer.fillColor = UIColor.systemBlue.withAlphaComponent(0.06).cgColor
		borderLayer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
		borderLayer.lineWidth = 1
		borderLayer.lineDashPattern = [6, 4]
		layer.addSublayer(borderLayer)

		for handle in [topLeftHandle, topRightHandle, bottomLeftHandle, bottomRightHandle] {
			handle.fillColor = UIColor.white.cgColor
			handle.strokeColor = UIColor.systemBlue.cgColor
			handle.lineWidth = 1.5
			handle.isHidden = true
			layer.addSublayer(handle)
		}
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		borderLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: 2).cgPath
		borderLayer.frame = bounds

		let handleRadius: CGFloat = 5
		let handleDiameter = handleRadius * 2
		let handlePath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: CGSize(width: handleDiameter, height: handleDiameter))).cgPath

		let positions: [(CAShapeLayer, CGPoint)] = [
			(topLeftHandle, CGPoint(x: 0, y: 0)),
			(topRightHandle, CGPoint(x: bounds.width, y: 0)),
			(bottomLeftHandle, CGPoint(x: 0, y: bounds.height)),
			(bottomRightHandle, CGPoint(x: bounds.width, y: bounds.height)),
		]
		for (handle, center) in positions {
			handle.path = handlePath
			handle.frame = CGRect(
				x: center.x - handleRadius,
				y: center.y - handleRadius,
				width: handleDiameter,
				height: handleDiameter
			)
		}
		CATransaction.commit()
	}

	func hitArea(for point: CGPoint) -> HitArea {
		let hitRadius: CGFloat = 22
		let corners: [(Corner, CGPoint)] = [
			(.topLeft, CGPoint(x: 0, y: 0)),
			(.topRight, CGPoint(x: bounds.width, y: 0)),
			(.bottomLeft, CGPoint(x: 0, y: bounds.height)),
			(.bottomRight, CGPoint(x: bounds.width, y: bounds.height)),
		]
		for (corner, center) in corners {
			let dx = point.x - center.x
			let dy = point.y - center.y
			if dx * dx + dy * dy <= hitRadius * hitRadius {
				return .corner(corner)
			}
		}
		if bounds.contains(point) {
			return .inside
		}
		return .none
	}
}
