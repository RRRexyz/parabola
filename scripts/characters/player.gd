class_name Player extends CharacterBody2D


## 玩家左右移动速度
@export var move_speed: int = 350
## 玩家跳跃时离地初速度
@export var jump_speed: int = 500

@onready var _hand_slot: Node2D = $HandSlot
@onready var _inventory_slot: Node2D = $InventorySlot
@onready var _inventory_slots_full_prompt: Label = $InventorySlotsFullPrompt

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var held_item: RigidBody2D = null


func _ready() -> void:
	_inventory_slots_full_prompt.hide()

	# 拾起物品后将其挂载到HandSlot节点，原本挂载到HandSlot节点的物品会被挂载到InventorySlot节点
	ItemEventBus.throwable_item_picked_up.connect(_on_throwable_item_picked_up)
	# 物品栏满后继续拾取物品，展示已满提示2秒
	PlayerInventory.inventory.slots_full.connect(_on_inventory_slots_full)


func _physics_process(delta: float) -> void:
	_basic_movement_control(delta)


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
	if held_item != null:
		held_item.hide()
		held_item.reparent(_inventory_slot)
	held_item = throwable_item
	throwable_item.freeze = true
	throwable_item.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	throwable_item.reparent(_hand_slot)
	throwable_item.position = Vector2.ZERO


func _on_inventory_slots_full():
	_inventory_slots_full_prompt.show()
	await get_tree().create_timer(2.0).timeout
	_inventory_slots_full_prompt.hide()