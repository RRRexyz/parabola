extends HBoxContainer


@onready var _button_group := ButtonGroup.new()

var _slots: Array[InventorySlotNode]
## 用于区分对物品槽的选中是程序自动触发的还是用户手动选择的
var _auto_selecting: bool = false


func _ready() -> void:
	var slot_num := PlayerInventory.inventory.capacity
	# 所有物品槽添加到一个按钮组中，同一时间只能有0个或1个被选中
	for i in range(slot_num):
		var inventory_slot := get_node("InventorySlot%d" % (i + 1)) as InventorySlotNode
		_slots.append(inventory_slot)
		inventory_slot.button_group = _button_group
		# 已弃用：右键物品槽丢弃槽中所有物品，现改由 player_discard_item 输入丢弃手持的单个物品
		# inventory_slot.gui_input.connect(_on_gui_input.bind(i))
		inventory_slot.toggled.connect(_on_slot_toggled.bind(i))
	_button_group.allow_unpress = true

	PlayerInventory.inventory.slot_changed.connect(_on_slot_changed)


func _on_slot_changed(index: int, item: ItemData, quantity: int):
	_slots[index].item = item
	_slots[index].quantity = quantity

	# 有新物品进入该槽时（拾取/堆叠），自动选中该槽；item 为 null 是丢弃清空，跳过
	if item != null:
		_auto_selecting = true    # 拾取物体触发的程序化选中，不触发取出逻辑
		_slots[index].button_pressed = true
		_auto_selecting = false
	else:
		# 槽位被丢弃清空时，取消其选中状态
		_slots[index].button_pressed = false


# 已弃用：右键物品槽丢弃该槽中所有物品，现由玩家按下 player_discard_item 丢弃手持的单个物品
# func _on_gui_input(event: InputEvent, slot_index: int):
# 	if event is InputEventMouseButton:
# 		if event.pressed:
# 			if event.button_index == MOUSE_BUTTON_RIGHT:
# 				PlayerInventory.inventory.discard_items(slot_index)


func _on_slot_toggled(toggled_on: bool, slot_index: int):
	if toggled_on:
		if not _auto_selecting:
			ItemEventBus.slot_selected.emit(slot_index)
	else:
		ItemEventBus.slot_deselected.emit(slot_index)
