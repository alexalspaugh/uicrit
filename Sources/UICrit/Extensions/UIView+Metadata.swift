import UIKit

extension UIView {
	var agClassName: String {
		String(describing: type(of: self))
	}

	var agFrameInWindow: CGRect? {
		guard let window else { return nil }
		return convert(bounds, to: window)
	}

	var agOwningViewController: UIViewController? {
		var responder: UIResponder? = next
		while let current = responder {
			if let viewController = current as? UIViewController {
				return viewController
			}
			responder = current.next
		}
		return nil
	}
}
