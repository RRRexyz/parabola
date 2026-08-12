extends CharacterBody2D
class_name Player


## 玩家左右移动速度
@export var move_speed: int = 350
## 玩家跳跃时离地初速度
@export var jump_speed: int = 500

@onready var _hand_slot: Node2D = $HandSlot

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var held_item: RigidBody2D = null


func _ready() -> void:
	ItemEventBus.throwable_item_picked_up.connect(_on_throwable_item_picked_up)


func _physics_process(delta: float) -> void:
	basic_movement_control(delta)


func basic_movement_control(delta: float):
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
	# 防止重复拾取
	if held_item != null:
		return
	else:
		held_item = throwable_item
		throwable_item.freeze = true
		throwable_item.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		throwable_item.reparent(_hand_slot)
		throwable_item.position = Vector2.ZERO
