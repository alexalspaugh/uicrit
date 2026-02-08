import UIKit

@available(iOS 26, *)
@MainActor
final class OverlayViewController: UIViewController {
	private let session: Session
	private let toolbarView = ToolbarView()
	private let annotationInputView = AnnotationInputView()
	private var selectionRectangleView: SelectionRectangleView?
	private var dragStartPoint: CGPoint?
	private var annotationBottomConstraint: NSLayoutConstraint?
	private var panGesture: UIPanGestureRecognizer?

	private enum OverlayState {
		case idle
		case areaSelected
		case noting
	}

	private enum SelectionInteraction {
		case none
		case resizing(fixedCorner: CGPoint)
		case moving(startPoint: CGPoint, startRect: CGRect)
	}

	private var overlayState: OverlayState = .idle
	private var selectionInteraction: SelectionInteraction = .none
	private var selectedAreaRect: CGRect?
	private var capturedFullScreenData: Data?
	private var capturedAreaData: Data?
	private var capturedAreaRecords: [ElementRecord] = []

	init(session: Session) {
		self.session = session
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .clear

		let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
		panGesture.minimumNumberOfTouches = 1
		panGesture.maximumNumberOfTouches = 1
		view.addGestureRecognizer(panGesture)
		self.panGesture = panGesture

		view.addSubview(toolbarView)
		NSLayoutConstraint.activate([
			toolbarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			toolbarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
		])

		view.addSubview(annotationInputView)
		let annotationBottom = annotationInputView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
		annotationBottomConstraint = annotationBottom
		annotationInputView.setBottomConstraint(annotationBottom)
		NSLayoutConstraint.activate([
			annotationInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			annotationInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			annotationBottom,
		])

		toolbarView.onDone = {
			UICrit.deactivate()
		}
		toolbarView.onConfirm = { [weak self] in
			self?.confirmArea()
		}
		toolbarView.onRedo = { [weak self] in
			self?.redoAreaSelection()
		}

		annotationInputView.onSave = { [weak self] text in
			self?.saveAnnotation(text)
		}
	}

	// MARK: - Drag Selection

