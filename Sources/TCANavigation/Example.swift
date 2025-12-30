import UIKit

final class PaymentCoordinator: Coordinator {

	@UIBindable var model = FeatureModel()

	override func start(transaction: UITransaction) {
		present(item: $model.destination.addItem) { addItemModel in
			AddItemViewController(model: addItemModel)
		}

		present(isPresented: $model.destination.deleteItemAlert) {
			let alert = UIAlertController(title: "Delete?", message: "Are you sure you want to delete this item?", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Yes", style: .destructive))
			alert.addAction(UIAlertAction(title: "No", style: .cancel))
			return alert
		}

		navigationDestination(item: $model.destination.editItem) { editItemModel in
			EditItemViewController(model: editItemModel)
		}
	}
}

@Perceptible
class FeatureModel {

	var destination: Destination?

	@CasePathable
	enum Destination {
		case addItem(AddItemModel)
		case deleteItemAlert
		case editItem(EditItemModel)
	}
}

struct AddItemModel: Identifiable {

	let id = UUID()
	var name: String = ""
}

struct EditItemModel: Identifiable {

	let id = UUID()
	var name: String = ""
}

class AddItemViewController: UIViewController {

	let model: AddItemModel

	init(model: AddItemModel) {
		self.model = model
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class EditItemViewController: UIViewController {

	let model: EditItemModel

	init(model: EditItemModel) {
		self.model = model
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
