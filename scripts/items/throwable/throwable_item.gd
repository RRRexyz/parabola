extends RigidBody2D


@onready var can_pickup_prompt: HBoxContainer = $CanPickupPrompt
@onready var can_interact_area: Area2D = $CanInteractArea


func _ready() -> void:
	can_pickup_prompt.hide()

	# 可拾取物品的Area2D检测到玩家进出时，修改可拾取提示的可见性
	can_interact_area.body_entered.connect(_on_body_entered)
	can_interact_area.body_exited.connect(_on_body_exited)

	can_interact_area.mouse_entered.connect(_on_mouse_entered)
	can_interact_area.mouse_exited.connect(_on_mouse_exited)


func _on_body_entered(body: Node2D):
	if body is Player:
		can_pickup_prompt.show()


func _on_body_exited(body: Node2D):
	if body is Player:
		can_pickup_prompt.hide()


func _on_mouse_entered():
	pass


func _on_mouse_exited():
	pass
