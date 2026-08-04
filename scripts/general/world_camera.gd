extends Camera2D

## 相机视角移动时的速度
@export var move_speed: int = 500
## 鼠标指针距屏幕边缘多少像素内视为触发边缘滚动
@export var edge_threshold: int = 100


func _ready() -> void:
	WorldEventBus.world_limit_data_changed.connect(_on_world_limit_data_changed)


func _process(delta: float) -> void:
	var move_direction := get_mouse_edge_direction()
	position += move_direction * move_speed * delta
	# 把相机中心钳制在 limit 范围内，避免 position 越界累积，导致反向移动需先"追回"越界距离
	clamp_position_to_limits()


## 根据鼠标指针在屏幕边缘阈值内的深度计算移动方向与强度（越靠近边缘速度越快，指针回到阈值内则停止）
func get_mouse_edge_direction() -> Vector2:
	var mouse_pos := get_viewport().get_mouse_position()
	var screen_size := get_viewport_rect().size
	var direction := Vector2.ZERO

	# 水平：指针进入左/右边缘阈值区域时产生对应方向分量
	if mouse_pos.x < edge_threshold:
		direction.x = -1.0 + mouse_pos.x / edge_threshold
	elif mouse_pos.x > screen_size.x - edge_threshold:
		direction.x = (mouse_pos.x - (screen_size.x - edge_threshold)) / edge_threshold

	# 垂直：指针进入上/下边缘阈值区域时产生对应方向分量
	if mouse_pos.y < edge_threshold:
		direction.y = -1.0 + mouse_pos.y / edge_threshold
	elif mouse_pos.y > screen_size.y - edge_threshold:
		direction.y = (mouse_pos.y - (screen_size.y - edge_threshold)) / edge_threshold

	# 窗口模式下鼠标可能位于窗口外，分量可能超出 [-1, 1]，钳制防止相机滚动过快
	return direction.clamp(Vector2(-1.0, -1.0), Vector2(1.0, 1.0))


## 将相机中心钳制在世界边界内（与 Camera2D 内置 limit 钳制逻辑一致）
func clamp_position_to_limits() -> void:
	var full_screen := get_viewport_rect().size * zoom
	var half_screen := full_screen * 0.5
	# 水平：世界宽度不小于视口时，中心限制在 [左+半屏, 右-半屏]；世界比视口窄时居中
	if limit_right - limit_left >= full_screen.x:
		position.x = clampf(position.x, limit_left + half_screen.x, limit_right - half_screen.x)
	else:
		position.x = (limit_left + limit_right) * 0.5
	# 垂直：同理
	if limit_bottom - limit_top >= full_screen.y:
		position.y = clampf(position.y, limit_top + half_screen.y, limit_bottom - half_screen.y)
	else:
		position.y = (limit_top + limit_bottom) * 0.5


func _on_world_limit_data_changed(left: int, right: int, top: int, bottom: int):
	limit_left = left
	limit_right = right
	limit_top = top
	limit_bottom = bottom
