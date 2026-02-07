import Foundation

enum AreaMarkdownExporter {
	static func export(payload: AreaExportPayload) -> String {
		var lines: [String] = []
		lines.append("# UICrit Area Export")
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
				if let cellName = element.cellClassName {
					lines.append("- **Cell:** `\(cellName)`")
				}
				let frame = element.frame
				lines.append("- **Frame:** (\(Int(frame.x)), \(Int(frame.y)), \(Int(frame.width))x\(Int(frame.height)))")
				if let vp = element.visualProperties {
					appendVisualProperties(vp, to: &lines)
				}
				lines.append("")
			}
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
