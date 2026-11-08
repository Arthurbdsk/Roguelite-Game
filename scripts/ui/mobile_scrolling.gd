class_name MobileScrolling
extends RefCounted

static func prepare(node:Node,inside:bool=false):
 if node is ScrollBar:return
 if node is ScrollContainer:
  node.scroll_deadzone=8
  node.follow_focus=false
  inside=true
 elif inside and node is Control and not node is Slider and not node is LineEdit and not node is TextEdit:
  if node.mouse_filter==Control.MOUSE_FILTER_STOP:node.mouse_filter=Control.MOUSE_FILTER_PASS
 for child in node.get_children():prepare(child,inside)
