import UIKit

@available(iOS 26, *)
@MainActor
public final class Agentation {

	private static let shared = Agentation()

	private var isInstalled = false
	private var isActive = false
	private var activationNotification: Notification.Name?
	private var autoInstrument = false
	private var notificationObserver: Any?
	private var session: Session?
	private var overlayWindow: OverlayWindow?

	private init() {}

	public static func install(
		activationNotification: Notification.Name? = nil,
		autoInstrument: Bool = false
	) {
		shared.performInstall(
			activationNotification: activationNotification,
			autoInstrument: autoInstrument
		)
	}

	public static func activate() { shared.performActivate() }
	public static func deactivate() { shared.performDeactivate() }
	public static func toggle() {
		if shared.isActive { deactivate() } else { activate() }
	}

	private func performInstall(activationNotification: Notification.Name?, autoInstrument: Bool) {
		guard !isInstalled else { return }
		isInstalled = true
		self.activationNotification = activationNotification
		self.autoInstrument = autoInstrument

		if let activationNotification {
			notificationObserver = NotificationCenter.default.addObserver(
				forName: activationNotification,
				object: nil,
				queue: .main
			) { [weak self] _ in
				MainActor.assumeIsolated {
					self?.performToggle()
				}
			}
		}
	}

	private func performActivate() {
		guard isInstalled, !isActive else { return }
		isActive = true

		let newSession = Session()
		session = newSession

		guard
			let scene = UIApplication.shared.connectedScenes
				.compactMap({ $0 as? UIWindowScene })
				.first(where: { $0.activationState == .foregroundActive })
		else { return }

		let window = OverlayWindow(scene: scene)
		let viewController = OverlayViewController(session: newSession)
		window.rootViewController = viewController
		window.makeKeyAndVisible()
		overlayWindow = window

		if autoInstrument {
			SwizzleManager.enable()
		}
	}

	private func performDeactivate() {
		guard isActive else { return }
		isActive = false

		if autoInstrument {
			SwizzleManager.disable()
		}

		overlayWindow?.isHidden = true
		overlayWindow?.rootViewController = nil
		overlayWindow = nil
		session?.clear()
		session = nil
	}

	private func performToggle() {
		if isActive { performDeactivate() } else { performActivate() }
	}
}
