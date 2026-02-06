import UIKit

@MainActor
final class OverlayViewController: UIViewController {
	private let session: Session
	private let highlightView = HighlightView()
	private let toolbarView = ToolbarView()
	private let annotationInputView = AnnotationInputView()
	private var selectedView: UIView?
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
		view.addGestureRecognizer(tapGesture)

		highlightView.isHidden = true
		highlightView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(highlightView)

		view.addSubview(toolbarView)
		NSLayoutConstraint.activate([
			toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			toolbarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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
		toolbarView.onExport = { [weak self] in
			self?.performExport()
		}
		toolbarView.onDone = {
			Agentation.deactivate()
		}

		annotationInputView.onSave = { [weak self] text in
			self?.saveAnnotation(text)
		}
	}

	@objc private func handleTap(_ gesture: UITapGestureRecognizer) {
		let point = gesture.location(in: view)
		guard let appView = findAppView(at: point) else { return }

		let record = MetadataCapture.captureMetadata(for: appView)
		session.addRecord(record)
		selectedView = appView

		if let frameInWindow = appView.agFrameInWindow {
			highlightView.isHidden = false
			highlightView.frame = frameInWindow
			highlightView.configure(
				className: record.className,
				accessibilityID: record.accessibilityIdentifier,
				propertyName: record.propertyName
			)
		}
	}

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

	private func showAnnotationInput() {
		guard selectedView != nil else { return }
		toolbarView.isHidden = true
		annotationInputView.show()
	}

	private func saveAnnotation(_ text: String) {
		if let selectedView {
			session.annotate(view: selectedView, text: text)
		}
		annotationInputView.hide()
		toolbarView.isHidden = false
	}

	private func performExport() {
		let coordinator = ExportCoordinator()
		Task { [weak self] in
			guard let session = self?.session else { return }
			if let result = await coordinator.export(session: session) {
				print("[Agentation] Export complete: \(result.directoryURL.path)")
				print("[Agentation] Markdown copied to clipboard")
			}
		}
	}
}
