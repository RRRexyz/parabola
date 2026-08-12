# 开发过程中的注意事项

1. BoxContainer(HBoxContainer/VBoxContainer)的子控件必须是继承自Control的节点，才会进行自动排列。非继承自Control的节点会被忽略（例如Sprite2D）。
2. godot_state_charts 的状态机事件处理与同帧内的场景树变更（reparent 等）互斥：先 reparent 再 send_event 会导致事件处理失效、状态不切换。必须先在稳定的树结构中 send_event，再执行树操作；若流程要求先改树，则对树操作使用 call_deferred 推迟到事件处理完成之后。