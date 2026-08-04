extends Node2D


# 关卡世界的有效范围，通过四个边缘碰撞墙获取，用于限定相机滚动极限
var left_limit: int = -10000000
var right_limit: int = 10000000
var top_limit: int = -10000000
# 注：下边界为禁用的碰撞墙，仅做获取世界范围用
var bottom_limit: int = 10000000


func _ready() -> void:
	left_limit = $LeftLimitWall/CollisionShape2D.position.x
	right_limit = $RightLimitWall/CollisionShape2D.position.x
	top_limit = $TopLimitWall/CollisionShape2D.position.y
	bottom_limit = $BottomLimitWall/CollisionShape2D.position.y

	# 延迟到本帧结束时再广播：若在 _ready 中同步 emit，会早于其他节点（如相机）的 _ready 连接，导致接收方错过信号
	WorldEventBus.world_limit_data_changed.emit.call_deferred(left_limit, right_limit, top_limit, bottom_limit)
