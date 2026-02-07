import Foundation

enum JSONExporter {
	static func export(payload: ExportPayload) throws -> Data {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		return try encoder.encode(payload)
	}
}