	@objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
		switch overlayState {
		case .idle:
			handleDrawingPan(gesture)
		case .areaSelected:
			handleSelectionPan(gesture)
		case .noting:
			break
		}
	}

	private func handleDrawingPan(_ gesture: UIPanGestureRecognizer) {
		let currentPoint = gesture.location(in: view)

		switch gesture.state {
		case .began:
			dragStartPoint = currentPoint
			let rectView = SelectionRectangleView()
			rectView.frame = CGRect(origin: currentPoint, size: .zero)
			view.insertSubview(rectView, belowSubview: toolbarView)
			selectionRectangleView = rectView

		case .changed:
			guard let startPoint = dragStartPoint else { return }
			let rect = CGRect(
				x: min(startPoint.x, currentPoint.x),
				y: min(startPoint.y, currentPoint.y),
				width: abs(currentPoint.x - startPoint.x),
				height: abs(currentPoint.y - startPoint.y)
			)
			selectionRectangleView?.frame = rect

		case .ended:
			guard let startPoint = dragStartPoint else { return }
			let rect = CGRect(
				x: min(startPoint.x, currentPoint.x),
				y: min(startPoint.y, currentPoint.y),
				width: abs(currentPoint.x - startPoint.x),
				height: abs(currentPoint.y - startPoint.y)
			)
			dragStartPoint = nil

			guard rect.width > 10, rect.height > 10 else {
				selectionRectangleView?.removeFromSuperview()
				selectionRectangleView = nil
				return
			}

			selectionRectangleView?.frame = rect
			selectedAreaRect = rect
			enterAreaSelectedState()

		case .cancelled, .failed:
			selectionRectangleView?.removeFromSuperview()
			selectionRectangleView = nil
			dragStartPoint = nil

		default:
			break
		}
	}

	private func handleSelectionPan(_ gesture: UIPanGestureRecognizer) {
		let currentPoint = gesture.location(in: view)

		switch gesture.state {
		case .began:
			guard let rectView = selectionRectangleView else { return }
			let localPoint = view.convert(currentPoint, to: rectView)
			let hitArea = rectView.hitArea(for: localPoint)
			switch hitArea {
			case .corner(let corner):
				let rect = rectView.frame
				let fixedCorner: CGPoint
				switch corner {
				case .topLeft:     fixedCorner = CGPoint(x: rect.maxX, y: rect.maxY)
				case .topRight:    fixedCorner = CGPoint(x: rect.minX, y: rect.maxY)
				case .bottomLeft:  fixedCorner = CGPoint(x: rect.maxX, y: rect.minY)
				case .bottomRight: fixedCorner = CGPoint(x: rect.minX, y: rect.minY)
				}
				selectionInteraction = .resizing(fixedCorner: fixedCorner)
			case .inside:
				selectionInteraction = .moving(startPoint: currentPoint, startRect: rectView.frame)
			case .none:
				selectionInteraction = .none
			}

		case .changed:
			switch selectionInteraction {
			case .resizing(let fixedCorner):
				let width = max(abs(currentPoint.x - fixedCorner.x), 10)
				let height = max(abs(currentPoint.y - fixedCorner.y), 10)
				let x = currentPoint.x < fixedCorner.x ? fixedCorner.x - width : fixedCorner.x
				let y = currentPoint.y < fixedCorner.y ? fixedCorner.y - height : fixedCorner.y
				let newRect = CGRect(x: x, y: y, width: width, height: height)
				selectionRectangleView?.frame = newRect
				selectedAreaRect = newRect
			case .moving(let startPoint, let startRect):
				let dx = currentPoint.x - startPoint.x
				let dy = currentPoint.y - startPoint.y
				let newRect = startRect.offsetBy(dx: dx, dy: dy)
				selectionRectangleView?.frame = newRect
				selectedAreaRect = newRect
			case .none:
				break
			}

		case .ended, .cancelled, .failed:
			selectionInteraction = .none

		default:
			break
		}
	}

	// MARK: - View Finding

	private func findAppViews(in windowRect: CGRect) -> [UIView] {
		let appWindows = UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.flatMap(\.windows)
			.filter { !($0 is OverlayWindow) }

		var results: [UIView] = []
		for window in appWindows {
			let localRect = window.convert(windowRect, from: nil)
			collectViews(in: window, intersecting: localRect, results: &results)
		}
		return results
	}

	private func collectViews(in view: UIView, intersecting rect: CGRect, results: inout [UIView]) {
		let viewFrame = view.convert(view.bounds, to: view.window)
		let frameInWindow = view.window?.convert(viewFrame, to: nil) ?? viewFrame
		guard frameInWindow.intersects(rect) else { return }

		let parentIndex = results.count
		var childIntersected = false
		for child in view.subviews where !child.isHidden && child.alpha > 0 {
			let before = results.count
			collectViews(in: child, intersecting: rect, results: &results)
			if results.count > before {
				childIntersected = true
			}
		}

		if !childIntersected || view.agHasVisualStyling {
			results.insert(view, at: parentIndex)
		}
	}

	private func filterOversizedViews(_ views: [UIView], selectionRect: CGRect) -> [UIView] {
		let selectionArea = selectionRect.width * selectionRect.height
		guard selectionArea > 0 else { return views }
		return views.filter { view in
			guard let frameInWindow = view.agFrameInWindow else { return true }
			let containsSelection = frameInWindow.contains(selectionRect)
			let viewArea = frameInWindow.width * frameInWindow.height
			return !(containsSelection && viewArea > selectionArea * 4)
		}
	}

	// MARK: - Annotation

	private func saveAnnotation(_ text: String) {
		performAreaExport(note: text)
	}

	// MARK: - Area Selection

	private func enterAreaSelectedState() {
		overlayState = .areaSelected
		panGesture?.isEnabled = true
		selectionRectangleView?.handlesVisible = true
		toolbarView.setMode(.areaSelected)
		toolbarView.isHidden = false
	}

	private func confirmArea() {
		guard let areaRect = selectedAreaRect else { return }

		let windowRect = view.convert(areaRect, to: nil)

		// Capture metadata while overlay is still visible (no dependency on overlay state)
		let appViews = findAppViews(in: windowRect)
		let filteredViews = filterOversizedViews(appViews, selectionRect: windowRect)
		capturedAreaRecords = filteredViews.map { MetadataCapture.captureMetadata(for: $0) }

		// Find the app's content window (skip system windows like UITextEffectsWindow)
		let appWindow = UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.flatMap(\.windows)
			.first { !($0 is OverlayWindow) && $0.windowLevel == .normal }

		let overlayWindow = view.window
		overlayWindow?.isHidden = true

		if let appWindow {
			appWindow.makeKey()
			CATransaction.flush()

			DispatchQueue.main.async { [weak self] in
				self?.capturedFullScreenData = ScreenshotCapture.captureFullScreen(window: appWindow)
				self?.capturedAreaData = ScreenshotCapture.captureRect(windowRect, in: appWindow)
				overlayWindow?.makeKeyAndVisible()
				self?.enterNotingState()
			}
		} else {
			overlayWindow?.makeKeyAndVisible()
			enterNotingState()
		}
	}

	private func enterNotingState() {
		overlayState = .noting
		toolbarView.isHidden = true
		annotationInputView.show()
	}

	private func redoAreaSelection() {
		selectionInteraction = .none
		selectionRectangleView?.handlesVisible = false
		selectionRectangleView?.removeFromSuperview()
		selectionRectangleView = nil
		selectedAreaRect = nil
		capturedFullScreenData = nil
		capturedAreaData = nil
		capturedAreaRecords = []

		overlayState = .idle
		panGesture?.isEnabled = true
		toolbarView.setMode(.idle)
	}

	// MARK: - Export

	private func performAreaExport(note: String) {
		annotationInputView.hide()

		let baseDir = URL(fileURLWithPath: "/tmp/UICrit", isDirectory: true)
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH-mm-ss"
		let timestampDir = baseDir.appendingPathComponent(dateFormatter.string(from: Date()), isDirectory: true)
		try? FileManager.default.createDirectory(at: timestampDir, withIntermediateDirectories: true)
		let latestLink = baseDir.appendingPathComponent("latest")
		try? FileManager.default.removeItem(at: latestLink)
		try? FileManager.default.createSymbolicLink(at: latestLink, withDestinationURL: timestampDir)
		let exportDir = timestampDir

		if let data = capturedFullScreenData {
			try? data.write(to: exportDir.appendingPathComponent("fullscreen.jpg"))
		}
		if let data = capturedAreaData {
			try? data.write(to: exportDir.appendingPathComponent("area.jpg"))
		}

		let formatter = ISO8601DateFormatter()
		let areaRect = selectedAreaRect ?? .zero
		let windowRect = view.convert(areaRect, to: nil)
		let elements = capturedAreaRecords.map { record in
			ExportElement(
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
				annotation: nil,
				screenshotFilename: nil
			)
		}

		let payload = AreaExportPayload(
			schemaVersion: "1.2.0",
			timestamp: formatter.string(from: Date()),
			note: note,
			selectedArea: ExportFrame(
				x: windowRect.origin.x, y: windowRect.origin.y,
				width: windowRect.size.width, height: windowRect.size.height
			),
			fullScreenFilename: "fullscreen.jpg",
			areaFilename: "area.jpg",
			elements: elements
		)

		let jsonURL = exportDir.appendingPathComponent("export.json")
		let markdownURL = exportDir.appendingPathComponent("export.md")

		do {
			let encoder = JSONEncoder()
			encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
			let jsonData = try encoder.encode(payload)
			try jsonData.write(to: jsonURL)
			let markdown = AreaMarkdownExporter.export(payload: payload)
			try markdown.write(to: markdownURL, atomically: true, encoding: .utf8)
			print("[UICrit] ========================================")
			print("[UICrit] Area Export Complete")
			print("[UICrit] Export directory: \(exportDir.path)")
			print("[UICrit] ========================================")
		} catch {
			print("[UICrit] Export failed: \(error)")
		}

		UICrit.deactivate()
	}
}
