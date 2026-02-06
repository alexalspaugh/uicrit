import Foundation

enum MarkdownExporter {
	static func export(payload: ExportPayload) -> String {
		var lines: [String] = []
		lines.append("# Agentation Export")
		lines.append("")
		lines.append("**Timestamp:** \(payload.timestamp)")
		lines.append("**Schema Version:** \(payload.schemaVersion)")
		lines.append("**Elements:** \(payload.elements.count)")
		lines.append("")

		for (index, element) in payload.elements.enumerated() {
			lines.append("---")
			lines.append("")
			lines.append("## Element \(index + 1): \(element.className)")
			lines.append("")

			if let accessibilityID = element.accessibilityIdentifier {
				lines.append("- **Accessibility ID:** `\(accessibilityID)`")
			}
			if let propertyName = element.propertyName {
				lines.append("- **Property Name:** `\(propertyName)`")
			}
			if let vcName = element.viewControllerName {
				lines.append("- **View Controller:** `\(vcName)`")
			}

			let frame = element.frame
			lines.append("- **Frame:** (\(Int(frame.x)), \(Int(frame.y)), \(Int(frame.width))x\(Int(frame.height)))")

			if let annotation = element.annotation {
				lines.append("")
				lines.append("> \(annotation)")
			}

			if let screenshot = element.screenshotFilename {
				lines.append("")
				lines.append("![\(element.className)](\(screenshot))")
			}

			lines.append("")
		}

		return lines.joined(separator: "\n")
	}
}
