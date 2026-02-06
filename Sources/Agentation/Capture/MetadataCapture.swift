import UIKit

enum MetadataCapture {
	static func captureMetadata(for view: UIView) -> ElementRecord {
		let propertyName = findPropertyName(for: view)
		let viewController = view.agOwningViewController
		return ElementRecord(
			id: UUID().uuidString,
			view: view,
			className: view.agClassName,
			accessibilityIdentifier: view.accessibilityIdentifier,
			propertyName: propertyName,
			frameInWindow: view.agFrameInWindow ?? .zero,
			viewControllerName: viewController.map { String(describing: type(of: $0)) },
			annotation: nil,
			capturedAt: Date()
		)
	}

	static func propertyName(of child: UIView, in parent: UIView) -> String? {
		let mirror = Mirror(reflecting: parent)
		for case (let label?, let value) in mirror.children {
			if let view = value as? UIView, view === child {
				return label
			}
		}
		return nil
	}

	private static func findPropertyName(for view: UIView) -> String? {
		if let superview = view.superview {
			if let name = propertyName(of: view, in: superview) {
				return name
			}
		}
		if let viewController = view.agOwningViewController {
			let mirror = Mirror(reflecting: viewController)
			for case (let label?, let value) in mirror.children {
				if let vcView = value as? UIView, vcView === view {
					return label
				}
			}
		}
		return nil
	}
}
