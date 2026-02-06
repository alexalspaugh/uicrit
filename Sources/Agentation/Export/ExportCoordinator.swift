import UIKit

struct ExportResult {
	let directoryURL: URL
	let jsonURL: URL
	let markdownURL: URL
	let screenshotURLs: [URL]
	let markdownString: String
}

@MainActor
final class ExportCoordinator {
	func export(session: Session) async -> ExportResult? {
		let records = session.records

		let exportDir = FileManager.default.temporaryDirectory.appendingPathComponent("Agentation", isDirectory: true)
		try? FileManager.default.removeItem(at: exportDir)
		try? FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)

		var screenshotURLs: [URL] = []
		var elements: [ExportElement] = []

		for record in records {
			var screenshotFilename: String?

			if let view = record.view, let data = ScreenshotCapture.capture(view: view) {
				let filename = "\(record.id).jpg"
				let fileURL = exportDir.appendingPathComponent(filename)
				try? data.write(to: fileURL)
				screenshotFilename = filename
				screenshotURLs.append(fileURL)
			}

			let element = ExportElement(
				id: record.id,
				className: record.className,
				accessibilityIdentifier: record.accessibilityIdentifier,
				propertyName: record.propertyName,
				viewControllerName: record.viewControllerName,
				frame: ExportFrame(
					x: record.frameInWindow.origin.x,
					y: record.frameInWindow.origin.y,
					width: record.frameInWindow.size.width,
					height: record.frameInWindow.size.height
				),
				annotation: record.annotation?.text,
				screenshotFilename: screenshotFilename
			)
			elements.append(element)
		}

		let formatter = ISO8601DateFormatter()
		let payload = ExportPayload(
			schemaVersion: "1.0.0",
			timestamp: formatter.string(from: Date()),
			elements: elements
		)

		let jsonURL = exportDir.appendingPathComponent("export.json")
		let markdownURL = exportDir.appendingPathComponent("export.md")

		let markdownString = MarkdownExporter.export(payload: payload)

		do {
			let jsonData = try JSONExporter.export(payload: payload)
			try jsonData.write(to: jsonURL)
			try markdownString.write(to: markdownURL, atomically: true, encoding: .utf8)
		} catch {
			return nil
		}

		return ExportResult(
			directoryURL: exportDir,
			jsonURL: jsonURL,
			markdownURL: markdownURL,
			screenshotURLs: screenshotURLs,
			markdownString: markdownString
		)
	}
}
