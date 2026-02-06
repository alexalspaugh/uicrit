import UIKit

extension UIView {
	var agContainingCellClassName: String? {
		var current: UIView? = superview
		while let view = current {
			if view is UICollectionViewCell || view is UITableViewCell {
				return String(describing: type(of: view))
			}
			current = view.superview
		}
		return nil
	}
}
