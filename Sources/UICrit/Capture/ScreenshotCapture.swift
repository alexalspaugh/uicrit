import UIKit

enum ScreenshotCapture {
	static func capture(view: UIView, padding: CGFloat = 20, scale: CGFloat = 2, quality: CGFloat = 0.6) -> Data? {
		guard let window = view.window else { return nil }
		guard let frameInWindow = view.agFrameInWindow else { return nil }

		let screenBounds = window.bounds
		let cropRect = frameInWindow.insetBy(dx: -padding, dy: -padding).intersection(screenBounds)
		guard !cropRect.isEmpty else { return nil }

		let clampedScale = min(scale, 2)
		let format = UIGraphicsImageRendererFormat()
		format.scale = clampedScale
		let renderer = UIGraphicsImageRenderer(bounds: cropRect, format: format)

		let image = renderer.image { _ in
			window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
		}

		return image.jpegData(compressionQuality: quality)
	}

	static func captureRect(_ rect: CGRect, in window: UIWindow, scale: CGFloat = 2, quality: CGFloat = 0.6) -> Data? {
		let screenBounds = window.bounds
		let cropRect = rect.intersection(screenBounds)
		guard !cropRect.isEmpty else { return nil }

		let clampedScale = min(scale, 2)
		let format = UIGraphicsImageRendererFormat()
		format.scale = clampedScale
		let renderer = UIGraphicsImageRenderer(bounds: cropRect, format: format)

		let image = renderer.image { _ in
			window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
		}

		return image.jpegData(compressionQuality: quality)
	}

	static func captureFullScreen(window: UIWindow, scale: CGFloat = 2, quality: CGFloat = 0.6) -> Data? {
		let clampedScale = min(scale, 2)
		let format = UIGraphicsImageRendererFormat()
		format.scale = clampedScale
		let renderer = UIGraphicsImageRenderer(bounds: window.bounds, format: format)

		let image = renderer.image { _ in
			window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
		}

		return image.jpegData(compressionQuality: quality)
	}
}
