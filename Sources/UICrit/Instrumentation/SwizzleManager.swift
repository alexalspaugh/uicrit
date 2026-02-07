import UIKit

enum SwizzleManager {
	private static var isSwizzled = false
	private static var originalIMP: IMP?

	static func enable() {
		guard !isSwizzled else { return }
		guard let originalMethod = class_getInstanceMethod(UIView.self, #selector(UIView.didMoveToSuperview)) else { return }

		originalIMP = method_getImplementation(originalMethod)

		let swizzledBlock: @convention(block) (UIView) -> Void = { view in
			typealias OriginalFunc = @convention(c) (UIView, Selector) -> Void
			if let imp = SwizzleManager.originalIMP {
				let original = unsafeBitCast(imp, to: OriginalFunc.self)
				original(view, #selector(UIView.didMoveToSuperview))
			}
			NotificationCenter.default.post(name: .uicritViewDidMoveToSuperview, object: view)
		}

		let swizzledIMP = imp_implementationWithBlock(swizzledBlock)
		method_setImplementation(originalMethod, swizzledIMP)
		isSwizzled = true
	}

	static func disable() {
		guard isSwizzled, let originalIMP else { return }
		guard let method = class_getInstanceMethod(UIView.self, #selector(UIView.didMoveToSuperview)) else { return }

		method_setImplementation(method, originalIMP)
		self.originalIMP = nil
		isSwizzled = false
	}
}

extension Notification.Name {
	static let uicritViewDidMoveToSuperview = Notification.Name("uicritViewDidMoveToSuperview")
}
