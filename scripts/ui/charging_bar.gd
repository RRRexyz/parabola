extends Control


func _ready() -> void:
	hide()

	# 开始蓄力时，显示蓄力条
	ItemEventBus.charging_started.connect(_on_charging_started)


func _on_charging_started(_throw_angle_deg: int, _item_position: Vector2):
	show()
