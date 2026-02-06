import UIKit

@available(iOS 26, *)
@MainActor
final class OverlayViewController: UIViewController {
	private let session: Session
	private let toolbarView = ToolbarView()
	private let annotationInputView = AnnotationInputView()
	private var highlightViews: [HighlightView] = []
	private var selectedViews: [UIView] = []
	private var selectionRectangleView: SelectionRectangleView?
	private var dragStartPoint: CGPoint?
	private var annotationBottomConstraint: NSLayoutConstraint?
	private var panGesture: UIPanGestureRecognizer?
	private var tapGesture: UITapGestureRecognizer?

	private enum OverlayState {
		case idle
		case areaSelected
		case noting
	}

	private var overlayState: OverlayState = .idle
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

		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
		let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
		panGesture.minimumNumberOfTouches = 1
		panGesture.maximumNumberOfTouches = 1
		tapGesture.require(toFail: panGesture)
		view.addGestureRecognizer(tapGesture)
		view.addGestureRecognizer(panGesture)
		self.tapGesture = tapGesture
		self.panGesture = panGesture

		view.addSubview(toolbarView)
		NSLayoutConstraint.activate([
			toolbarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			toolbarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
		])

		view.addSubview(annotationInputView)
		let annotationBottom = annotationInputView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		annotationBottomConstraint = annotationBottom
		annotationInputView.setBottomConstraint(annotationBottom)
		NSLayoutConstraint.activate([
			annotationInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			annotationInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			annotationBottom,
		])

		toolbarView.onAnnotate = { [weak self] in
			self?.showAnnotationInput()
		}
		toolbarView.onDone = {
			Agentation.deactivate()
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

	// MARK: - Tap Selection

	@objc private func handleTap(_ gesture: UITapGestureRecognizer) {
		let point = gesture.location(in: view)
		guard let appView = findAppView(at: point) else { return }

		let record = MetadataCapture.captureMetadata(for: appView)
		session.addRecord(record)

		clearHighlights()
		selectedViews = [appView]
		addHighlight(for: appView, record: record)
	}

	// MARK: - Drag Selection

	@objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
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

	// MARK: - Highlights

	private func clearHighlights() {
		for highlightView in highlightViews {
			highlightView.removeFromSuperview()
		}
		highlightViews.removeAll()
		selectedViews.removeAll()
	}

	private func addHighlight(for appView: UIView, record: ElementRecord) {
		guard let frameInWindow = appView.agFrameInWindow else { return }
		let highlightView = HighlightView()
		highlightView.frame = frameInWindow
		highlightView.configure(
			className: record.className,
			accessibilityID: record.accessibilityIdentifier,
			propertyName: record.propertyName
		)
		view.insertSubview(highlightView, belowSubview: toolbarView)
		highlightView.updateLabelPosition(containerBounds: view.bounds)
		highlightView.animateIn()
		highlightViews.append(highlightView)
	}

	// MARK: - View Finding

	private func findAppView(at point: CGPoint) -> UIView? {
		let windowPoint = view.convert(point, to: nil)
		let appWindows = UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.flatMap(\.windows)
			.filter { !($0 is OverlayWindow) }
			.sorted { $0.windowLevel.rawValue > $1.windowLevel.rawValue }

		for window in appWindows {
			let windowLocalPoint = window.convert(windowPoint, from: nil)
			if let hit = window.hitTest(windowLocalPoint, with: nil) {
				return hit
			}
		}
		return nil
	}

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

		var childIntersected = false
		for child in view.subviews where !child.isHidden && child.alpha > 0 {
			let before = results.count
			collectViews(in: child, intersecting: rect, results: &results)
			if results.count > before {
				childIntersected = true
			}
		}

		if !childIntersected {
			results.append(view)
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

	private func showAnnotationInput() {
		guard !selectedViews.isEmpty else { return }
		toolbarView.isHidden = true
		annotationInputView.show()
	}

	private func saveAnnotation(_ text: String) {
		if overlayState == .noting {
			performAreaExport(note: text)
			return
		}
		for selectedView in selectedViews {
			session.annotate(view: selectedView, text: text)
		}
		annotationInputView.hide()
		toolbarView.isHidden = false
		performExport()
	}

	// MARK: - Area Selection

	private func enterAreaSelectedState() {
		overlayState = .areaSelected
		panGesture?.isEnabled = false
		tapGesture?.isEnabled = false
		clearHighlights()
		toolbarView.setMode(.confirmArea)
		toolbarView.isHidden = false
	}

	private func confirmArea() {
		guard let areaRect = selectedAreaRect else { return }

		let appWindows = UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.flatMap(\.windows)
			.filter { !($0 is OverlayWindow) }
			.sorted { $0.windowLevel.rawValue > $1.windowLevel.rawValue }

		let windowRect = view.convert(areaRect, to: nil)

		let overlayWindow = view.window
		overlayWindow?.isHidden = true

		if let appWindow = appWindows.first {
			capturedFullScreenData = ScreenshotCapture.captureFullScreen(window: appWindow)
			capturedAreaData = ScreenshotCapture.captureRect(windowRect, in: appWindow)
		}

		overlayWindow?.isHidden = false

		let appViews = findAppViews(in: windowRect)
		let filteredViews = filterOversizedViews(appViews, selectionRect: windowRect)
		capturedAreaRecords = filteredViews.map { MetadataCapture.captureMetadata(for: $0) }

		enterNotingState()
	}

	private func enterNotingState() {
		overlayState = .noting
		toolbarView.isHidden = true
		annotationInputView.show()
	}

	private func redoAreaSelection() {
		selectionRectangleView?.removeFromSuperview()
		selectionRectangleView = nil
		selectedAreaRect = nil
		capturedFullScreenData = nil
		capturedAreaData = nil
		capturedAreaRecords = []

		overlayState = .idle
		panGesture?.isEnabled = true
		tapGesture?.isEnabled = true
		toolbarView.setMode(.defaultMode)
	}

	// MARK: - Export

	private func performExport() {
		let coordinator = ExportCoordinator()
		Task { [weak self] in
			guard let session = self?.session else { return }
			if let result = await coordinator.export(session: session) {
				print("[Agentation] ========================================")
				print("[Agentation] Export Complete")
				print("[Agentation] ========================================")
				print(result.markdownString)
				print("[Agentation] ========================================")
				print("[Agentation] Export directory: \(result.directoryURL.path)")
				print("[Agentation] ========================================")
			}
		}
	}

	private func performAreaExport(note: String) {
		annotationInputView.hide()

		let baseDir = URL(fileURLWithPath: "/tmp/Agentation", isDirectory: true)
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
			schemaVersion: "1.1.0",
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
			print("[Agentation] ========================================")
			print("[Agentation] Area Export Complete")
			print("[Agentation] Export directory: \(exportDir.path)")
			print("[Agentation] ========================================")
		} catch {
			print("[Agentation] Export failed: \(error)")
		}

		Agentation.deactivate()
	}
}
