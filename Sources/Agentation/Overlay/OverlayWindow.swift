import UIKit

@MainActor
final class OverlayWindow: UIWindow {
	init(scene: UIWindowScene) {
		super.init(windowScene: scene)
		windowLevel = .alert + 2
		backgroundColor = .clear
		isHidden = false
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		guard let hit = super.hitTest(point, with: event) else { return nil }
		if hit === rootViewController?.view {
			return hit
		}
		if hit is UIControl || hit is UITextField {
			return hit
		}
		if let gestureRecognizers = hit.gestureRecognizers, !gestureRecognizers.isEmpty {
			return hit
		}
		return hit
	}
}
