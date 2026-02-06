import Foundation

struct AreaExportPayload: Codable {
	let schemaVersion: String
	let timestamp: String
	let note: String
	let selectedArea: ExportFrame
	let fullScreenFilename: String?
	let areaFilename: String?
	let elements: [ExportElement]

	enum CodingKeys: String, CodingKey {
		case schemaVersion = "schema_version"
		case timestamp
		case note
		case selectedArea = "selected_area"
		case fullScreenFilename = "fullscreen_filename"
		case areaFilename = "area_filename"
		case elements
	}
}
