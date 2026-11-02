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

## 预览线起点对应的世界坐标
var _item_world_position := Vector2.ZERO


func _ready() -> void:
	hide()
	
	ItemEventBus.throw_angle_preview_updated.connect(_on_throw_angle_preview_updated)


func _process(_delta: float) -> void:
	# 相机在玩家之后、UI 之前更新画布变换，放在这里换算可避免相机滚动时慢一帧
	if visible:
		global_position = get_viewport().get_canvas_transform() * _item_world_position


func _draw() -> void:
	var to = Vector2(
		from.x + total_length * cos(-deg_to_rad(angle_deg)),
		from.y + total_length * sin(-deg_to_rad(angle_deg))
	)
	# 绘制一条虚线
	draw_dashed_line(from, to, color, width, dash_length)


func _on_throw_angle_preview_updated(is_visible_: bool, throw_angle_deg: int, item_position: Vector2):
	if not is_visible_:
		hide()
		return

	_item_world_position = item_position
	angle_deg = throw_angle_deg
	# 立即换算一次，避免显示首帧使用旧位置；_process 会在相机更新后校正
	global_position = get_viewport().get_canvas_transform() * item_position
	show()
	queue_redraw()
