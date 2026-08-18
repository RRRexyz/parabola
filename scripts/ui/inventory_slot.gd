class_name InventorySlotNode extends Panel


var item: ItemData:
	set(value):
		if item != value:
			item = value
			_on_item_changed(value)
var quantity: int = 0:
	set(value):
		if quantity != value:
			quantity = value
			_on_quantity_changed(value)

@onready var texture: TextureRect = $TextureRect
@onready var label: Label = $Label


func _ready() -> void:
	label.hide()


func _on_quantity_changed(value: int):
	if value > 0:
		label.show()
	label.text = str(value)


func _on_item_changed(value: ItemData):
	texture.texture = value.icon
