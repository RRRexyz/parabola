extends RigidBody2D


@onready var _can_pickup_prompt: HBoxContainer = $CanPickupPrompt
@onready var _can_interact_area: Area2D = $CanInteractArea
@onready var _item_info: Control = $ItemInfo

var _is_mouse_on_item: bool = false
var _is_player_on_pickup_area: bool = false


func _ready() -> void:
	_can_pickup_prompt.hide()
	_item_info.hide()

	# 可拾取物品的Area2D检测到玩家进出时，修改可拾取提示的可见性
	_can_interact_area.body_entered.connect(_on_body_entered)
	_can_interact_area.body_exited.connect(_on_body_exited)

	# 当鼠标放置在物品附近时，修改物品名称与效果提示的可见性
	_can_interact_area.mouse_entered.connect(_on_mouse_entered)
	_can_interact_area.mouse_exited.connect(_on_mouse_exited)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("player_pickup_item") and _is_mouse_on_item and _is_player_on_pickup_area:
		ItemEventBus.throwable_item_picked_up.emit(self)


func _on_body_entered(body: Node2D):
	if body is Player:
		_can_pickup_prompt.show()
		_is_player_on_pickup_area = true


func _on_body_exited(body: Node2D):
	if body is Player:
		_can_pickup_prompt.hide()
		_is_player_on_pickup_area = false


func _on_mouse_entered():
	_item_info.show()
	_is_mouse_on_item = true


func _on_mouse_exited():
	_item_info.hide()
	_is_mouse_on_item = false
