import UIKit

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
			selectionRectangleView?.removeFromSuperview()
			selectionRectangleView = nil
			dragStartPoint = nil

			guard rect.width > 10, rect.height > 10 else { return }

			let windowRect = view.convert(rect, to: nil)
			let appViews = findAppViews(in: windowRect)
			guard !appViews.isEmpty else { return }

			clearHighlights()
			selectedViews = appViews

			for appView in appViews {
				let record = MetadataCapture.captureMetadata(for: appView)
				session.addRecord(record)
				addHighlight(for: appView, record: record)
			}

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

	// MARK: - Annotation

	private func showAnnotationInput() {
		guard !selectedViews.isEmpty else { return }
		toolbarView.isHidden = true
		annotationInputView.show()
	}

	private func saveAnnotation(_ text: String) {
		for selectedView in selectedViews {
			session.annotate(view: selectedView, text: text)
		}
		annotationInputView.hide()
		toolbarView.isHidden = false
		performExport()
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
}
