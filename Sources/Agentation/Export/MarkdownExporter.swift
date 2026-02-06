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
			if let cellName = element.cellClassName {
				lines.append("- **Cell:** `\(cellName)`")
			}

			let frame = element.frame
			lines.append("- **Frame:** (\(Int(frame.x)), \(Int(frame.y)), \(Int(frame.width))x\(Int(frame.height)))")
			if let vp = element.visualProperties {
				appendVisualProperties(vp, to: &lines)
			}

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

	private static func appendVisualProperties(_ vp: ExportVisualProperties, to lines: inout [String]) {
		if let text = vp.text {
			lines.append("- **Text:** \"\(text)\"")
		}
		if let fontSize = vp.fontSize {
			lines.append("- **Font Size:** \(Int(fontSize))")
		}
		if let textColor = vp.textColor {
			lines.append("- **Text Color:** `\(textColor)`")
		}
		if let bgColor = vp.backgroundColor {
			lines.append("- **Background Color:** `\(bgColor)`")
		}
		if let cornerRadius = vp.cornerRadius, cornerRadius > 0 {
			lines.append("- **Corner Radius:** \(Int(cornerRadius))")
		}
		if let alpha = vp.alpha, alpha < 1.0 {
			lines.append("- **Alpha:** \(alpha)")
		}
		if let isHidden = vp.isHidden, isHidden {
			lines.append("- **Hidden:** true")
		}
		if let imageName = vp.imageName {
			lines.append("- **Image:** `\(imageName)`")
		}
	}
}
