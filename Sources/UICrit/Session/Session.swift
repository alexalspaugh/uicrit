import UIKit

@MainActor
final class Session {
	private(set) var records: [ElementRecord] = []

	func addRecord(_ record: ElementRecord) {
		if let index = records.firstIndex(where: { $0.view === record.view && record.view != nil }) {
			records[index] = record
		} else {
			records.append(record)
		}
	}

	func record(for view: UIView) -> ElementRecord? {
		records.first(where: { $0.view === view })
	}

	func annotate(view: UIView, text: String) {
		guard let index = records.firstIndex(where: { $0.view === view }) else { return }
		records[index].annotation = Annotation(text: text, createdAt: Date())
	}

	func clear() {
		records.removeAll()
	}
}
