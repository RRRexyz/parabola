extends RigidBody2D

## 物品是否可被玩家拾取
@export var can_pickup: bool = true
## 物品信息
@export var item_data: ItemData

@onready var _can_pickup_prompt: HBoxContainer = $CanPickupPrompt
@onready var _can_interact_area: Area2D = $CanInteractArea
@onready var _item_info: Control = $ItemInfo
@onready var _state_chart: StateChart = $StateChart
@onready var _pickup_transition: Transition = $StateChart/CompoundState/OnGround/GroundToHand

var _is_mouse_on_item: bool = false
var _player_in_range: Player = null


func _ready() -> void:
	_can_pickup_prompt.hide()
	_item_info.hide()

	# 可拾取物品的Area2D检测到玩家进出时，修改可拾取提示的可见性
	_can_interact_area.body_entered.connect(_on_body_entered)
	_can_interact_area.body_exited.connect(_on_body_exited)

	# 当鼠标放置在物品附近时，修改物品名称与效果提示的可见性
	_can_interact_area.mouse_entered.connect(_on_mouse_entered)
	_can_interact_area.mouse_exited.connect(_on_mouse_exited)

	# 当物品被拾取后，隐藏可拾取提示并且变为不可拾取状态
	_pickup_transition.taken.connect(_on_pickup_transition)


func _process(_delta: float) -> void:
	# 拾取物品需要满足的条件：
	# 1. 按下快捷键（默认鼠标左键）
	# 2. 鼠标指针位于物品可拾取范围内
	# 3. 有玩家位于物品可拾取范围内
	# 4. 物品允许拾取
	if Input.is_action_just_pressed("player_pickup_item") and _is_mouse_on_item and _player_in_range != null and can_pickup:
		if PlayerInventory.inventory.add_item(item_data):
			# 此处必须先让状态机发送事件，然后再让玩家节点对当前物品节点进行重挂载，原因见percautions.md[2]
			_state_chart.send_event("pickup")
			ItemEventBus.throwable_item_picked_up.emit(self)


func _on_body_entered(body: Node2D):
	if body is Player:
		_player_in_range = body
		if can_pickup:
			_can_pickup_prompt.show()


func _on_body_exited(body: Node2D):
	if body is Player:
		_player_in_range = null
		_can_pickup_prompt.hide()


func _on_mouse_entered():
	_item_info.show()
	_is_mouse_on_item = true


func _on_mouse_exited():
	_item_info.hide()
	_is_mouse_on_item = false


func _on_pickup_transition():
	_can_pickup_prompt.hide()
	can_pickup = false
