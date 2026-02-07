import Foundation

struct ExportPayload: Codable {
	let schemaVersion: String
	let timestamp: String
	let elements: [ExportElement]

	enum CodingKeys: String, CodingKey {
		case schemaVersion = "schema_version"
		case timestamp
		case elements
	}
}

struct ExportElement: Codable {
	let id: String
	let className: String
	let accessibilityIdentifier: String?
	let propertyName: String?
	let viewControllerName: String?
	let cellClassName: String?
	let visualProperties: ExportVisualProperties?
	let frame: ExportFrame
	let annotation: String?
	let screenshotFilename: String?

	enum CodingKeys: String, CodingKey {
		case id
		case className = "class_name"
		case accessibilityIdentifier = "accessibility_identifier"
		case propertyName = "property_name"
		case viewControllerName = "view_controller_name"
		case cellClassName = "cell_class_name"
		case visualProperties = "visual_properties"
		case frame
		case annotation
		case screenshotFilename = "screenshot_filename"
	}
}

struct ExportVisualProperties: Codable {
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

	enum CodingKeys: String, CodingKey {
		case text
		case fontSize = "font_size"
		case textColor = "text_color"
		case backgroundColor = "background_color"
		case cornerRadius = "corner_radius"
		case alpha
		case isHidden = "is_hidden"
		case imageName = "image_name"
		case numberOfLines = "number_of_lines"
		case contentMode = "content_mode"
	}

	init(from visualProperties: VisualProperties?) {
		guard let vp = visualProperties else {
			text = nil
			fontSize = nil
			textColor = nil
			backgroundColor = nil
			cornerRadius = nil
			alpha = nil
			isHidden = nil
			imageName = nil
			numberOfLines = nil
			contentMode = nil
			return
		}
		text = vp.text
		fontSize = vp.fontSize
		textColor = vp.textColor
		backgroundColor = vp.backgroundColor
		cornerRadius = vp.cornerRadius
		alpha = vp.alpha
		isHidden = vp.isHidden
		imageName = vp.imageName
		numberOfLines = vp.numberOfLines
		contentMode = vp.contentMode
	}
}

struct ExportFrame: Codable {
	let x: CGFloat
	let y: CGFloat
	let width: CGFloat
	let height: CGFloat
}
