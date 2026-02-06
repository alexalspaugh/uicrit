import Foundation

enum AreaMarkdownExporter {
	static func export(payload: AreaExportPayload) -> String {
		var lines: [String] = []
		lines.append("# Agentation Area Export")
		lines.append("")
		lines.append("**Timestamp:** \(payload.timestamp)")
		lines.append("")
		lines.append("## Selected Area")
		lines.append("")
		let area = payload.selectedArea
		lines.append("- **Frame:** (\(Int(area.x)), \(Int(area.y)), \(Int(area.width))x\(Int(area.height)))")
		lines.append("")
		lines.append("## Note")
		lines.append("")
		lines.append("> \(payload.note)")
		lines.append("")
		lines.append("## Screenshots")
		lines.append("")
		if let fullscreen = payload.fullScreenFilename {
			lines.append("![Full Screen](\(fullscreen))")
		}
		if let areaFile = payload.areaFilename {
			lines.append("![Selected Area](\(areaFile))")
		}
		lines.append("")

		if !payload.elements.isEmpty {
			lines.append("## Views in Selected Area")
			lines.append("")
			lines.append("**Count:** \(payload.elements.count)")
			lines.append("")
			for (index, element) in payload.elements.enumerated() {
				lines.append("### \(index + 1). \(element.className)")
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
				lines.append("")
			}
		}

		return lines.joined(separator: "\n")
	}
}
