@tool
extends Control


## 起点
@export var from := Vector2(0, 0)
## 总长度
@export var total_length := 300
## 旋转角
@export_range(0, 90) var angle_deg := 0
## 线条颜色
@export var color := Color.WHITE
## 线条宽度
@export var width := 2.0
## 每段虚线的长度
@export var dash_length := 10.0


func _ready() -> void:
	hide()
	
	ItemEventBus.charging_started.connect(_on_charging_started)


func _draw() -> void:
	var to = Vector2(
		from.x + total_length * cos(-deg_to_rad(angle_deg)),
		from.y + total_length * sin(-deg_to_rad(angle_deg))
	)
	# 绘制一条虚线
	draw_dashed_line(from, to, color, width, dash_length)


func _on_charging_started(throw_angle_deg: int, item_position: Vector2):
	angle_deg = throw_angle_deg
	global_position = item_position
	show()
