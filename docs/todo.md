# 待办事项

- 手持可投掷物品蓄力时显示投掷抛物线预览轨迹。
- 投掷物品。

# 投掷蓄力系统方案

## 1. 总体架构与职责划分

按项目既有的“组件 + 事件总线 + 哑渲染 UI”模式拆分为四块：

| 模块 | 位置建议 | 职责 |
|---|---|---|
| 投掷控制器 | `scripts/characters/throw_charger.gd`，挂在 Player 下的组件节点 | 蓄力状态机、输入判定、守卫检查、角度/力度计算、发出投掷指令 |
| 力度滑条 UI | `scenes/ui/charge_slider.tscn`（Control 自绘），挂现有 Ui 场景的 CanvasLayer | 屏幕空间，只做渲染，值由控制器喂 |
| 抛物线预览 | `scripts/ui/trajectory_preview.gd`（Node2D + `_draw()`），挂 World 下 | 世界空间虚线，每帧根据角度+力度重算 |
| 数据层/状态机 | `player_inventory.gd`、`throwable_item.tscn` 状态图 | 物品离手的数据移除与 OnThrown 飞行态 |

推荐用独立组件而不是塞进 `player.gd`：投掷是自成一体的状态机，独立后 `player.gd` 只负责接线（手持变化通知组件、组件回调投掷）。

## 2. 输入映射

新增两个动作（遵循 `player_` 前缀）：
- `player_throw_charge` → 鼠标左键（按住/释放）
- `player_throw_cancel` → 鼠标右键

无冲突：拾取当前绑 E；RMB 物品槽菜单已弃用。注意将来若把拾取改回 LMB 需处理优先级。

## 3. 蓄力状态机（控制器内部）

```
Idle ──LMB按下且守卫通过──▶ Charging ──LMB释放──▶ 执行投掷 ──▶ Idle
                                └──RMB按下──▶ 取消 ──▶ Idle
```

**启动守卫**（仅在按下瞬间判定）：
1. `held_item != null` 且 `item_data.can_throw`
2. 鼠标不在 UI 上：`get_viewport().gui_get_hovering_control() == null`
3. `get_global_mouse_position().y < held_item.global_position.y`（世界坐标，鼠标必须高于物品）

**按下瞬间锁定**：
- 角度：`dir = (按下点世界坐标 - 物品位置).normalized()`，蓄力期间不可变（重蓄力才重取）
- 屏幕坐标：用于滑条摆放（屏幕空间固定）
- 蓄力期间鼠标移到 UI 上不影响进行中的蓄力（守卫只管启动）

**蓄力期间**（每帧）：
- 力度：`power = clamp(初始值 + (mouse_x - 按下x) / 轨道宽度, 0, 1)`，初始值建议 0.5（轨道以按下点为中心，向右增强）——具体见决策点
- 更新滑条手柄位置与轨迹预览

**蓄力期间其他输入**：建议 Q（丢弃）/E（拾取）按下时先取消蓄力再忽略原行为，防止状态交叠。

## 4. 力度滑条 UI

- Control 子类自绘：空心圆角轨道 + 实心进度 + 圆形手柄，StyleBoxFlat/绘制风格与物品槽一致
- 出现于按下时的**屏幕坐标**处，蓄力期间位置固定，手柄 x 映射 power
- 结束（投掷/取消）即隐藏；只读渲染，不含逻辑

## 5. 抛物线轨迹预览

- Node2D 的 `_draw()` 画虚线（短线段交替留空）
- 每帧采样：`p(t) = 物品位置 + v0·t + ½·g·t²`，`v0 = dir · speed(power)`，g 取 `ProjectSettings` 的 2D 重力，步长 1/60 与物理同步（物品 `linear_damp = 0` 时解析解与引擎积分一致）
- 每段用 `direct_space_state.intersect_ray` 做截断（排除玩家与物品自身），撞到地形即止——虚线终点即预测落点
- z_index 高于地块；蓄力开始显示、结束隐藏

## 6. 投掷执行（复用丢弃的善后模式）

顺序（严守 precautions #2/#3）：
1. `send_event("throw")`（先事件）
2. `freeze = false`、`sleeping = false`、清零角速度
3. `reparent(world_parent_node)`，位置保持手部
4. `linear_velocity = dir · lerp(min_speed, max_speed, power)`（世界速度，不继承玩家速度）
5. `can_pickup = false`

**数据层**：新增 `Inventory.remove_item(item)`——纯数据移除（erase、数量-1、槽空置空、发 `slot_changed`），**不发 `item_discarded`**（与丢弃语义区分）。随后玩家侧善后与丢弃完全一致：槽内有余量 → 自动上手下一颗；槽空 → UI 反选（现有逻辑）。

## 7. 物品状态机扩展

`throwable_item.tscn` 状态图新增：
- 状态 `OnThrown`（与 OnGround/OnHand/InBag 平级）
- 转换：`OnHand → OnThrown`（事件 `throw`）、`OnThrown → OnGround`（事件 `land`）

**落地检测**（`throwable_item.gd`）：进入 OnThrown 时置飞行标志；`_physics_process` 中检测“有接触且速度低于阈值（或已 sleeping）”→ `send_event("land")` + `can_pickup = true`；加安全超时（如 8 秒）兜底强制落地。

**已知边角**：物品落在玩家身边时 `body_entered` 早已触发过，可拾取提示不会自动出现——落地时若 `_player_in_range != null` 则补 `show()`（丢弃路径同理，可一并修）。

## 8. 待拍板的决策点

| 决策 | 默认建议 |
|---|---|
| 力度起始值与方向 | 按下点为轨道中心，起始 50%，向右增强 |
| 速度映射范围 | `lerp(250, 1000, power)` px/s，导出为 @export 便于调参 |
| 蓄力中能否移动/跳跃 | 允许（不改移动代码）；角度锁定不受影响 |
| 轨迹预览是否被其他物品截断 | 默认只截地形，忽略物品 |
| 轨迹采样长度 | 60 步（约 1 秒）或直到撞击 |
| 滑条轨道宽度 | 160px，居中于按下点 |

## 9. 文件清单

**新增**：`scripts/characters/throw_charger.gd`、`scenes/ui/charge_slider.tscn`（含脚本）、`scripts/ui/trajectory_preview.gd`
**修改**：`project.godot`（两个输入动作）、`player.gd`（挂组件/接线）、`throwable_item.gd` + `.tscn`（OnThrown 状态与落地检测）、`player_inventory.gd`（`remove_item`）、`throwable_item.tscn` 状态图、Ui 场景（滑条挂载点）、`docs/design.md`（补投掷操作说明）

## 10. 验证清单

1. 空手按 LMB 无反应；手持物品、鼠标在 UI 上/低于物品时按下无反应
2. 合法按下 → 滑条+虚线出现，左右滑动力度变化、虚线随之伸缩
3. 松开 LMB → 按锁定角度飞出、初速与力度匹配；槽位数量-1、自动上手或空槽反选
4. RMB 取消 → 物品仍在手、槽位不变；重新蓄力角度可变
5. 飞行中不可拾取，落地后恢复可拾取与提示
6. 虚线预测落点与实际落点一致（平地与有障碍物两种场景）

方案就绪。确认决策点（尤其第 8 节的默认值）后即可按 9 节清单实施。