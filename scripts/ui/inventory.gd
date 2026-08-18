extends HBoxContainer


var slots: Array[InventorySlotNode]


func _ready() -> void:
	var slot_num := PlayerInventory.inventory.capacity
	for i in range(slot_num):
		var inventory_slot := get_node("InventorySlot%d" % (i + 1))
		slots.append(inventory_slot)

	PlayerInventory.inventory.slot_changed.connect(_on_slot_changed)


func _on_slot_changed(index: int, item: ItemData, quantity: int):
	slots[index].item = item
	slots[index].quantity = quantity
