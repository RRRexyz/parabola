class_name Player extends CharacterBody2D


## 玩家左右移动速度
@export var move_speed: int = 350
## 玩家跳跃时离地初速度
@export var jump_speed: int = 500

@onready var _hand_slot: Node2D = $HandSlot
@onready var _inventory_slot: Node2D = $InventorySlot
@onready var _inventory_slots_full_prompt: Label = $InventorySlotsFullPrompt

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var held_item: RigidBody2D
## 丢弃落点的左右交替方向，见 _on_item_discarded
var _discard_side := 1


func _ready() -> void:
	_inventory_slots_full_prompt.hide()

	# 拾起物品后将其挂载到HandSlot节点，原本挂载到HandSlot节点的物品会被挂载到InventorySlot节点
	ItemEventBus.throwable_item_picked_up.connect(_on_throwable_item_picked_up)
	# 当物品槽被取消选中时，将手上的物品存入物品槽中
	ItemEventBus.slot_deselected.connect(_on_slot_deselected)
	# 
	ItemEventBus.slot_selected.connect(_on_slot_selected)
	# 物品栏满后继续拾取物品，展示已满提示2秒
	PlayerInventory.inventory.slots_full.connect(_on_inventory_slots_full)
	# 丢弃物品槽中的物品到地上
	PlayerInventory.inventory.item_discarded.connect(_on_item_discarded)


func _physics_process(delta: float) -> void:
	_basic_movement_control(delta)


func _process(_delta: float) -> void:
	# 按下丢弃键时丢弃当前手持的单个物品；空手时不动作
	# 物理还原（清手持、状态机、reparent 回世界）由 _on_item_discarded 统一处理
	if Input.is_action_just_pressed("player_discard_item") and held_item != null:
		var discarded := held_item
		var slot_index := PlayerInventory.inventory.get_slot_index_of(discarded)
		PlayerInventory.inventory.discard_item(discarded)
		# 丢弃后若槽位仍有堆叠物品，自动取出下一个上手；槽位已空则由 UI 取消选中（见 inventory.gd）
		var next_item := PlayerInventory.inventory.get_latest_item(slot_index)
		if next_item != null and next_item != discarded:	# 防御：数据异常时避免取回刚丢弃的同一节点
			_take_item(next_item)


func _basic_movement_control(delta: float):
	# 如果玩家在地面上，允许跳跃，不跳跃则纵向速度清零
	if is_on_floor():
		if Input.is_action_just_pressed("player_jump"):
			velocity.y = -jump_speed
		else:
			velocity.y = 0
	# 如果玩家不在地面上，应用重力
	else:
		velocity.y += _gravity * delta

	# 左右移动
	var move_direction := Input.get_axis("player_move_left", "player_move_right")
	velocity.x = move_direction * move_speed

	move_and_slide()


func _on_throwable_item_picked_up(throwable_item: RigidBody2D):
	_store_held_item()

	held_item = throwable_item
	throwable_item.freeze = true
	throwable_item.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	throwable_item.reparent(_hand_slot)
	throwable_item.position = Vector2.ZERO


func _on_inventory_slots_full():
	_inventory_slots_full_prompt.show()
	await get_tree().create_timer(2.0).timeout
	_inventory_slots_full_prompt.hide()


func _on_item_discarded(item: RigidBody2D, spread_index: int):
	# 丢弃的槽位里包含手持节点时清空手
	if held_item == item: 
		held_item = null
	
	item.state_chart.send_event("discard")
	item.show()
	item.freeze = false
	item.sleeping = false					# 显式唤醒，防止解冻后仍保持睡眠
	item.linear_velocity = Vector2.ZERO	# 清掉拾取前残留的速度，丢弃应从静止开始下落
	item.angular_velocity = 0.0
	item.can_pickup = true
	item.reparent(item.world_parent_node)
	# 落点向手的侧方偏移并左右交替：丢弃后若自动上手了新物品，两者位置错开，
	# 防止被丢弃物品落在手持物品顶上而悬空（冻结的手持物对物理引擎是支撑平台）
	var offset_x := spread_index * 48.0 + _discard_side * 30.0 + randf_range(-6.0, 6.0)
	_discard_side = -_discard_side
	item.global_position = _hand_slot.global_position + Vector2(offset_x, -8.0)


func _on_slot_deselected(slot_index: int):
	# 仅当选中的正是手持物品所在槽时才收纳，防止拾取级联中重复收纳
	if PlayerInventory.inventory.get_slot_index_of(held_item) == slot_index:
		_store_held_item()


func _store_held_item():
	if held_item == null:
		return
	# 先发状态机事件，再做树操作，原因见percautions.md[2]
	held_item.state_chart.send_event("store")
	held_item.hide()
	held_item.reparent(_inventory_slot)
	held_item = null
	

func _on_slot_selected(slot_index: int):
	var item := PlayerInventory.inventory.get_latest_item(slot_index)
	if item == null or item == held_item:
		return 						# 空槽或本来就在手上，直接返回
	_store_held_item()              # 收纳旧手持（其数据仍在原槽，不丢）
	_take_item(item)


## 将物品节点拿到手上（调用前确保该物品不在手上）
func _take_item(item: RigidBody2D):
	# 先发状态机事件，再操作树，原因见percautions.md[2]
	item.state_chart.send_event("take")
	item.freeze = true
	item.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	item.show()
	item.reparent(_hand_slot)
	item.position = Vector2.ZERO
	held_item = item
