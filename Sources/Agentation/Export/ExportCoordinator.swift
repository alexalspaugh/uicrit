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

		let baseDir = URL(fileURLWithPath: "/tmp/Agentation", isDirectory: true)
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd'T'HH-mm-ss"
		let timestampDir = baseDir.appendingPathComponent(formatter.string(from: Date()), isDirectory: true)
		try? FileManager.default.createDirectory(at: timestampDir, withIntermediateDirectories: true)
		let latestLink = baseDir.appendingPathComponent("latest")
		try? FileManager.default.removeItem(at: latestLink)
		try? FileManager.default.createSymbolicLink(at: latestLink, withDestinationURL: timestampDir)
		let exportDir = timestampDir

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
				cellClassName: record.cellClassName,
				visualProperties: ExportVisualProperties(from: record.visualProperties),
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

		let isoFormatter = ISO8601DateFormatter()
		let payload = ExportPayload(
			schemaVersion: "1.1.0",
			timestamp: isoFormatter.string(from: Date()),
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
