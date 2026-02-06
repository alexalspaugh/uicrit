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
	let frame: ExportFrame
	let annotation: String?
	let screenshotFilename: String?

	enum CodingKeys: String, CodingKey {
		case id
		case className = "class_name"
		case accessibilityIdentifier = "accessibility_identifier"
		case propertyName = "property_name"
		case viewControllerName = "view_controller_name"
		case frame
		case annotation
		case screenshotFilename = "screenshot_filename"
	}
}

struct ExportFrame: Codable {
	let x: CGFloat
	let y: CGFloat
	let width: CGFloat
	let height: CGFloat
}
