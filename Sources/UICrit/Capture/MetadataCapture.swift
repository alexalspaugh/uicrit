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
			cellClassName: view.agContainingCellClassName,
			visualProperties: view.agVisualProperties,
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
		var current: UIView? = view.superview
		while let ancestor = current {
			if ancestor is UICollectionViewCell || ancestor is UITableViewCell {
				let mirror = Mirror(reflecting: ancestor)
				for case (let label?, let value) in mirror.children {
					if let cellView = value as? UIView, cellView === view {
						return label
					}
				}
				break
			}
			current = ancestor.superview
		}
		// TIER 4: Walk up ancestors and resolve the first one that has a property name
		var ancestor: UIView? = view.superview
		while let current = ancestor {
			if let superview = current.superview,
			   let name = propertyName(of: current, in: superview) {
				return name
			}
			if let vc = current.agOwningViewController {
				let mirror = Mirror(reflecting: vc)
				for case (let label?, let value) in mirror.children {
					if let vcView = value as? UIView, vcView === current {
						return label
					}
				}
			}
			ancestor = current.superview
		}
		return nil
	}
}
