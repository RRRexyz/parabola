# 开发过程中的注意事项

1. BoxContainer(HBoxContainer/VBoxContainer)的子控件必须是继承自Control的节点，才会进行自动排列。非继承自Control的节点会被忽略（例如Sprite2D）。
2. godot_state_charts 的状态机事件处理与同帧内的场景树变更（reparent 等）互斥：先 reparent 再 send_event 会导致事件处理失效、状态不切换。必须先在稳定的树结构中 send_event，再执行树操作；若流程要求先改树，则对树操作使用 call_deferred 推迟到事件处理完成之后。
3. 冻结（freeze，KINEMATIC 模式）的 RigidBody2D 对其他刚体来说是静止的支撑平台。如果把一个解冻后的刚体传送到与冻结刚体相同的坐标（例如丢弃物品与自动上手的物品同在手部位置），解重叠后自由刚体可能恰好平衡在冻结刚体顶上，表现为“悬在空中不落地”。此类传送落点必须与冻结刚体错开（如 _on_item_discarded 中的水平交替偏移）。