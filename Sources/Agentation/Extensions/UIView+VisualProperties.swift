import UIKit

struct VisualProperties {
	let text: String?
	let fontSize: CGFloat?
	let textColor: String?
	let backgroundColor: String?
	let cornerRadius: CGFloat?
	let alpha: CGFloat?
	let isHidden: Bool?
	let imageName: String?
	let numberOfLines: Int?
	let contentMode: String?
}

extension UIView {
	var agVisualProperties: VisualProperties {
		var text: String? = nil
		var fontSize: CGFloat? = nil
		var textColor: String? = nil
		var imageName: String? = nil
		var numberOfLines: Int? = nil
		var contentModeString: String? = nil

		if let label = self as? UILabel {
			text = label.text
			fontSize = label.font?.pointSize
			textColor = label.textColor.agHexString
			numberOfLines = label.numberOfLines
		} else if let textField = self as? UITextField {
			text = textField.text
			fontSize = textField.font?.pointSize
			textColor = textField.textColor?.agHexString
		} else if let textView = self as? UITextView {
			text = textView.text
			fontSize = textView.font?.pointSize
			textColor = textView.textColor?.agHexString
		} else if let button = self as? UIButton {
			text = button.currentTitle
			fontSize = button.titleLabel?.font?.pointSize
			textColor = button.currentTitleColor.agHexString
		} else if let imageView = self as? UIImageView {
			imageName = imageView.image?.accessibilityIdentifier
			contentModeString = imageView.contentMode.agName
		}

		return VisualProperties(
			text: text,
			fontSize: fontSize,
			textColor: textColor,
			backgroundColor: self.backgroundColor?.agHexString,
			cornerRadius: layer.cornerRadius,
			alpha: self.alpha,
			isHidden: isHidden,
			imageName: imageName,
			numberOfLines: numberOfLines,
			contentMode: contentModeString
		)
	}
}

extension UIView.ContentMode {
	var agName: String {
		switch self {
		case .scaleToFill: return "scaleToFill"
		case .scaleAspectFit: return "scaleAspectFit"
		case .scaleAspectFill: return "scaleAspectFill"
		case .center: return "center"
		case .top: return "top"
		case .bottom: return "bottom"
		case .left: return "left"
		case .right: return "right"
		case .topLeft: return "topLeft"
		case .topRight: return "topRight"
		case .bottomLeft: return "bottomLeft"
		case .bottomRight: return "bottomRight"
		case .redraw: return "redraw"
		@unknown default: return "unknown"
		}
	}
}

extension UIColor {
	var agHexString: String? {
		var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
		guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
		guard a > 0 else { return nil }
		return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
	}
}
