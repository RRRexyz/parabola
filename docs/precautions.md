# 开发过程中的注意事项

1. BoxContainer(HBoxContainer/VBoxContainer)的子控件必须是继承自Control的节点，才会进行自动排列。非继承自Control的节点会被忽略（例如Sprite2D）。