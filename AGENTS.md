# AGENTS.md

## 项目概览

parabola（抛物线）—— 2D 平台肉鸽 PVE 动作游戏，使用 **Godot 4.7.1**（GL Compatibility 渲染器）开发。目前处于早期原型阶段，已实现：玩家基础移动、相机控制、关卡世界边界。

- 详细游戏设计（物品/敌人分类、操作方式、祝福/诅咒等）见 [docs/design.md](docs/design.md)。
- 代码注释与文档均为**中文**，请保持这一约定。

## 运行

- Godot 可执行文件：`g:\Godot\Godot_v4.7.1-stable_win64.exe`（已配置在 `.vscode/settings.json` 的 `godotTools.editorPath.godot4`）。
- 主场景：`scenes/general/game.tscn`（`project.godot` 中 `run/main_scene` 指向其 uid）。
- 运行：在 Godot 编辑器中按 F5。

## 架构

- **场景/脚本镜像结构**：`scenes/` 与 `scripts/` 目录一一对应（如 `scenes/characters/player.tscn` ↔ `scripts/characters/player.gd`）。给场景添加逻辑时，脚本放到 `scripts/<同路径>/`。
- **事件总线模式**：跨节点通信一律通过 autoload 单例 `WorldEventBus`（`global/world_event_bus.gd`）发信号，避免节点间直接耦合。例：`world.gd` 通过 `world_limit_data_changed` 信号把世界边界广播给相机。
- **场景层级**：
  - `game.tscn`（主场景）= `World` + `Player` + `WorldCamera`。
  - `WorldCamera` 是**顶层节点，不是 Player 子节点**——若作为子节点会自动跟随玩家，与设计冲突。
  - `world.tscn` = `TileMapLayer` 地面 + 4 个 LimitWall（用禁用碰撞的墙标记世界范围，供相机 limit 用）。

## 物理层（`project.godot` → `[layer_names]`）

| 层 | 名称 | 用途 |
|----|------|------|
| 1 | world | 地形/墙体 |
| 2 | player | 玩家 |
| 3 | item | 物品 |

## 输入映射

输入动作以 `project.godot` 的 `[input]` 实际映射为准。**`docs/design.md` 的按键表与部分实际映射不一致**（例如设计文档跳跃为 W，实际映射为空格），不要按设计文档写输入代码。

常用动作：`player_move_left/right`、`player_jump`、`player_crouch`、`camera_move_*`（Q/E 左右、W/S 上下）、`player_use_item`、`player_interact_with_scene`、`player_pickup_item`、`player_charge_and_throw_item`。

## 代码约定

- **GDScript 缩进必须用 Tab，禁止空格**（VS Code 已设 `editor.insertSpaces: false`、`editor.detectIndentation: false`）。
- 可调参数用 `@export` 暴露，并加 `##` 中文文档注释。
- 常用类型用 `class_name` 注册全局类型（如 `class_name Player`），便于 `is` 类型判断。
- 物理移动在 `_physics_process` + `move_and_slide()`；**纯视觉/输入响应（如相机）用 `_process`**。
- 瓦片 24×24（`assets/tiles/pixel_platformer_tile_set_1.png`）。

## 常见陷阱

- **场景重构会丢失 `@export` 赋值**：在 .tscn 中移动/删除节点时，脚本 `@export` 变量在场景里的赋值行容易连带丢失，导致运行时 `Nil` 报错。改动场景后务必确认脚本的 `@export` 变量仍在场景文件中显式赋值（历史中已多次发生）。
- **`_ready` 中先 emit 后 connect 会丢信号**：发射方在 `_ready` 里同步 emit 信号时，兄弟节点（按树顺序在后的）可能还没在 `_ready` 中 connect，信号直接丢失。发射方应改用 `signal.emit.call_deferred(...)` 延迟到本帧末尾广播（例：`world.gd` 广播世界边界）。
- **相机滞后感**：鼠标/按键驱动的相机若开启 `position_smoothing_enabled` 会有明显滞后，需要即时响应时保持关闭。
- **相机逻辑放错回调**：相机是纯视觉元素，放在 `_physics_process` 会在快速反向移动时出现停顿感，应使用 `_process`。
