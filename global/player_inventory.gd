extends Node


@onready var inventory := Inventory.new()
	

## 单个物品槽数据类
class InventorySlot extends Node:
	var item: ItemData
	var quantity: int = 0


	func _init(item_: ItemData, quantity_: int = 1) -> void:
		item = item_
		quantity = quantity_


## 物品栏行为类
class Inventory extends Node:
	var capacity: int = 6
	var slots: Array[InventorySlot]

	signal slot_changed(index: int, item: ItemData, quantity: int)
	signal slots_full


	func _init() -> void:
		slots.resize(capacity)


	func add_item(item: ItemData) -> bool:
		# 先尝试堆叠到已有物品
		if item.max_stack_size > 1:
			for i in range(capacity):
				if slots[i] != null and slots[i].item.type_name == item.type_name and slots[i].quantity < item.max_stack_size:
					slots[i].quantity += 1
					slot_changed.emit(i, item, slots[i].quantity)
					return true
		
		# 放不下再找空位
		var empty_index := _find_empty_slot()
		if empty_index == -1:
			slots_full.emit()
			return false
		slots[empty_index] = InventorySlot.new(item)
		slot_changed.emit(empty_index, item, slots[empty_index].quantity)
		return true


	func _find_empty_slot() -> int:
		for i in range(capacity):
			if slots[i] == null:
				return i
		return -1


	func remove_item(index: int):
		slots[index].quantity =  0
		slots[index].item = null
		slot_changed.emit(index, null, 0)
