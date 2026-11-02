extends Node


@warning_ignore_start("unused_signal")


signal throwable_item_picked_up(throwable_item: RigidBody2D)
signal slot_deselected(slot_index: int)
signal slot_selected(slot_index: int)
signal charging_started(throw_angle_deg: int, item_position: Vector2)
signal throw_angle_preview_updated(is_visible: bool, throw_angle_deg: int, item_position: Vector2)
