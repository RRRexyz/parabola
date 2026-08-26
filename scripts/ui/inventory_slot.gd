class_name InventorySlotNode extends Button


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

@onready var _texture: TextureRect = $TextureRect
@onready var _label: Label = $Label


func _ready() -> void:
	_label.hide()


func _on_quantity_changed(value: int):
	if value > 0:
		_label.show()
		_label.text = str(value)
	else:
		_label.hide()


func _on_item_changed(value: ItemData):
	if value == null:
		_texture.texture = null
		return

	_texture.texture = value.icon
