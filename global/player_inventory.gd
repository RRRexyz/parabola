extends Node


@onready var inventory := Inventory.new()
	

## 单个物品槽数据类
class InventorySlot extends RefCounted:
	var item_data: ItemData			# 物品数据
	var quantity: int = 0
	var items: Array[RigidBody2D]	# 放到该槽中的所有物品节点


	func _init(item_data_: ItemData, quantity_: int = 1) -> void:
		item_data = item_data_
		quantity = quantity_


## 物品栏行为类
class Inventory extends Node:
	var capacity: int = 6
	var slots: Array[InventorySlot]

	signal slot_changed(index: int, item: ItemData, quantity: int)
	signal slots_full
	## spread_index 用于把多个物品错开摆放
	signal item_discarded(item: RigidBody2D, spread_index: int)


	func _init() -> void:
		slots.resize(capacity)


	func add_item(item: RigidBody2D) -> bool:
		# 防御：同一节点不应重复注册；重复注册会导致丢弃后自动上手逻辑错误地取回刚丢弃的节点
		if get_slot_index_of(item) != -1:
			return true
		var item_data: ItemData = item.item_data

		# 先尝试堆叠到已有物品
		if item_data.max_stack_size > 1:
			for i in range(capacity):
				if slots[i] != null and slots[i].item_data.type_name == item_data.type_name and slots[i].quantity < item_data.max_stack_size:
					slots[i].quantity += 1
					slots[i].items.append(item)
					slot_changed.emit(i, item_data, slots[i].quantity)
					return true
		
		# 放不下再找空位
		var empty_index := _find_empty_slot()
		if empty_index == -1:
			slots_full.emit()
			return false
		slots[empty_index] = InventorySlot.new(item_data)
		slots[empty_index].items.append(item)
		slot_changed.emit(empty_index, item_data, slots[empty_index].quantity)
		return true


	func _find_empty_slot() -> int:
		for i in range(capacity):
			if slots[i] == null:
				return i
		return -1


	## 已弃用：整格丢弃（现改为丢弃手持的单个物品，见 discard_item）；保留代码暂不删除
	func discard_items(index: int) -> void:
		var slot := slots[index]
		if slot == null or slot.quantity <= 0:
			return
		
		var items := slot.items.duplicate()
		slot.items.clear()
		slot.quantity = 0
		slot.item_data = null
		slots[index] = null
		slot_changed.emit(index, null, 0)
		for i in range(items.size()):
			item_discarded.emit(items[i], i)

	
	func get_slot_index_of(item: RigidBody2D) -> int:
		for i in range(capacity):
			if slots[i] != null and slots[i].items.has(item):
				return i
		return -1


	func get_latest_item(index: int) -> RigidBody2D:
		if index < 0 or index >= capacity or slots[index] == null or slots[index].items.is_empty():
			return null
		return slots[index].items.back()


	## 丢弃单个物品节点（丢弃手持物品时使用）
	## 从所在槽位移除该节点；槽位清空后整个槽位置空
	func discard_item(item: RigidBody2D) -> void:
		var index := get_slot_index_of(item)
		if index == -1:
			return
		var slot := slots[index]
		slot.items.erase(item)
		slot.quantity -= 1
		if slot.quantity == 0:
			slots[index] = null
			slot_changed.emit(index, null, 0)
		else:
			slot_changed.emit(index, slot.item_data, slot.quantity)
		item_discarded.emit(item, 0)
