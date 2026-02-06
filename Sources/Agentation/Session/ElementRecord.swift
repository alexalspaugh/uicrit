import UIKit

struct ElementRecord {
	let id: String
	weak var view: UIView?
	let className: String
	let accessibilityIdentifier: String?
	let propertyName: String?
	let frameInWindow: CGRect
	let viewControllerName: String?
	let cellClassName: String?
	let visualProperties: VisualProperties?
	var annotation: Annotation?
	let capturedAt: Date
}
